// Sem build tag, de proposito.
//
// Este arquivo nao abre conexao, nao le ORGANIQ_TEST_DATABASE_URL, nao importa
// internal/infra/postgres e nao encosta em Groq. AiSchemaValidator e funcao pura,
// entao tudo que da pra saber sobre o payload do stub da pra saber ANTES de
// qualquer container existir -- e a janela do OrbStack e da Vanessa, nao nossa.
// Queimar um run dela num `ai_schema_invalid` por virgula de JSON seria gastar
// uma coisa que nao esta sob meu controle pra descobrir uma que esta.
//
// classificationJSON mora AQUI e nao no arquivo com tag `integration` porque a
// string tem que ser a MESMA nos dois lados. Se ela vivesse la e eu reescrevesse
// uma "equivalente" aqui, este teste passaria a atestar a reescrita e nao o que o
// stub manda -- que e a diferenca entre verificar e encenar.
package usecase_test

import (
	"fmt"
	"strings"
	"testing"

	"organiq/backend/internal/app/service"
)

// classificationJSON e a resposta de classificacao do stubAIClient
// (inbox_tx_integration_test.go). Fonte unica: o stub chama esta funcao.
//
// ARRAY de dois itens de proposito. ReprocessInboxItem so entra no ramo
// transacional quando `autoConfirm := len(validatedMany) > 1`; com um item so, o
// caminho que o teste de integracao existe pra exercitar nem e tomado.
//
// Formato: decodeStrictOutput exige as chaves type/title/needs_review/payload e
// roda DisallowUnknownFields, entao campo a mais reprova. `context` fica de fora
// (omitempty, e usuario novo nao tem flag). Payload de task `{"dueAt":null}` e o
// mesmo shape que o inbox ja produz.
func classificationJSON(a, b string) string {
	return fmt.Sprintf(`[
  {"type":"task","title":%q,"confidence":0.95,"needs_review":false,"payload":{"dueAt":null}},
  {"type":"task","title":%q,"confidence":0.95,"needs_review":false,"payload":{"dueAt":null}}
]`, a, b)
}

// TestStubClassificationPayloadIsAcceptedByValidator converte de LIDO pra MEDIDO
// a unica afirmacao do teste de integracao que estava so lida: que o JSON do stub
// passa pelo AiSchemaValidator.
//
// Vai pelo metodo EXPORTADO ValidateMany, que e o que InboxUsecase chama de
// verdade, em vez de alcancar decodeStrictOutput por dentro. Testar o caminho
// publico mede o caminho de producao; testar o interno mede outra coisa.
func TestStubClassificationPayloadIsAcceptedByValidator(t *testing.T) {
	const titleA = "tarefa A r1"
	const titleB = "tarefa B r1"

	raw := classificationJSON(titleA, titleB)
	v := service.NewAiSchemaValidator()

	t.Run("payload_exato_do_stub_e_aceito", func(t *testing.T) {
		outs, err := v.ValidateMany([]byte(raw))
		if err != nil {
			t.Fatalf("ValidateMany reprovou o payload do stub: %v\npayload:\n%s", err, raw)
		}

		// Nao e detalhe: e a pre-condicao de autoConfirm. Se um dia isso virar 1,
		// o teste de integracao passa a exercitar o ramo errado em silencio.
		if len(outs) != 2 {
			t.Fatalf("esperava 2 itens (autoConfirm exige len > 1), vieram %d", len(outs))
		}

		for i, want := range []string{titleA, titleB} {
			out := outs[i].Output

			if out.Type != "task" {
				t.Errorf("item %d: type = %q, esperado \"task\"", i, out.Type)
			}
			if out.Title != want {
				t.Errorf("item %d: title = %q, esperado %q", i, out.Title, want)
			}
			if out.NeedsReview {
				t.Errorf("item %d: needs_review = true; com true o item vai pra NEEDS_REVIEW e nao auto-confirma", i)
			}
			if out.Confidence == nil {
				t.Errorf("item %d: confidence veio nil", i)
			} else if *out.Confidence != 0.95 {
				t.Errorf("item %d: confidence = %v, esperado 0.95", i, *out.Confidence)
			}

			// parseTaskPayload devolve TaskPayload por VALOR, nao ponteiro.
			payload, ok := outs[i].Payload.(service.TaskPayload)
			if !ok {
				t.Errorf("item %d: payload = %T, esperado service.TaskPayload", i, outs[i].Payload)
				continue
			}
			if payload.DueAt != nil {
				t.Errorf("item %d: dueAt = %v, esperado nil", i, payload.DueAt)
			}
		}
	})

	// Controle negativo. Sem ele, "ValidateMany nao deu erro" tambem seria o
	// resultado de um validador que aceita qualquer coisa -- e ai o subteste acima
	// nao teria como reprovar nada. Verificacao que nao pode reprovar e cerimonia.
	t.Run("controle_negativo_o_validador_consegue_reprovar", func(t *testing.T) {
		cases := map[string]string{
			// DisallowUnknownFields tem que morder.
			"campo_desconhecido": strings.Replace(raw, `"type":"task"`, `"type":"task","naoExisteEsseCampo":1`, 1),
			// type fora da uniao cai no default de validatePayload -> invalid_type.
			// Nao uso "note" aqui: note CONTINUA sendo tipo valido em
			// validatePayload. O fix de hoje tirou note do PROMPT, nao da uniao do
			// validador -- confundir os dois faria este caso reprovar pelo motivo
			// errado e ainda assim ficar verde.
			"type_invalido": strings.Replace(raw, `"type":"task"`, `"type":"telepatia"`, 2),
			// needs_review e obrigatorio por presenca de chave, nao por valor.
			"sem_needs_review": strings.ReplaceAll(raw, `"needs_review":false,`, ""),
		}

		for name, bad := range cases {
			t.Run(name, func(t *testing.T) {
				if bad == raw {
					t.Fatalf("o payload adulterado ficou identico ao original; este caso nao esta testando nada")
				}
				if _, err := v.ValidateMany([]byte(bad)); err == nil {
					t.Fatalf("ValidateMany ACEITOU payload invalido; entao o subteste positivo nao prova nada")
				}
			})
		}
	})
}
