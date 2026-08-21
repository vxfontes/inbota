// Driver de captura para os prints da App Store + observação do que a UI faz
// enquanto a IA processa (o /reprocess).
//
// NÃO é um teste de asserção: ele NAVEGA e ABRE JANELAS, e quem tira o print é
// o `xcrun simctl io ... screenshot` por fora, sincronizado pelos marcadores
// `=== JANELA <nome> ABERTA ===` / `FECHADA` no stdout. Toque por coordenada
// está vetado, então toda navegação aqui é pelo widget real ou pela mesma
// chamada que o `_onNavTap` do RootPage faz (`AppNavigation.navigate`).
//
// ESCREVE EM PRODUÇÃO: cria itens de inbox de verdade na conta de vitrine (é o
// único jeito de ver a fase de processamento — não existe tela que liste inbox
// pendente, ver comentário em _passoCreate). Não apaga nada.
//
// Execução:
//   flutter test integration_test/store_capture_test.dart -d <udid>

import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:organiq/presentation/app.dart';
import 'package:organiq/presentation/routes/app_module.dart';
import 'package:organiq/presentation/routes/app_navigation.dart';
import 'package:organiq/presentation/routes/app_routes.dart';
import 'package:organiq/presentation/screens/auth_module/pages/login_page.dart';
import 'package:organiq/presentation/screens/auth_module/pages/pre_login_page.dart';
import 'package:organiq/presentation/screens/create_module/components/create_done_phase_view.dart';
import 'package:organiq/presentation/screens/create_module/components/create_processing_line_item.dart';
import 'package:organiq/presentation/screens/create_module/components/create_review_phase_view.dart';
import 'package:organiq/presentation/screens/create_module/pages/create_page.dart';
import 'package:organiq/presentation/screens/home_module/pages/home_page.dart';
import 'package:organiq/presentation/screens/root_module/pages/root_page.dart';
import 'package:organiq/presentation/screens/schedule_module/pages/schedule_page.dart';
import 'package:organiq/presentation/screens/shopping_module/pages/shopping_page.dart';
import 'package:organiq/shared/components/oq_lib/oq_button.dart';
import 'package:organiq/shared/services/push/firebase_bootstrap.dart';
import 'package:organiq/shared/storage/app_preferences.dart';

// Conta de vitrine semeada pela @lauren. NÃO é criada nem apagada aqui.
const _email = 'del.app.vitrine.1786679619@organiq.app';
const _senha = 'Vitrine-Loja-2026';

// Texto escolhido por DOIS critérios ao mesmo tempo, porque ele manda em duas
// coisas: é o que a IA classifica E é o conteúdo do print da loja.
//
// (1) Frase de gente, dentro do domínio. Meta-texto ("teste", "asdf") foi o que
//     a @lauren viu devolver 400 com `invalid_type` cru na tela — se der isso
//     aqui, os prints 2 e 3 morrem e a rodada refaz.
// (2) UMA entidade-usecase só. A variável que derruba o confirm não é número de
//     cláusula, é quantas entidades criadas via usecase (task/reminder/event/
//     routine) entram na mesma transação — o @marcus mediu 34 execuções em
//     produção: 1 entidade = 0 falhas em 22; 2 = 70-75%; 3+ = 100%. Compra NÃO
//     conta (shopping é criado em nível de repositório, sem usecase e sem
//     goroutine). Então: uma lista + UM evento = 1 entidade-usecase, faixa
//     limpa. O texto anterior tinha compra + tarefa + evento = 2, e eu teria
//     rodado com 70-75% de chance de perder o print #3.
// (3) Entre tarefa e evento escolhi EVENTO: custam o mesmo (1 usecase cada) e o
//     evento mostra a IA tirando data e hora de linguagem solta, que é a coisa
//     mais impressionante que ela faz. O print #4 mostra a agenda montada; este
//     mostra COMO ela se monta.
// Parametrizável por --dart-define=CAP_LINHAS="a|b" para a segunda família não
// repetir o mesmo conteúdo na conta e duplicar item nos prints de Agenda e
// Compras. Separador `|` porque quebra de linha não passa limpo pelo shell.
const _linhasCru = String.fromEnvironment(
  'CAP_LINHAS',
  defaultValue: 'Comprar leite, café e filtro|Reunião com o time sexta às 10h',
);
final String _linhas = _linhasCru.split('|').join('\n');

