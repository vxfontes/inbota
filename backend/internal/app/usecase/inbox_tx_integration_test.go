//go:build integration

// Teste de integracao do regime transacional do Inbox.
//
// PACOTE: `usecase_test` (externo), de proposito. So enxerga simbolo exportado,
// entao e IMPOSSIVEL este arquivo referenciar scheduleNotificationCopy,
// generateNotificationCopy ou derefString -- os tres nomes que o fix introduziu e
// que nao existem em HEAD. A restricao vira erro de compilacao, nao lembranca.
//
// DOIS BRACOS
//
//	BRACO A (TestInboxNotificationCopyLandsAfterCommit) exercita ReprocessInboxItem
//	de ponta a ponta com AIClient stubado. Em working tree deve PASSAR; rodado no
//	worktree em HEAD deve FALHAR. Essa diferenca e o controle real do fix, e ela so
//	existe porque o arquivo compila nas duas arvores.
//
//	BRACO B (TestTxBoundWriteFromGoroutine) reproduz o MECANISMO do bug com codigo
//	que o teste mesmo escreve, usando apenas repositorio + TxRunner. Nao chama
//	TaskUsecase.Create de proposito: la o erro e engolido com `_ =` e nao ha nada
//	pra capturar. Como so toca simbolo intocado pelo fix, roda igual nas duas
//	arvores e prova o mecanismo independente de qual versao esta compilada.
//
// CONTROLE NEGATIVO DE TRES PARTES (braco B, por rodada)
//
//	1. o erro veio E tem a assinatura do regime (discriminante, nao "deu erro");
//	2. as colunas continuam NULL depois da tentativa;
//	3. testemunha positiva: a MESMA escrita pelo pool, com a MESMA sentinela, no
//	   MESMO registro, LANDA.
//
//	Sem (3), coluna NULL tambem seria explicada por linha errada, usuario errado ou
//	sentinela errada. Ausencia sozinha nao prova nada -- e a armadilha do dia.
//
// EXECUCAO
//
//	backend/scripts/testdb.sh up          # sobe Postgres descartavel e aplica db/
//	export ORGANIQ_TEST_DATABASE_URL=...  # a linha que o script imprime
//	go test -tags integration ./internal/app/usecase/ -run TestInbox -v
package usecase_test

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"net/url"
	"os"
	"strings"
	"sync"
	"testing"
	"time"

	"organiq/backend/internal/app/domain"
	"organiq/backend/internal/app/repository"
	"organiq/backend/internal/app/service"
	"organiq/backend/internal/app/usecase"
	"organiq/backend/internal/infra/postgres"
)

// ---------------------------------------------------------------------------
// Limites PRE-REGISTRADOS.
//
// Piso e teto ficam aqui em cima, em const, antes de qualquer execucao. Se o
// resultado sair da faixa a rodada falha -- inclusive quando sai pra cima. Faixa
// escolhida depois de ver o numero nao e faixa, e narrativa.
// ---------------------------------------------------------------------------

const (
	roundsPerRegime = 5

	// BRACO A: stub responde na hora, sem rede. Deterministico.
	fixArmMinOK, fixArmMaxOK = roundsPerRegime, roundsPerRegime

	// Regime POST-COMMIT: database/sql confere o estado da tx atomicamente e
	// devolve sql.ErrTxDone ANTES de encostar no driver. Deterministico.
	postCommitMinFail, postCommitMaxFail = roundsPerRegime, roundsPerRegime

	// Regime CONCURRENT: depende de escalonamento entre duas goroutines na mesma
	// *sql.Tx. Nao da pra prometer 5/5 e prometer seria mentira. O que importa e
	// que reproduza ao menos uma vez -- piso 1.
	concurrentMinFail, concurrentMaxFail = 1, roundsPerRegime
)

// ---------------------------------------------------------------------------
// Guardas. Duas camadas independentes + variavel propria.
// ---------------------------------------------------------------------------

// testDSNEnv e variavel PROPRIA e NAO cai pra DATABASE_URL. Fallback aqui seria
// exatamente o caminho que aponta um teste destrutivo pra producao.
const testDSNEnv = "ORGANIQ_TEST_DATABASE_URL"

