import 'package:carteira_digital_escolar/core/api_client.dart';
import 'package:carteira_digital_escolar/providers/auth_provider.dart';
import 'package:carteira_digital_escolar/screens/login/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../helpers/test_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpLoginScreen(WidgetTester tester) async {
    final storage = await createTestStorageService();
    final auth = AuthProvider(ApiClient(), storage);

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<AuthProvider>.value(
          value: auth,
          child: const LoginScreen(),
        ),
      ),
    );
  }

  testWidgets('mostra os campos de CPF, senha e o botão Entrar', (tester) async {
    await pumpLoginScreen(tester);

    expect(find.widgetWithText(TextFormField, 'CPF'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Senha'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Entrar'), findsOneWidget);
  });

  testWidgets('mostra erros de validação ao tentar entrar com campos vazios', (tester) async {
    await pumpLoginScreen(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pump();

    expect(find.text('Informe o CPF'), findsOneWidget);
    expect(find.text('Informe a senha'), findsOneWidget);
  });

  testWidgets('não mostra erro de validação depois de preencher os campos', (tester) async {
    await pumpLoginScreen(tester);

    await tester.enterText(find.widgetWithText(TextFormField, 'CPF'), '12345678900');
    await tester.enterText(find.widgetWithText(TextFormField, 'Senha'), '123456');
    await tester.pump();

    // Os campos preenchidos não devem mostrar mensagem de validação
    // mesmo antes de submeter.
    expect(find.text('Informe o CPF'), findsNothing);
    expect(find.text('Informe a senha'), findsNothing);
  });
}