void _log(String mensagem) {
  debugPrint('[CAP] ${DateTime.now().toUtc().toIso8601String()} $mensagem');
}

/// Deixa o tempo REAL correr e depois desenha um frame. Mesmo motivo do teste
/// de exclusão: `tester.pump(duration)` é tempo controlado, não relógio de
/// parede, e aqui tudo que importa depende de rede.
Future<void> _respira(
  WidgetTester tester, {
  Duration duracao = const Duration(milliseconds: 300),
}) async {
  await tester.runAsync(() => Future<void>.delayed(duracao));
  await tester.pump();
}

Future<void> _esperarPor(
  WidgetTester tester,
  Finder alvo, {
  Duration limite = const Duration(seconds: 45),
  required String descricao,
}) async {
  final prazo = DateTime.now().add(limite);
  while (DateTime.now().isBefore(prazo)) {
    if (alvo.evaluate().isNotEmpty) return;
    await _respira(tester);
  }
  fail('Timeout de ${limite.inSeconds}s esperando: $descricao');
}

Finder _botao(String rotulo) => find.widgetWithText(OQButton, rotulo);

/// Despeja no log todo texto visível na tela. Existe para um caso só: quando o
/// Create falha, eu não quero descrever o erro com as minhas palavras — quero a
/// string exata que o app pintou, porque é ela que diz de qual bug se trata.
void _despejarTextosDaTela(String motivo) {
  _log('--- textos na tela ($motivo) ---');
  for (final elemento in find.byType(Text).evaluate()) {
    final dado = (elemento.widget as Text).data;
    if (dado != null && dado.trim().isNotEmpty) {
      _log('  | $dado');
    }
  }
  _log('--- fim dos textos ---');
}

Future<void> _tocar(WidgetTester tester, Finder alvo) async {
  await tester.ensureVisible(alvo);
  await tester.pump();
  await tester.tap(alvo);
  await _respira(tester);
}

/// Abre a janela em que o print é tirado por fora. Os dois marcadores no stdout
/// são o único sincronismo entre este processo e o `simctl io screenshot`.
Future<void> _janela(
  WidgetTester tester,
  String nome, {
  Duration duracao = const Duration(seconds: 12),
}) async {
  await _respira(tester, duracao: const Duration(seconds: 1));
  _log('=== JANELA $nome ABERTA (${duracao.inSeconds}s) ===');
  await _respira(tester, duracao: duracao);
  _log('=== JANELA $nome FECHADA ===');
}

// ============================================================================
// Detector de quebra de layout — é o que responde a regra do /luka pro iPad
// ("se aparecer overflow, texto cortado ou controle inalcançável, PARA").
//
// Overflow de RenderFlex em debug não derruba o app: ele pinta a faixa amarela
// e reporta pelo FlutterError. Sem este gancho eu teria que descobrir a faixa
// OLHANDO o PNG, e a faixa pode estar fora da área capturada ou atrás de um
// sheet. Aqui ela vira linha de log carimbada com a tela onde aconteceu.
// ============================================================================
final List<String> _quebras = <String>[];
String _telaAtual = 'inicio';