// testDBName e a segunda camada. Producao no Supabase e `organiq`/`postgres`,
// nunca `organiq_test`. Essa condicao nao se importa com tunel SSH -- foi por
// isso que ela existe: a guarda de host sozinha nao distingue local descartavel
// de qualquer coisa redirecionada pra 127.0.0.1.
const testDBName = "organiq_test"

func mustTestDSN(t *testing.T) string {
	t.Helper()

	raw := strings.TrimSpace(os.Getenv(testDSNEnv))
	if raw == "" {
		// Fatal, NAO Skip. A build tag `integration` esta ligada, ou seja, alguem
		// pediu explicitamente por este teste. Skip silencioso viraria suite verde
		// sem nada ter rodado -- de novo ausencia virando prova.
		t.Fatalf("%s nao definido. Rode backend/scripts/testdb.sh up e exporte a linha que ele imprime.", testDSNEnv)
	}

	u, err := url.Parse(raw)
	if err != nil {
		t.Fatalf("%s nao e uma URL valida: %v", testDSNEnv, err)
	}

	host := u.Hostname()
	switch host {
	case "localhost", "127.0.0.1", "::1":
	default:
		t.Fatalf("guarda 1: host %q recusado. Este teste escreve e apaga dados; so roda em Postgres local descartavel.", host)
	}

	dbname := strings.TrimPrefix(u.Path, "/")
	if dbname != testDBName {
		t.Fatalf("guarda 2: banco %q recusado, exigido %q.", dbname, testDBName)
	}

	// Terceira rede, barata: nenhum host gerenciado tem por que aparecer aqui.
	for _, needle := range []string{"supabase", "render.com", "amazonaws"} {
		if strings.Contains(strings.ToLower(raw), needle) {
			t.Fatalf("guarda 3: DSN menciona %q. Recusado.", needle)
		}
	}

	return raw
}

// ---------------------------------------------------------------------------
// Stub do AIClient. Nunca sai da maquina -- nenhum teste aqui encosta na Groq.
// ---------------------------------------------------------------------------

type stubAIClient struct {
	mu            sync.Mutex
	classifyCalls int
	copyCalls     int

	classifyJSON string
	copyTitle    string
	copyBody     string
}

// Complete decide pelo CONTEUDO do prompt, nao por configuracao externa: o
// prompt do NotificationCopyService pede as chaves notification_title/
// notification_body, o de classificacao nao.
func (s *stubAIClient) Complete(_ context.Context, prompt string) (service.AICompletion, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	if strings.Contains(prompt, "notification_title") {
		s.copyCalls++
		body, err := json.Marshal(map[string]string{
			"notification_title": s.copyTitle,
			"notification_body":  s.copyBody,
		})
		if err != nil {
			return service.AICompletion{}, err
		}
		return service.AICompletion{Content: string(body), Model: "stub", Raw: body}, nil
	}

	s.classifyCalls++
	return service.AICompletion{
		Content: s.classifyJSON,
		Model:   "stub",
		Raw:     json.RawMessage(s.classifyJSON),
	}, nil
}

func (s *stubAIClient) counts() (classify, copy int) {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.classifyCalls, s.copyCalls
}

func (s *stubAIClient) setSentinel(title, body string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.copyTitle, s.copyBody = title, body
}

// classificationJSON vive em inbox_stub_payload_test.go, SEM build tag, junto do
// teste que a valida contra o AiSchemaValidator sem banco. Fonte unica de
// proposito: se a string fosse duplicada aqui, aquele teste passaria a atestar a
// copia e nao o que este stub manda.

// ---------------------------------------------------------------------------
// Fiacao.
// ---------------------------------------------------------------------------

type testEnv struct {
	db    *postgres.DB
	tx    repository.TxRunner
	users repository.UserRepository
	inbox repository.InboxRepository
	tasks repository.TaskRepository
	ai    *stubAIClient
	uc    *usecase.InboxUsecase
}

