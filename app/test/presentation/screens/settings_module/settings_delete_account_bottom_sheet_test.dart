// Locks the behaviour an App Store reviewer exercises: typing the wrong
// password must show an inline message and keep the user exactly where they
// are. If this flow ever navigates on error, the reviewer gets kicked out of
// the deletion screen and the submission fails.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:organiq/presentation/screens/settings_module/components/settings_delete_account_bottom_sheet.dart';
import 'package:organiq/shared/components/oq_lib/index.dart';

void main() {
  group('SettingsDeleteAccountBottomSheet', () {
    testWidgets('senha errada mostra erro inline e NÃO sai da tela', (tester) async {
      final harness = await _openSheet(
        tester,
        onConfirm: (_) async => 'Senha incorreta. Tente de novo.',
      );

      await _submit(tester, password: 'senha-errada');

      expect(find.text('Senha incorreta. Tente de novo.'), findsOneWidget);
      expect(find.byType(SettingsDeleteAccountBottomSheet), findsOneWidget);
      expect(harness.closed, isFalse);
    });

    testWidgets('mensagem de 429 aparece inline igual, sem string crua', (tester) async {
      await _openSheet(
        tester,
        onConfirm: (_) async => 'Muitas tentativas. Aguarde um minuto e tente de novo.',
      );

      await _submit(tester, password: 'senha-certa');

      expect(find.text('Muitas tentativas. Aguarde um minuto e tente de novo.'), findsOneWidget);
      expect(find.textContaining('rate_limited'), findsNothing);
      expect(find.byType(SettingsDeleteAccountBottomSheet), findsOneWidget);
    });

    testWidgets('sucesso fecha o sheet devolvendo true', (tester) async {
      final harness = await _openSheet(tester, onConfirm: (_) async => null);

      await _submit(tester, password: 'senha-certa');

      expect(find.byType(SettingsDeleteAccountBottomSheet), findsNothing);
      expect(harness.result, isTrue);
    });

    testWidgets('digitar de novo limpa o erro anterior', (tester) async {
      await _openSheet(tester, onConfirm: (_) async => 'Senha incorreta. Tente de novo.');

      await _submit(tester, password: 'errada');
      expect(find.text('Senha incorreta. Tente de novo.'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'outra');
      await tester.pump();

      expect(find.text('Senha incorreta. Tente de novo.'), findsNothing);
    });

    testWidgets('senha vazia não dispara requisição', (tester) async {
      var calls = 0;
      await _openSheet(
        tester,
        onConfirm: (_) async {
          calls++;
          return null;
        },
      );

      await tester.tap(find.widgetWithText(OQButton, 'Excluir conta'));
      await tester.pumpAndSettle();

      expect(calls, 0);
      expect(find.byType(SettingsDeleteAccountBottomSheet), findsOneWidget);
    });

    testWidgets('cancelar fecha sem confirmar', (tester) async {
      var calls = 0;
      final harness = await _openSheet(
        tester,
        onConfirm: (_) async {
          calls++;
          return null;
        },
      );

      await tester.tap(find.widgetWithText(OQButton, 'Cancelar'));
      await tester.pumpAndSettle();

      expect(calls, 0);
      expect(harness.result, isNot(isTrue));
      expect(find.byType(SettingsDeleteAccountBottomSheet), findsNothing);
    });
  });
}

Future<void> _submit(WidgetTester tester, {required String password}) async {
  await tester.enterText(find.byType(TextField), password);
  await tester.pump();
  await tester.tap(find.widgetWithText(OQButton, 'Excluir conta'));
  await tester.pumpAndSettle();
}

Future<_SheetHarness> _openSheet(
  WidgetTester tester, {
  required Future<String?> Function(String password) onConfirm,
}) async {
  final harness = _SheetHarness();

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      body: SettingsDeleteAccountBottomSheet(onConfirm: onConfirm),
                    ),
                  ),
                );
                harness.closed = true;
                harness.result = result;
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();

  return harness;
}

class _SheetHarness {
  bool closed = false;
  bool? result;
}
