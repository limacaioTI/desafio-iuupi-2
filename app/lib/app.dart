import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/storage_service.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/transactions_provider.dart';
import 'providers/wallet_provider.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/login/login_screen.dart';

class App extends StatelessWidget {
  final StorageService storageService;

  const App({super.key, required this.storageService});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();

    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(apiClient, storageService),
        ),
        ChangeNotifierProvider(
          create: (_) => WalletProvider(apiClient, storageService),
        ),
        ChangeNotifierProvider(
          create: (_) => TransactionsProvider(apiClient, storageService),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(storageService),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp(
          title: 'Carteira Digital Escolar',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorSchemeSeed: Colors.indigo,
            brightness: Brightness.light,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorSchemeSeed: Colors.indigo,
            brightness: Brightness.dark,
            useMaterial3: true,
          ),
          themeMode: themeProvider.themeMode,
          home: const _AuthGate(),
        ),
      ),
    );
  }
}

/// Decide qual tela mostrar de acordo com o estado de autenticação:
/// enquanto restaura a sessão salva, mostra um loading; sem sessão, Login;
/// com sessão, Dashboard.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    switch (auth.status) {
      case AuthStatus.checking:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthStatus.loggedIn:
        return const DashboardScreen();
      case AuthStatus.loggedOut:
      case AuthStatus.loggingIn:
        return const LoginScreen();
    }
  }
}
