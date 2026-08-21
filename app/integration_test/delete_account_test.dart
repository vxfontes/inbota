// Teste de integração do fluxo de exclusão de conta — Apple Guideline 5.1.1(v).
//
// ATENÇÃO: roda contra a API de PRODUÇÃO e APAGA DE VERDADE a conta que ele
// mesmo cria no início. Nenhuma outra conta é tocada: antes do passo destrutivo
// o teste abre Configurações > Conta e confere que o email logado é exatamente
// o de _email. Se não for, aborta sem disparar nenhum DELETE.
//
// Execução:
//   flutter test integration_test/delete_account_test.dart -d <udid>

import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:organiq/presentation/app.dart';
import 'package:organiq/presentation/routes/app_module.dart';
import 'package:organiq/presentation/screens/auth_module/pages/login_page.dart';
import 'package:organiq/presentation/screens/auth_module/pages/pre_login_page.dart';
import 'package:organiq/presentation/screens/auth_module/pages/signup_page.dart';
import 'package:organiq/presentation/screens/root_module/pages/root_page.dart';
import 'package:organiq/presentation/screens/settings_module/components/settings_delete_account_bottom_sheet.dart';
import 'package:organiq/presentation/screens/settings_module/pages/settings_page.dart';
import 'package:organiq/shared/components/oq_lib/oq_button.dart';
import 'package:organiq/shared/services/push/firebase_bootstrap.dart';
import 'package:organiq/shared/storage/app_preferences.dart';
import 'package:organiq/shared/tutorial/tutorial_keys.dart';

// Conta descartável criada e destruída por este teste. Fixa de propósito: se o
// teste morrer no meio, sobra uma conta só, com nome previsível para limpeza.
//
// NÃO é a mesma de _emailFixture: aquela fica viva entre rodadas e o signup
// daqui bateria em email duplicado se as duas fossem iguais.
const _nome = 'Teste Exclusao';
const _email = 'del.app.dylan02@organiq.app';
const _senhaCerta = 'Organiq2026del';

/// Conta que JÁ EXISTE, reaproveitada pelo teste do alerta. Ele só faz login
/// nela e nunca a apaga — por isso mede quantas rodadas for preciso sem
/// escrever nada novo em produção. A limpeza dela é manual, por fora.
const _emailFixture = 'del.app.dylan01@organiq.app';
// 14 caracteres: passa na validação de tamanho do backend (8..72) e por isso
// chega no handler e devolve 403 incorrect_password, que é o que queremos ver.
const _senhaErrada = 'senhaerrada123';

const _msgSenhaIncorreta = 'Senha incorreta. Tente de novo.';
const _msgRateLimit = 'Muitas tentativas. Aguarde um minuto e tente de novo.';
const _msgFalhaGenerica = 'Não foi possível excluir sua conta agora. Tente novamente.';

void _log(String mensagem) {
  debugPrint('[DEL] ${DateTime.now().toUtc().toIso8601String()} $mensagem');
}

/// Deixa o tempo REAL correr e depois desenha um frame.
///
/// `tester.pump(duration)` sozinho não serve para esperar rede: dependendo do
/// binding a duração é tempo controlado, não relógio de parede. `runAsync`
/// garante que o Future de verdade tenha chance de completar.
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

Future<bool> _apareceEm(
  WidgetTester tester,
  Finder alvo,
  Duration limite,
) async {
  final prazo = DateTime.now().add(limite);
  while (DateTime.now().isBefore(prazo)) {
    if (alvo.evaluate().isNotEmpty) return true;
    await _respira(tester);
  }
  return false;
}

/// Espera algo SUMIR da tela. Existe porque o `errorText` do InputDecorator
/// não some no mesmo frame em que vira null: o Material faz fade-out e mantém
/// o Text montado durante a animação. Um `expect(findsNothing)` logo depois do
/// enterText mede um frame só e pega a mensagem ainda desaparecendo. O limite
/// continua curto de propósito — se a mensagem ficar grudada, isso é bug e o
/// teste tem que falhar.
Future<void> _sumirEm(
  WidgetTester tester,
  Finder alvo, {
  Duration limite = const Duration(seconds: 5),
  required String descricao,
}) async {
  final prazo = DateTime.now().add(limite);
  while (DateTime.now().isBefore(prazo)) {
    if (alvo.evaluate().isEmpty) return;
    await _respira(tester);
  }
  fail('Timeout de ${limite.inSeconds}s esperando sumir: $descricao');
}

Finder _botao(String rotulo) => find.widgetWithText(OQButton, rotulo);