func newTestEnv(t *testing.T) *testEnv {
	t.Helper()

	dsn := mustTestDSN(t)

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	// postgres.NewDB ja aplica SetMaxOpenConns(10)/SetMaxIdleConns(5). O pool
	// espelhado importa: o bug original so aparece sob a mesma escassez de
	// conexao que producao tem. Nao mexer nisso aqui.
	db, err := postgres.NewDB(ctx, dsn)
	if err != nil {
		t.Fatalf("nao conectou no banco de teste: %v", err)
	}
	t.Cleanup(func() { _ = db.Close() })

	ai := &stubAIClient{}

	tasksRepo := postgres.NewTaskRepository(db)
	flagsRepo := postgres.NewFlagRepository(db)
	subflagsRepo := postgres.NewSubflagRepository(db)

	copySvc := service.NewNotificationCopyService(ai)

	tasksUC := &usecase.TaskUsecase{
		Tasks:            tasksRepo,
		Flags:            flagsRepo,
		Subflags:         subflagsRepo,
		NotificationLog:  postgres.NewNotificationLogRepository(db),
		NotificationCopy: copySvc,
	}

	env := &testEnv{
		db:    db,
		tx:    postgres.NewTxRunner(db),
		users: postgres.NewUserRepository(db),
		inbox: postgres.NewInboxRepository(db),
		tasks: tasksRepo,
		ai:    ai,
	}

	// RoutinesUsecase fica de fora de proposito: rotina nao entra neste teste.
	env.uc = &usecase.InboxUsecase{
		Users:         env.users,
		Inbox:         env.inbox,
		Suggestions:   postgres.NewAiSuggestionRepository(db),
		Flags:         flagsRepo,
		Subflags:      subflagsRepo,
		ContextRules:  postgres.NewContextRuleRepository(db),
		Tasks:         tasksRepo,
		Reminders:     postgres.NewReminderRepository(db),
		Events:        postgres.NewEventRepository(db),
		ShoppingLists: postgres.NewShoppingListRepository(db),
		ShoppingItems: postgres.NewShoppingItemRepository(db),

		TasksUsecase: tasksUC,

		PromptBuilder:   service.NewPromptBuilder(),
		AIClient:        ai,
		SchemaValidator: service.NewAiSchemaValidator(),
		RuleMatcher:     service.NewContextRuleMatcher(),
		TxRunner:        env.tx,
	}

	return env
}

// newUser cria um usuario DESCARTAVEL por rodada. Usuario novo a cada rodada
// impede que linha sobrevivente de uma rodada anterior satisfaca a assercao da
// seguinte. Prefixo del.probe.* e o combinado; review@organiq.app nao e tocado
// por caminho nenhum deste arquivo.
func (e *testEnv) newUser(t *testing.T, ctx context.Context, tag string, round int) domain.User {
	t.Helper()

	email := fmt.Sprintf("del.probe.tx.%s.r%d.%d@organiq.app", tag, round, time.Now().UnixNano())
	u, err := e.users.Create(ctx, domain.User{
		Email:       email,
		DisplayName: "probe tx",
		Password:    "not-a-real-hash-" + tag,
		Locale:      "pt_BR",
		Timezone:    "America/Sao_Paulo",
	})
	if err != nil {
		t.Fatalf("rodada %d: criar usuario: %v", round, err)
	}

	// CASCADE: users(id) e referenciado com ON DELETE CASCADE em toda tabela, entao
	// isso limpa tudo que a rodada criou.
	t.Cleanup(func() {
		delCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()
		if err := e.users.Delete(delCtx, u.ID); err != nil {
			t.Errorf("rodada %d: limpeza do usuario %s falhou: %v", round, u.ID, err)
		}
	})

	return u
}

// sentinel monta um par title+body unico por rodada E por usuario. Incluir o
// user_id e o que impede uma linha de outra rodada de passar a assercao por
// acidente.
func sentinel(regime, userID string, round int) (string, string) {
	return fmt.Sprintf("oq-test/%s/%s/r%d/title", regime, userID, round),
		fmt.Sprintf("oq-test/%s/%s/r%d/body", regime, userID, round)
}

// ---------------------------------------------------------------------------
// BRACO A -- o fix, de ponta a ponta.
// ---------------------------------------------------------------------------

