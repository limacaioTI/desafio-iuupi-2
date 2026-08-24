import 'package:carteira_digital_escolar/core/api_client.dart';
import 'package:carteira_digital_escolar/models/user.dart';
import 'package:carteira_digital_escolar/providers/auth_provider.dart';
import 'package:carteira_digital_escolar/providers/theme_provider.dart';
import 'package:carteira_digital_escolar/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../helpers/test_storage.dart';

const _user = User(
  id: 1,
  name: 'João da Silva',
  cpf: '12345678900',
  school: 'Escola Exemplo',
  registration: '20260001',
  balance: 58.4,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Abrir as boxes do Hive é I/O real, então precisa rodar em `runAsync`
  // (mesma justificativa do helper `test_storage.dart`, usado no teste de
  // login). Depois de aberta, a leitura síncrona de `ThemeProvider` e o
  // campo `AuthProvider.user`, atribuído diretamente, não fazem I/O.
  Future<(AuthProvider, ThemeProvider)> buildProviders(WidgetTester tester) async {
    final result = await tester.runAsync(() async {
      final storage = await createTestStorageService();
      final auth = AuthProvider(ApiClient(), storage)..user = _user;
      final theme = ThemeProvider(storage);
      return (auth, theme);
    });
    return result!;
  }

  Widget wrap(AuthProvider auth, ThemeProvider theme) {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<ThemeProvider>.value(value: theme),
        ],
        child: const ProfileScreen(),
      ),
    );
  }

  testWidgets('mostra nome, escola, matrícula e o botão Sair', (tester) async {
    final (auth, theme) = await buildProviders(tester);

    await tester.pumpWidget(wrap(auth, theme));
    await tester.pump();

    expect(find.text('João da Silva'), findsOneWidget);
    expect(find.text('Escola Exemplo'), findsOneWidget);
    expect(find.text('20260001'), findsOneWidget);
    expect(find.text('Sair'), findsOneWidget);
  });

  testWidgets('mostra a opção de alternar o tema', (tester) async {
    final (auth, theme) = await buildProviders(tester);

    await tester.pumpWidget(wrap(auth, theme));
    await tester.pump();

    expect(find.byTooltip('Alternar aparência'), findsOneWidget);
    expect(find.text('Claro'), findsOneWidget);
  });
}