void _instalarDetectorDeOverflow() {
  final anterior = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    final texto = details.exceptionAsString();
    if (texto.contains('overflowed') || texto.contains('RenderFlex')) {
      final registro = '[$_telaAtual] $texto';
      _quebras.add(registro);
      _log('!!! QUEBRA DE LAYOUT $registro');
    }
    anterior?.call(details);
  };
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('captura de prints da loja + observacao do processamento da IA',
      (tester) async {
    _instalarDetectorDeOverflow();

    // Bootstrap que o main() de verdade faz (main.dart:61 e :82). Sem isto o
    // ThemeController chama AppPreferences.instance no build e estoura
    // LateInitializationError — a árvore nem chega a montar. Foi exatamente o
    // que aconteceu na primeira rodada com o simulador zerado, e eu li o
    // sintoma errado: como a PreLoginPage não aparecia em 20s, meu detector
    // concluiu "abriu logado". Não tinha aberto nada.
    try {
      await FirebaseBootstrap.initialize();
    } catch (erro) {
      _log('firebase falhou no bootstrap (seguindo): $erro');
    }
    await AppPreferences.initialize();

    await tester.pumpWidget(
      ModularApp(module: AppModule(), child: const AppWidget()),
    );
    await _respira(tester, duracao: const Duration(seconds: 2));
    _log('app iniciado');

    await _logar(tester);
    await _dispensarTutorial(tester);

    // ORDEM INVERTIDA no meio da rodada, e o motivo é bom: a cota diária da
    // Groq estourou (100k tokens/dia pra conta inteira; ~1.4k por
    // classificação). O Create vai provavelmente voltar 429 — e ele era o
    // PRIMEIRO passo, então uma falha dele custaria também a Home, a Agenda e
    // as Compras, que não dependem de IA nenhuma e saem limpas. A ordem antiga
    // fazia sentido quando a única incerteza era latência; com a cota estourada
    // ela transforma um passo provavelmente-morto em porteiro dos outros três.
    //
    // Agora: as três telas semeadas primeiro (prints garantidos), o Create
    // depois e NÃO-FATAL. Cinto e suspensório de propósito — mesmo no fim, uma
    // exceção não capturada derrubaria o resumo de layout aqui embaixo, que é
    // parte do que o /luka precisa ler.
    await _passoTelasEstaveis(tester);
    try {
      await _passoCreate(tester);
    } catch (erro) {
      _log('!!! CREATE FALHOU — os prints 01/04/05 JA ESTAO SALVOS e nao foram '
          'afetados. Prints 02 e 03 ficam pra quando a cota da IA voltar.');
      _log('!!! motivo cru: $erro');
    }

    _log('=== FIM DA CAPTURA ===');
    if (_quebras.isEmpty) {
      _log('LAYOUT: nenhuma quebra detectada em nenhuma das telas visitadas');
    } else {
      _log('LAYOUT: ${_quebras.length} QUEBRA(S) — a captura NAO pode ser '
          'aprovada sem o /luka olhar:');
      for (final quebra in _quebras) {
        _log('  - $quebra');
      }
    }
    // Folga sobre a espera humana de 3h: o que roda depois do toque leva ~4min.
  }, timeout: const Timeout(Duration(minutes: 210)));
}