// TestInboxNotificationCopyLandsAfterCommit exercita ReprocessInboxItem inteiro.
//
// Working tree: a copy e gerada DEPOIS do commit, pelas usecases originais ainda
// ligadas ao pool -- deve landar nas duas tasks, em 5 de 5 rodadas.
//
// HEAD (worktree): a mesma chamada gera copy de dentro da transacao. Este teste
// deve FALHAR la. A falha e o resultado do controle, nao um defeito do teste.
func TestInboxNotificationCopyLandsAfterCommit(t *testing.T) {
	env := newTestEnv(t)
	ok := 0

	for round := 1; round <= roundsPerRegime; round++ {
		ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)

		user := env.newUser(t, ctx, "fixarm", round)
		cTitle, cBody := sentinel("fixarm", user.ID, round)
		env.ai.setSentinel(cTitle, cBody)
		env.ai.classifyJSON = classificationJSON(
			fmt.Sprintf("tarefa A r%d", round),
			fmt.Sprintf("tarefa B r%d", round),
		)

		item, err := env.inbox.Create(ctx, domain.InboxItem{
			UserID:  user.ID,
			Source:  domain.InboxSourceManual,
			RawText: fmt.Sprintf("duas coisas pra fazer, rodada %d", round),
			Status:  domain.InboxStatusNew,
		})
		if err != nil {
			cancel()
			t.Fatalf("rodada %d: criar item de inbox: %v", round, err)
		}

		classifyBefore, copyBefore := env.ai.counts()

		res, err := env.uc.ReprocessInboxItem(ctx, user.ID, item.ID)
		if err != nil {
			cancel()
			t.Fatalf("rodada %d: ReprocessInboxItem: %v", round, err)
		}

		// Testemunha positiva #1: o stub de classificacao correu de verdade.
		classifyAfter, _ := env.ai.counts()
		if classifyAfter == classifyBefore {
			cancel()
			t.Fatalf("rodada %d: o stub de classificacao nao foi chamado; o resto do teste nao mede nada", round)
		}

		taskIDs := make([]string, 0, 2)
		for _, c := range res.Confirmed {
			if c.Task != nil {
				taskIDs = append(taskIDs, c.Task.ID)
			}
		}
		if len(taskIDs) != 2 {
			cancel()
			t.Fatalf("rodada %d: esperava 2 tasks auto-confirmadas, vieram %d (autoConfirm exige len(validatedMany) > 1)", round, len(taskIDs))
		}

		landed := waitForCopy(ctx, env.tasks, user.ID, taskIDs, cTitle, cBody, 20*time.Second)

		// Testemunha positiva #2: o stub de COPY correu. Se copyCalls nao subiu, a
		// copy ausente nao diz nada sobre transacao -- diz que a IA nem foi chamada.
		_, copyAfter := env.ai.counts()
		if copyAfter == copyBefore {
			cancel()
			t.Fatalf("rodada %d: o stub de copy nao foi chamado nenhuma vez; ausencia de copy aqui nao e evidencia sobre o regime transacional", round)
		}

		if landed {
			ok++
		} else {
			t.Logf("rodada %d: copy NAO landou nas 2 tasks (%v). Em HEAD isso e o esperado.", round, taskIDs)
		}

		cancel()
	}

	if ok < fixArmMinOK || ok > fixArmMaxOK {
		t.Fatalf("braco A: %d/%d rodadas com copy persistida, faixa pre-registrada [%d,%d]",
			ok, roundsPerRegime, fixArmMinOK, fixArmMaxOK)
	}
	t.Logf("braco A: %d/%d rodadas dentro da faixa [%d,%d]", ok, roundsPerRegime, fixArmMinOK, fixArmMaxOK)
}

// waitForCopy so devolve true quando TODAS as tasks tem exatamente a sentinela da
// rodada. Comparacao por igualdade, nao por "nao-nulo": nao-nulo passaria com
// sobra de outra rodada.
func waitForCopy(ctx context.Context, tasks repository.TaskRepository, userID string, ids []string, wantTitle, wantBody string, timeout time.Duration) bool {
	deadline := time.Now().Add(timeout)
	for {
		all := true
		for _, id := range ids {
			task, err := tasks.Get(ctx, userID, id)
			if err != nil || task.NotificationTitle == nil || task.NotificationBody == nil ||
				*task.NotificationTitle != wantTitle || *task.NotificationBody != wantBody {
				all = false
				break
			}
		}
		if all {
			return true
		}
		if time.Now().After(deadline) || ctx.Err() != nil {
			return false
		}
		time.Sleep(150 * time.Millisecond)
	}
}

