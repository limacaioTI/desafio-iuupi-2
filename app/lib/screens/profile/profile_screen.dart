import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/responsive_container.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final themeMode = context.watch<ThemeProvider>().themeMode;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ResponsiveContainer(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProfileRow(label: 'Nome', value: user.name),
                    _ProfileRow(label: 'Escola', value: user.school),
                    _ProfileRow(label: 'Matrícula', value: user.registration),
                    const SizedBox(height: 8),
                    Text('Aparência', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 8),
                    _ThemeModeToggleButton(themeMode: themeMode),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await context.read<AuthProvider>().logout();
                          if (context.mounted) {
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          }
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('Sair'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _ThemeModeToggleButton extends StatelessWidget {
  final ThemeMode themeMode;

  const _ThemeModeToggleButton({required this.themeMode});

  static const _icons = {
    ThemeMode.light: Icons.light_mode_outlined,
    ThemeMode.dark: Icons.dark_mode_outlined,
  };

  static const _labels = {
    ThemeMode.light: 'Claro',
    ThemeMode.dark: 'Escuro',
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: () => context.read<ThemeProvider>().cycleThemeMode(),
          icon: Icon(_icons[themeMode]),
          tooltip: 'Alternar aparência',
        ),
        const SizedBox(width: 12),
        Text(_labels[themeMode]!, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