/// Login pela UI. O alerta NATIVO de notificação sobe aqui e trava o fluxo até
/// alguém responder: `login_page.dart:67` dá await no `initialize()` antes de
/// navegar. Como o `flutter test` desinstala o app no teardown, a permissão
/// volta pra `notDetermined` a cada rodada — então esse toque é por rodada, e
/// não tem como pré-responder sem tocar em lib/ ou em coordenada.
Future<void> _logar(WidgetTester tester) async {
  // CORRIDA entre as duas telas, não timeout de uma só. A versão anterior
  // esperava a PreLoginPage por 20s e, no estouro, CONCLUÍA "está logado" —
  // inferir estado a partir de um timeout curto é justamente o erro que já me
  // mordeu nesta sessão. O splash chama /v1/me e a API é Render free tier: a
  // primeira chamada depois de ociosa demora, e o app tolera até 60s de
  // receiveTimeout. Em 20s eu estava medindo a minha impaciência, não o app.
  final prazo = DateTime.now().add(const Duration(minutes: 3));
  var deslogado = false;
  var logado = false;
  while (DateTime.now().isBefore(prazo)) {
    deslogado = find.byType(PreLoginPage).evaluate().isNotEmpty;
    logado = find.byType(RootPage).evaluate().isNotEmpty;
    if (deslogado || logado) break;
    await _respira(tester);
  }
  if (!deslogado && !logado) {
    fail('Nem PreLoginPage nem RootPage em 3min. O app nao saiu do splash — '
        'olhe o log acima por excecao de bootstrap antes de culpar a rede.');
  }

  // Abrir logado é MOTIVO DE PARAR, não caminho alternativo. O token do
  // flutter_secure_storage vive no Keychain do iOS e sobrevive ao uninstall que
  // o `flutter test` faz no teardown — então "logado" aqui quer dizer "logado
  // em alguma conta", e eu não sei em qual. Já vi o app abrir assim duas vezes
  // nesta sessão. Fotografar sem saber a conta arrisca mandar pra loja print de
  // conta de teste, e o passo do Create escreveria nela. O jeito de garantir a
  // conta é passar pelo login: `xcrun simctl erase <udid>` antes da rodada.
  if (!deslogado) {
    fail('ABORTADO: o app abriu JA LOGADO e este driver nao sabe em qual '
        'conta. Rode `xcrun simctl erase <udid>` (apaga Keychain e prefs) e '
        'dispare de novo — o login precisa acontecer pela UI para a conta ser '
        'garantidamente a de vitrine.');
  }

  await _tocar(tester, _botao('Já tenho conta'));
  await _esperarPor(tester, find.byType(LoginPage), descricao: 'tela de login');

  await tester.enterText(find.widgetWithText(TextField, 'Email'), _email);
  await tester.enterText(find.widgetWithText(TextField, 'Senha'), _senha);
  await _respira(tester);

  await _tocar(tester, _botao('Entrar'));
  _log('login submetido em $_email');
  // O "(ate 3h)" tem que casar com o `limite` logo abaixo. Ficou "40min" aqui
  // depois de eu subir a janela pra 3h — mensagem sobrevivendo à mudança que ela
  // descrevia. É pequeno e é o defeito do dia: instrumento afirmando um número
  // que ele não mede mais. Quem lê o log decide quanto tempo tem com base nesta
  // linha, então ela mentindo custa uma visita perdida.
  _log('=== ESPERANDO O TOQUE HUMANO NO ALERTA (ate 3h) ===');

  await _esperarPor(tester, find.byType(RootPage),
      // 3 HORAS, e não 40min. A janela de 40 estourou vazia: ela não estava no
      // Mac naquela hora, e eu não tenho como saber quando estará. Janela curta
      // não mede a disponibilidade dela, mede o meu palpite sobre ela — e
      // quando o palpite erra, o custo é o ciclo inteiro, não o palpite.
      // Enquanto ninguém toca, o processo só dorme; janela longa custa zero.
      limite: const Duration(hours: 3),
      descricao: 'root depois do alerta, pelo login. SE ESTOUROU AQUI O APP '
          'NAO NAVEGOU = BLOQUEANTE DE SUBMISSAO');
  _log('logado na conta de vitrine');
}

/// O tutorial é overlay e engole toque. Flag por DISPOSITIVO, não por conta.
Future<void> _dispensarTutorial(WidgetTester tester) async {
  await _respira(tester, duracao: const Duration(seconds: 2));
  final pular = find.text('Pular tutorial');
  if (pular.evaluate().isEmpty) {
    _log('tutorial nao apareceu (flag ja marcada neste dispositivo)');
    return;
  }
  _log('tutorial apareceu — pulando');
  await tester.tap(pular);
  await _respira(tester, duracao: const Duration(seconds: 2));
}