// ---------------------------------------------------------------------------
// BRACO B -- o mecanismo, com codigo do proprio teste.
// ---------------------------------------------------------------------------

// TestTxBoundWriteFromGoroutine reproduz escrita via *sql.Tx a partir de
// goroutine, nos dois regimes, sem depender de nenhum simbolo que o fix mexeu.
//
// Nao usa TaskUsecase.Create de proposito: la o erro da goroutine e descartado com
// `_ =`, entao nao existe nada observavel pra afirmar em cima.
func TestTxBoundWriteFromGoroutine(t *testing.T) {
	t.Run("post_commit", func(t *testing.T) {
		env := newTestEnv(t)
		fails := 0

		for round := 1; round <= roundsPerRegime; round++ {
			ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
			user := env.newUser(t, ctx, "postcommit", round)
			sTitle, sBody := sentinel("postcommit", user.ID, round)

			var taskID string
			var lateTasks repository.TaskRepository

			if err := env.tx.WithTx(ctx, func(tx repository.TxRepositories) error {
				created, err := tx.Tasks.Create(ctx, domain.Task{
					UserID: user.ID,
					Title:  fmt.Sprintf("postcommit r%d", round),
					Status: domain.TaskStatusOpen,
				})
				if err != nil {
					return err
				}
				taskID = created.ID
				// Vazamento deliberado do repositorio ligado a tx pra fora do closure.
				// E exatamente o que o codigo antigo fazia sem perceber.
				lateTasks = tx.Tasks
				return nil
			}); err != nil {
				cancel()
				t.Fatalf("rodada %d: WithTx: %v", round, err)
			}

			// Tx ja commitou. A escrita sai numa goroutine, como no codigo original.
			errCh := make(chan error, 1)
			go func() {
				errCh <- lateTasks.UpdateNotificationCopy(ctx, user.ID, taskID, sTitle, sBody)
			}()

			var lateErr error
			select {
			case lateErr = <-errCh:
			case <-time.After(20 * time.Second):
				cancel()
				t.Fatalf("rodada %d: goroutine pos-commit nao retornou", round)
			}

			// (1) assinatura ESPECIFICA do regime. Neste, database/sql confere o
			// estado da tx antes de tocar o driver, entao tem que ser ErrTxDone --
			// nao "algum erro".
			if !errors.Is(lateErr, sql.ErrTxDone) {
				cancel()
				t.Fatalf("rodada %d: esperava sql.ErrTxDone, veio %v", round, lateErr)
			}

			// (2) as colunas continuam vazias.
			assertCopyAbsent(t, ctx, env.tasks, user.ID, taskID, round)

			// (3) testemunha positiva: mesma escrita, mesma sentinela, mesmo registro,
			// so que pelo pool. Se isto falhar, (2) nao era sobre transacao.
			assertPoolWriteLands(t, ctx, env.tasks, user.ID, taskID, sTitle, sBody, round)

			fails++
			cancel()
		}

		if fails < postCommitMinFail || fails > postCommitMaxFail {
			t.Fatalf("regime post_commit: %d/%d rodadas com a assinatura esperada, faixa pre-registrada [%d,%d]",
				fails, roundsPerRegime, postCommitMinFail, postCommitMaxFail)
		}
		t.Logf("regime post_commit: %d/%d, faixa [%d,%d]", fails, roundsPerRegime, postCommitMinFail, postCommitMaxFail)
	})

	t.Run("concurrent", func(t *testing.T) {
		env := newTestEnv(t)
		fails := 0

		for round := 1; round <= roundsPerRegime; round++ {
			ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
			user := env.newUser(t, ctx, "concurrent", round)
			sTitle, sBody := sentinel("concurrent", user.ID, round)

			var taskID string
			var lateErr error
			var sawErr bool

			txErr := env.tx.WithTx(ctx, func(tx repository.TxRepositories) error {
				created, err := tx.Tasks.Create(ctx, domain.Task{
					UserID: user.ID,
					Title:  fmt.Sprintf("concurrent r%d", round),
					Status: domain.TaskStatusOpen,
				})
				if err != nil {
					return err
				}
				taskID = created.ID

				// Goroutine escreve pela MESMA *sql.Tx enquanto o closure ainda a usa.
				// Duas conversas simultaneas num protocolo que so aceita uma.
				errCh := make(chan error, 1)
				go func() {
					errCh <- tx.Tasks.UpdateNotificationCopy(ctx, user.ID, created.ID, sTitle, sBody)
				}()

				for i := 0; i < 20; i++ {
					if _, err := tx.Tasks.Get(ctx, user.ID, created.ID); err != nil {
						// O closure tambem pode ser a vitima da dessincronizacao. Conta
						// como reproducao do mesmo mecanismo.
						lateErr, sawErr = err, true
						break
					}
				}

				select {
				case e := <-errCh:
					if e != nil && !sawErr {
						lateErr, sawErr = e, true
					}
				case <-time.After(20 * time.Second):
					return fmt.Errorf("rodada %d: goroutine concorrente nao retornou", round)
				}
				return nil
			})

			if txErr != nil {
				// A propria tx morrendo tambem e o mecanismo se manifestando.
				if !sawErr {
					lateErr, sawErr = txErr, true
				}
			}

			if sawErr {
				// Assinatura ESPECIFICA deste regime: aqui a tx ainda estava ABERTA,
				// entao ErrTxDone seria o erro do outro regime e nao vale como
				// reproducao deste.
				if errors.Is(lateErr, sql.ErrTxDone) {
					cancel()
					t.Fatalf("rodada %d: veio sql.ErrTxDone num regime de tx aberta; isso e a assinatura do post_commit, nao deste", round)
				}
				fails++
				t.Logf("rodada %d: reproduziu -> %v", round, lateErr)

				if taskID != "" {
					assertCopyAbsent(t, ctx, env.tasks, user.ID, taskID, round)
					assertPoolWriteLands(t, ctx, env.tasks, user.ID, taskID, sTitle, sBody, round)
				}
			} else {
				t.Logf("rodada %d: nao reproduziu (escalonamento). Esperado -- por isso o piso e %d, nao %d.",
					round, concurrentMinFail, roundsPerRegime)
			}

			cancel()
		}

		if fails < concurrentMinFail || fails > concurrentMaxFail {
			t.Fatalf("regime concurrent: %d/%d rodadas reproduziram, faixa pre-registrada [%d,%d]",
				fails, roundsPerRegime, concurrentMinFail, concurrentMaxFail)
		}
		t.Logf("regime concurrent: %d/%d, faixa [%d,%d]", fails, roundsPerRegime, concurrentMinFail, concurrentMaxFail)
	})
}