Finder _campo(String rotulo) => find.widgetWithText(TextField, rotulo);

Finder get _sheetExcluir => find.byType(SettingsDeleteAccountBottomSheet);

Finder get _botaoConfirmarExclusao => find.descendant(
      of: _sheetExcluir,
      matching: _botao('Excluir conta'),
    );

Finder get _campoSenhaSheet => find.descendant(
      of: _sheetExcluir,
      matching: find.byType(TextField),
    );

Future<void> _tocar(WidgetTester tester, Finder alvo) async {
  await tester.ensureVisible(alvo);
  await tester.pump();
  await tester.tap(alvo);
  await _respira(tester);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ==========================================================================
  // Mede o que acontece DEPOIS de responder o alerta nativo de notificação —
  // em especial o "Não Permitir", que é o botão que o revisor da Apple mais
  // aperta. A pergunta não é "o alerta some", é: o app NAVEGA, e em quanto
  // tempo. signup_page.dart:49, login_page.dart:67 e splash_page.dart:54 dão
  // await no initialize() ANTES de navegar; se esse future não resolver, o
  // usuário fica preso na tela em que estava.
  //
  // Faz login numa conta que já existe em vez de criar uma: não escreve nada
  // em produção e não gasta a janela de 5 DELETE/min, então pode repetir.
  //
  // Só faz sentido logo depois de zerar a decisão de notificação do iOS:
  //   xcrun simctl uninstall <udid> <bundle>
  //   flutter test integration_test/delete_account_test.dart -d <udid> \
  //       --plain-name 'alerta de notificacao'
  // ==========================================================================
  testWidgets('alerta de notificacao — o app navega depois do Nao Permitir?',
      (tester) async {
    await tester.runAsync(() async {
      try {
        await FirebaseBootstrap.initialize();
      } catch (erro) {
        _log('firebase falhou no bootstrap (seguindo): $erro');
      }
      await AppPreferences.initialize();
    });

    await tester.pumpWidget(
      ModularApp(module: AppModule(), child: const AppWidget()),
    );
    await _respira(tester, duracao: const Duration(seconds: 2));
    _log('app iniciado (teste do alerta)');

    // O alerta pode subir por dois caminhos e os dois valem, porque o await é
    // o mesmo: se o keychain sobreviveu ao uninstall o app abre logado e quem
    // pede a permissão é o splash; se não sobreviveu, quem pede é o login.
    // Aceito os dois e digo no log qual foi, em vez de assumir um.
    final deslogado =
        await _apareceEm(tester, find.byType(PreLoginPage), const Duration(seconds: 20));

    if (!deslogado) {
      _log('nao abriu deslogado — o alerta sobe pelo SPLASH (splash_page.dart:54)');
      _log('=== ESPERANDO O TOQUE HUMANO NO ALERTA (ate 20min) ===');
      final abriuEspera = DateTime.now();
      await _esperarPor(tester, find.byType(RootPage),
          limite: const Duration(minutes: 20),
          descricao: 'o app navegar para o root depois do alerta, pelo splash. '
              'SE ESTOUROU AQUI O APP NAO NAVEGOU = BLOQUEANTE DE SUBMISSAO');
      // Este numero NAO e latencia e nao pode ser reportado como tal: ele comeca
      // a contar antes do humano tocar no alerta, entao inclui o tempo de leitura
      // e decisao da pessoa. Ja enganou duas vezes (5a: 753343ms; 6: 10807ms, que
      // caiu quase em cima de uma previsao de ~10s e nao a confirmava).
      // A latencia real sai dos frames de 1s: ultimo frame COM alerta -> RootPage.
      _log('=== APP NAVEGOU (splash). CONTAMINADO, inclui decisao humana: '
          '${DateTime.now().difference(abriuEspera).inMilliseconds}ms desde o '
          'inicio da espera. Latencia real: medir pelos frames. ===');
      return;
    }

    _log('abriu deslogado — o alerta sobe pelo LOGIN (login_page.dart:67)');
    await _tocar(tester, _botao('Já tenho conta'));
    await _esperarPor(tester, find.byType(LoginPage), descricao: 'tela de login');

    await tester.enterText(_campo('Email'), _emailFixture);
    await tester.enterText(_campo('Senha'), _senhaCerta);
    await _respira(tester);

    final abriuEspera = DateTime.now();
    await _tocar(tester, _botao('Entrar'));
    _log('login submetido em $_emailFixture — o alerta NATIVO deve subir agora');
    _log('=== ESPERANDO O TOQUE HUMANO NO ALERTA (ate 20min) ===');

    await _esperarPor(tester, find.byType(RootPage),
        limite: const Duration(minutes: 20),
        descricao: 'o app navegar para o root depois do alerta, pelo login. '
            'SE ESTOUROU AQUI O APP NAO NAVEGOU = BLOQUEANTE DE SUBMISSAO');

    // Mesma contaminação do ramo do splash — ver comentário lá em cima.
    final levou = DateTime.now().difference(abriuEspera);
    _log('=== APP NAVEGOU (login). CONTAMINADO, inclui decisao humana: '
        '${levou.inMilliseconds}ms desde o submit. '
        'Latencia real: medir pelos frames. ===');

    // A conta fixture não é apagada aqui de propósito: ela serve de novo na
    // próxima rodada. Limpeza dela é manual, por fora.
    expect(find.byType(RootPage), findsOneWidget);
  }, timeout: const Timeout(Duration(minutes: 30)));

  testWidgets('exclusao de conta no app — 5.1.1(v)', (tester) async {
    // ---------------------------------------------------------------- boot
    // Mesmo bootstrap do main.dart, sem o runZonedGuarded: dentro do
    // integration_test a zona própria do main brigaria com a do binding.
    await tester.runAsync(() async {
      try {
        await FirebaseBootstrap.initialize();
      } catch (erro) {
        _log('firebase falhou no bootstrap (seguindo): $erro');
      }
      await AppPreferences.initialize();
    });

    await tester.pumpWidget(
      ModularApp(module: AppModule(), child: const AppWidget()),
    );
    await _respira(tester, duracao: const Duration(seconds: 2));
    _log('app iniciado');

    // -------------------------------------------------- sessão limpa antes
    // O simulador pode estar logado em outra conta. Sair primeiro garante que
    // a sessão usada daqui pra frente é a que este teste criou.
    // 40s e não 12: depois de um `simctl uninstall` o token do Keychain
    // SOBREVIVE e o app volta logado, então este ramo passa a ser o normal e
    // não mais a exceção. O boot ainda espera o GET /v1/me, que na Render pode
    // vir de container frio. Se a janela fosse curta o teste cairia no ramo
    // errado e morreria esperando a tela deslogada que nunca vem.
    if (await _apareceEm(tester, find.byType(RootPage), const Duration(seconds: 40))) {
      _log('app abriu logado — deslogando antes de comecar');
      await _dispensarTutorial(tester);
      await _tocar(tester, find.byKey(TutorialKeys.appBarSettings));
      await _esperarPor(tester, find.byType(SettingsPage),
          descricao: 'tela de Configuracoes (logout previo)');
      await _tocar(tester, _botao('Sair'));
    }

    await _esperarPor(tester, find.byType(PreLoginPage),
        descricao: 'tela inicial deslogada');
    _log('deslogado, na tela inicial');

    // ------------------------------------------------------------- signup
    await _tocar(tester, _botao('Começar'));
    await _esperarPor(tester, find.byType(SignupPage),
        descricao: 'tela Criar conta');

    await tester.enterText(_campo('Nome completo'), _nome);
    await tester.enterText(_campo('Email'), _email);
    await tester.enterText(_campo('Senha'), _senhaCerta);
    await _respira(tester);

    await _tocar(tester, _botao('Criar conta'));
    _log('signup submetido — signup_page.dart:49 vai dar await no push antes de '
        'navegar, entao o alerta NATIVO de notificacao deve subir agora');
    _log('=== ESPERANDO O TOQUE HUMANO NO ALERTA (ate 10min) ===');

    // O alerta de permissao é do SpringBoard: WidgetTester.tap injeta direto no
    // engine do Flutter e não alcança alerta de sistema. Só mão humana resolve,
    // uma vez por instalação. Timeout largo de propósito — o que está sendo
    // medido aqui é se o app NAVEGA depois da resposta, e um limite curto
    // confundiria "app travado" com "pessoa demorou pra clicar".
    await _esperarPor(tester, find.byType(RootPage),
        limite: const Duration(minutes: 10),
        descricao: 'app navegar para o root depois da resposta ao alerta '
            'de notificacao (se o alerta ja foi respondido e mesmo assim nao '
            'navegou, signup_page.dart:49 trava o fluxo — BLOQUEANTE DE SUBMISSAO)');
    _log('=== APP NAVEGOU PARA O ROOT depois do alerta ===');
    _log('conta criada e logada: $_email');

    await _dispensarTutorial(tester);

    // ------------------------------- metade (i) da descoberta: achar Ajustes
    final gear = find.byKey(TutorialKeys.appBarSettings);
    expect(gear, findsOneWidget,
        reason: 'botao de Configuracoes deve estar visivel no app bar do root');
    await _tocar(tester, gear);
    await _esperarPor(tester, find.byType(SettingsPage),
        descricao: 'tela de Configuracoes');
    _log('metade (i) OK: cheguei em Configuracoes por toque no app bar');

    // ------------------------ metade (ii): "Excluir conta" cabe sem rolar?
    await _respira(tester, duracao: const Duration(seconds: 1));
    final itemExcluir = find.text('Excluir conta');
    expect(itemExcluir, findsOneWidget,
        reason: '"Excluir conta" deve existir na propria tela de Configuracoes');

    final caixa = tester.getRect(itemExcluir);
    final tela = tester.view.physicalSize / tester.view.devicePixelRatio;
    final cabeSemRolar = caixa.bottom <= tela.height;
    _log('MEDIDA descoberta(ii): item.bottom=${caixa.bottom.toStringAsFixed(1)} '
        'altura_tela=${tela.height.toStringAsFixed(1)} '
        'cabe_sem_rolar=$cabeSemRolar');

    // Janela parada para o print externo (simctl io screenshot). É o artefato
    // que a Vanessa precisa ver: o que o revisor da Apple enxerga de cara.
    _log('=== JANELA DE SCREENSHOT ABERTA (15s) ===');
    await _respira(tester, duracao: const Duration(seconds: 15));
    _log('=== JANELA DE SCREENSHOT FECHADA ===');

    // ------------------------------------------- botao travado com campo vazio
    await _tocar(tester, itemExcluir);
    await _esperarPor(tester, _sheetExcluir, descricao: 'bottom sheet de exclusao');

    final confirmarVazio = tester.widget<OQButton>(_botaoConfirmarExclusao);
    expect(confirmarVazio.onPressed, isNull,
        reason: 'com o campo de senha vazio o botao de confirmar deve estar travado');
    _log('botao travado com senha vazia: OK');

    // ------------------------------ senha errada #1 (o teste que a Apple faz)
    final primeiroDelete = DateTime.now();
    await tester.enterText(_campoSenhaSheet, _senhaErrada);
    await _respira(tester);
    await _tocar(tester, _botaoConfirmarExclusao);

    await _esperarPor(tester, find.text(_msgSenhaIncorreta),
        limite: const Duration(seconds: 45),
        descricao: 'mensagem "$_msgSenhaIncorreta" inline no sheet');
    _log('senha errada #1: mensagem inline apareceu');

    // A asserção que vale a submissão: errar a senha não pode deslogar ninguém.
    expect(_sheetExcluir, findsOneWidget,
        reason: 'o sheet deve continuar aberto depois da senha errada');
    expect(find.byType(SettingsPage), findsOneWidget,
        reason: 'deve continuar em Configuracoes depois da senha errada');
    expect(find.byType(PreLoginPage), findsNothing,
        reason: 'senha errada NAO pode jogar o usuario para fora do app');
    expect(find.byType(LoginPage), findsNothing,
        reason: 'senha errada NAO pode levar para a tela de login');
    _log('sessao intacta depois da senha errada: OK');

    // -------------------------------------- digitar limpa a mensagem de erro
    await tester.enterText(_campoSenhaSheet, '${_senhaErrada}x');
    await _sumirEm(tester, find.text(_msgSenhaIncorreta),
        descricao: 'a mensagem de erro deve sumir assim que o usuario digita');
    _log('erro some ao digitar: OK');

    // ------------------------------------------------------ senha errada #2
    await tester.enterText(_campoSenhaSheet, _senhaErrada);
    await _respira(tester);
    await _tocar(tester, _botaoConfirmarExclusao);
    await _esperarPor(tester, find.text(_msgSenhaIncorreta),
        limite: const Duration(seconds: 45),
        descricao: 'mensagem "$_msgSenhaIncorreta" na segunda tentativa');
    expect(find.byType(SettingsPage), findsOneWidget);
    _log('senha errada #2: mesmo comportamento, sessao intacta');

    // ---------------------------------------------- fechar pelo Cancelar
    await _tocar(tester, find.descendant(of: _sheetExcluir, matching: _botao('Cancelar')));
    await _respira(tester, duracao: const Duration(seconds: 1));
    expect(_sheetExcluir, findsNothing, reason: 'Cancelar deve fechar o sheet');
    expect(find.byType(SettingsPage), findsOneWidget);
    _log('Cancelar fecha o sheet sem efeito colateral: OK');

    // ------------------------------------------------ TRAVA DE SEGURANÇA
    // Antes de qualquer coisa destrutiva, confirmar na tela quem está logado.
    // Se não for a conta que este teste criou, aborta sem disparar DELETE.
    await _tocar(tester, find.text('Conta'));
    await _esperarPor(tester, find.text(_email),
        limite: const Duration(seconds: 45),
        descricao: 'email $_email na tela Conta (trava de seguranca)');
    _log('TRAVA DE SEGURANCA OK: a conta logada e $_email');
    // De quebra, essa tela só renderiza porque o token ainda vale — prova
    // adicional de que as duas senhas erradas não derrubaram a sessão.

    await _tocar(tester, find.byIcon(Icons.arrow_back_rounded));
    await _esperarPor(tester, find.byType(SettingsPage),
        descricao: 'voltar para Configuracoes');

    // ------------------------------------------------- espera de janela real
    // O rate limit é do servidor: 5 DELETE /v1/me por minuto por IP, janela
    // fixa que começa na primeira requisição. Já gastamos 2 nas senhas erradas.
    // Esperar a janela virar faz o DELETE de verdade ser o primeiro de um
    // balde novo — sem isso um 429 deixaria a conta VIVA com o teste verde.
    // O relógio que conta é o do servidor: encurtar esse tempo porque "script
    // é mais rápido que humano" não muda nada para ele. Não diminua.
    final alvo = primeiroDelete.add(const Duration(seconds: 65));
    final falta = alvo.difference(DateTime.now());
    if (falta > Duration.zero) {
      _log('esperando ${falta.inSeconds}s para a janela de rate limit virar');
      await tester.runAsync(() => Future<void>.delayed(falta));
      await tester.pump();
    }
    final esperou = DateTime.now().difference(primeiroDelete);
    _log('janela virada: ${esperou.inSeconds}s desde o primeiro DELETE');

    // ----------------------------------------- PASSO DESTRUTIVO (irreversível)
    await _tocar(tester, find.text('Excluir conta'));
    await _esperarPor(tester, _sheetExcluir, descricao: 'sheet reaberto');
    await tester.enterText(_campoSenhaSheet, _senhaCerta);
    await _respira(tester);
    _log('>>> disparando DELETE de verdade em $_email');
    await _tocar(tester, _botaoConfirmarExclusao);

    // Regra inegociável: 429 no passo destrutivo significa CONTA VIVA.
    // Falhar alto e não tentar de novo.
    final saiu = await _apareceEm(
      tester,
      find.byType(PreLoginPage),
      const Duration(seconds: 60),
    );

    if (find.text(_msgRateLimit).evaluate().isNotEmpty) {
      fail('RATE LIMIT no passo destrutivo: a conta $_email NAO foi apagada e '
          'continua VIVA em producao. Limpeza manual declarada. Nao repetir em laco.');
    }
    if (find.text(_msgFalhaGenerica).evaluate().isNotEmpty) {
      fail('Falha generica no passo destrutivo: estado da conta $_email é '
          'DESCONHECIDO. Verificar no servidor antes de qualquer nova tentativa.');
    }
    if (!saiu) {
      fail('Depois do DELETE o app nao voltou para a tela inicial em 60s. '
          'Estado da conta $_email é DESCONHECIDO — verificar no servidor.');
    }

    expect(find.byType(PreLoginPage), findsOneWidget,
        reason: 'depois de excluir a conta o app deve voltar deslogado');
    _log('conta excluida e app deslogado');

    // -------------------------------- prova externa: o login tem que falhar
    await _tocar(tester, _botao('Já tenho conta'));
    await _esperarPor(tester, find.byType(LoginPage), descricao: 'tela de login');
    await tester.enterText(_campo('Email'), _email);
    await tester.enterText(_campo('Senha'), _senhaCerta);
    await _respira(tester);
    await _tocar(tester, _botao('Entrar'));

    final entrou = await _apareceEm(
      tester,
      find.byType(RootPage),
      const Duration(seconds: 45),
    );
    expect(entrou, isFalse,
        reason: 'login com a conta excluida NAO pode funcionar — '
            'se funcionou, a conta continua viva no servidor');
    _log('login com a conta excluida falhou, como esperado: conta morreu no servidor');
    _log('=== FIM: fluxo 5.1.1(v) aprovado ===');
  }, timeout: const Timeout(Duration(minutes: 25)));
}

/// O tutorial é um overlay que cobre a tela e engole os toques. A flag dele é
/// por DISPOSITIVO (SharedPreferences), não por conta — então ele pode ou não
/// aparecer dependendo do histórico do simulador.
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
