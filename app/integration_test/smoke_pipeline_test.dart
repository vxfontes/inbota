// Teste descartável de UM propósito: provar que o caminho
// `flutter test integration_test/ -d <udid>` compila, instala e roda.
//
// POR QUE ELE EXISTE, se eu já rodei `xcodebuild build-for-testing` e passou:
// porque o xcodebuild NÃO passa pelo flutter_tools, e a falha que me derrubou
// mora dentro do flutter_tools. O `ios/mac.dart:342-350` só corrige o
// Package.swift gerado (que nasce em 13.0, `darwin/darwin.dart:70`) se
// `buildSettings['IPHONEOS_DEPLOYMENT_TARGET']` não vier nulo — e
// `ios/xcodeproj.dart:283-299` devolve MAPA VAZIO quando o
// `xcodebuild -showBuildSettings` estoura o timeout. xcodebuild verde só me diz
// que o projeto está são; não diz nada sobre esse trecho.
//
// E por que não usar a própria captura pra verificar: a captura ARMA o alerta
// de notificação e fica esperando a Vanessa tocar. Usar ela como teste de
// encanamento gastaria uma visita dela pra responder uma pergunta de build.
// Este arquivo responde a mesma pergunta em ~2min e sem envolver ninguém.
//
// DESCARTÁVEL: entra na mesma lista de reversão dos outros arquivos de
// integration_test/ antes do archive.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('canal de integration_test esta vivo', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Center(child: Text('encanamento ok')))),
    );
    expect(find.text('encanamento ok'), findsOneWidget);
    // Marcador com o mesmo formato dos da captura: se este texto sair no
    // stdout, o build nativo passou, o app subiu no simulador e o canal de
    // ida-e-volta com o driver funciona. É exatamente o que eu preciso saber.
    debugPrint('=== ENCANAMENTO OK ===');
  });
}