// assertCopyAbsent e a parte (2) do controle. Sozinha nao prova nada -- so vale
// acompanhada de assertPoolWriteLands.
func assertCopyAbsent(t *testing.T, ctx context.Context, tasks repository.TaskRepository, userID, taskID string, round int) {
	t.Helper()
	task, err := tasks.Get(ctx, userID, taskID)
	if err != nil {
		t.Fatalf("rodada %d: reler task %s: %v", round, taskID, err)
	}
	if task.NotificationTitle != nil || task.NotificationBody != nil {
		t.Fatalf("rodada %d: a escrita pela tx landou (title=%v body=%v); era pra ter falhado",
			round, task.NotificationTitle, task.NotificationBody)
	}
}

// assertPoolWriteLands e a parte (3): a testemunha positiva. Fecha a alternativa
// "a coluna esta NULL porque o registro/usuario/sentinela estavam errados".
func assertPoolWriteLands(t *testing.T, ctx context.Context, tasks repository.TaskRepository, userID, taskID, wantTitle, wantBody string, round int) {
	t.Helper()
	if err := tasks.UpdateNotificationCopy(ctx, userID, taskID, wantTitle, wantBody); err != nil {
		t.Fatalf("rodada %d: testemunha positiva falhou no pool: %v. Sem ela, coluna NULL nao e evidencia de nada.", round, err)
	}
	task, err := tasks.Get(ctx, userID, taskID)
	if err != nil {
		t.Fatalf("rodada %d: reler task depois da testemunha: %v", round, err)
	}
	if task.NotificationTitle == nil || *task.NotificationTitle != wantTitle ||
		task.NotificationBody == nil || *task.NotificationBody != wantBody {
		t.Fatalf("rodada %d: testemunha positiva nao persistiu a sentinela (title=%v body=%v)",
			round, task.NotificationTitle, task.NotificationBody)
	}
}