/// Passo do Create — faz DUAS coisas de uma vez, e é de propósito.
///
/// (1) É a observação que o /luka pediu primeiro: o que a UI faz enquanto o
///     /reprocess da IA demora. Aqui os marcadores de fase saem carimbados com
///     relógio de parede, então a latência sai do log e não do meu chute.
///
/// (2) É de onde saem os prints #2 (sugestão da IA) e #3 (virou tarefa/evento).
///     Descoberta ao mapear as telas: NÃO EXISTE tela de inbox no app. O
///     `IInboxRepository` expõe create/reprocess/confirm e mais nada — não tem
///     list. O inbox é um pipeline dentro do Create, não uma caixa que o
///     usuário abre. Por isso o #1 do plano ("inbox cheio") não existe como
///     tela e virou a Home; está reportado ao /luka.
Future<void> _passoCreate(WidgetTester tester) async {
  _telaAtual = 'create/input';
  AppNavigation.navigate(AppRoutes.rootCreate);
  await _esperarPor(tester, find.byType(CreatePage), descricao: 'tela de criar');
  await _respira(tester, duracao: const Duration(seconds: 1));

  await tester.enterText(find.byType(TextField).first, _linhas);
  await _respira(tester);

  final submeteu = DateTime.now();
  await _tocar(tester, _botao('Organizar'));
  _log('=== ORGANIZAR TOCADO — comeca a espera da IA ===');

  // Enquanto a IA não volta, eu não fico só esperando: registro, a cada
  // segundo, se existe ALGUMA indicação de progresso na tela. É exatamente a
  // pergunta do /luka ("se a tela ficar parada sem loading, é achado de
  // submissão"), e ela se responde por amostragem, não por leitura de código —
  // o código eu já li e ele TEM estado de loading; o que falta é ver.
  // ATENÇÃO ao formato do fluxo — quase me custou uma rodada: a fase
  // `processing` NÃO renderiza a CreateReviewPhaseView. Ela renderiza a MESMA
  // CreateInputPhaseView (create_page.dart:185), com um cartão de progresso
  // dentro. Só quando o processamento acaba é que aparece o botão "Revisar
  // sugestões", e é o TOQUE nele que muda pra fase review. Esperar a
  // CreateReviewPhaseView aparecer sozinha aqui seria esperar pra sempre.
  var viLoading = false;
  var amostras = 0;
  final prazo = DateTime.now().add(const Duration(minutes: 5));
  while (DateTime.now().isBefore(prazo)) {
    if (find.byType(CreateReviewPhaseView).evaluate().isNotEmpty) break;
    if (find.byType(CreateDonePhaseView).evaluate().isNotEmpty) break;
    if (_botao('Revisar sugestões').evaluate().isNotEmpty) {
      _log('processamento terminou — botao "Revisar sugestoes" apareceu');
      break;
    }

    final temProcessing =
        find.byType(CreateProcessingLineItem).evaluate().isNotEmpty;
    if (temProcessing && !viLoading) {
      viLoading = true;
      _log('LOADING VISIVEL em '
          '${DateTime.now().difference(submeteu).inMilliseconds}ms '
          '(CreateProcessingLineItem montado)');
      // Print da tela em loading — o /luka pediu "print de tela em loading e
      // print jogado fora". Janela curta porque a fase pode acabar a qualquer
      // momento e eu não quero segurar o relógio da medição.
      await _janela(tester, 'loading-ia', duracao: const Duration(seconds: 4));
    }
    amostras++;
    if (amostras % 5 == 0) {
      // O contador ("Processando 1 de 3 linhas...") é a prova mais direta de
      // que a tela não está parada, e ele diz em QUAL linha a IA está. Vale
      // mais no log do que qualquer descrição minha.
      final contador = find.textContaining('linhas').evaluate();
      final texto = contador.isEmpty
          ? '(sem contador na tela)'
          : (contador.first.widget as Text).data ?? '(sem data)';
      _log('esperando IA: ${DateTime.now().difference(submeteu).inSeconds}s '
          'loading_visivel=$temProcessing contador="$texto"');
    }
    await _respira(tester, duracao: const Duration(seconds: 1));
  }

  final voltou = DateTime.now().difference(submeteu);
  _log('=== IA RESPONDEU em ${voltou.inMilliseconds}ms '
      '(loading apareceu em algum momento: $viLoading) ===');
  if (!viLoading) {
    _log('!!! ACHADO: a tela NAO mostrou estado de loading em nenhuma amostra');
  }

  // O toque que muda de fase. Se o botão não está aqui, ou a IA não devolveu
  // sugestão nenhuma (o que em si é achado) ou estourou o prazo lá em cima.
  final revisar = _botao('Revisar sugestões');
  if (revisar.evaluate().isNotEmpty) {
    await _tocar(tester, revisar);
    await _esperarPor(tester, find.byType(CreateReviewPhaseView),
        descricao: 'fase review depois de tocar em Revisar sugestoes');
  } else if (find.byType(CreateDonePhaseView).evaluate().isEmpty) {
    _log('!!! ACHADO: sem botao "Revisar sugestoes" e sem fase done — a IA nao '
        'devolveu sugestao para nenhuma das linhas. Prints 2 e 3 nao saem '
        'nesta rodada.');
    // A STRING CRUA importa: `driver: bad connection` (bug de transacao/pooler
    // do @marcus) e `invalid_type` (o tipo `note` que o backend pede e não sabe
    // consumir) são bugs DIFERENTES, e daqui de fora só o texto distingue.
    // Sem retentativa automática: cada rodada custa um toque humano.
    _despejarTextosDaTela('falha no processamento');
    await _janela(tester, 'falha-create', duracao: const Duration(seconds: 5));
    // Sai aqui em vez de cair no `_esperarPor(done)` lá embaixo: sem sugestão
    // não existe fase done pra esperar, e esperar seriam 3 minutos parado pra
    // chegar na mesma conclusão que eu já tenho agora.
    return;
  }

  // A fase de review pode não aparecer se tudo foi auto-confirmado; nesse caso
  // o app já está em `done` e o print #2 não existe nesta rodada. Digo qual foi
  // em vez de assumir.
  if (find.byType(CreateReviewPhaseView).evaluate().isNotEmpty) {
    _telaAtual = 'create/review';
    _log('fase REVIEW — print #2 (sugestao da IA)');
    await _janela(tester, '02-sugestao-ia');

    final confirmar = find.descendant(
      of: find.byType(CreateReviewPhaseView),
      matching: find.byWidgetPredicate(
        (w) => w is OQButton && w.label.startsWith('Confirmar todos'),
      ),
    );
    if (confirmar.evaluate().isEmpty) {
      _log('!!! nao achei o botao "Confirmar todos" — pulando o print #3');
      return;
    }
    await _tocar(tester, confirmar);
  } else {
    _log('fase REVIEW nao apareceu (auto-confirmado) — print #2 fica sem tela '
        'nesta rodada');
  }

  await _esperarPor(tester, find.byType(CreateDonePhaseView),
      limite: const Duration(minutes: 3), descricao: 'fase done do create');
  _telaAtual = 'create/done';
  _log('fase DONE — print #3 (virou tarefa/lembrete/evento)');
  await _janela(tester, '03-confirmado');
}

/// Home, Agenda e Compras — telas que só dependem do que já está semeado.
/// A navegação é a MESMA chamada que o `_onNavTap` do RootPage faz; não é
/// atalho de teste nem toque por coordenada.
Future<void> _passoTelasEstaveis(WidgetTester tester) async {
  final roteiro = <List<Object>>[
    <Object>[AppRoutes.rootHome, find.byType(HomePage), '01-home', 'home'],
    <Object>[
      AppRoutes.rootSchedule,
      find.byType(SchedulePage),
      '04-agenda',
      'schedule'
    ],
    <Object>[
      AppRoutes.rootShopping,
      find.byType(ShoppingPage),
      '05-compras',
      'shopping'
    ],
  ];

  for (final passo in roteiro) {
    final rota = passo[0] as String;
    final alvo = passo[1] as Finder;
    final nome = passo[2] as String;
    _telaAtual = passo[3] as String;

    AppNavigation.navigate(rota);
    await _esperarPor(tester, alvo, descricao: 'tela $nome');
    // A lista chega por rede; sem esta pausa o print sai com skeleton.
    await _respira(tester, duracao: const Duration(seconds: 3));
    await _janela(tester, nome);
  }
}
