import 'package:carteira_digital_escolar/widgets/state_views.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('LoadingView mostra um indicador de progresso', (tester) async {
    await tester.pumpWidget(_wrap(const LoadingView()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  group('ErrorView', () {
    testWidgets('mostra a mensagem recebida e um botão de tentar novamente', (tester) async {
      await tester.pumpWidget(
        _wrap(ErrorView(message: 'Não foi possível carregar.', onRetry: () {})),
      );

      expect(find.text('Não foi possível carregar.'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
    });

    testWidgets('chama onRetry ao tocar no botão', (tester) async {
      var retried = false;

      await tester.pumpWidget(
        _wrap(ErrorView(message: 'Erro', onRetry: () => retried = true)),
      );
      await tester.tap(find.text('Tentar novamente'));
      await tester.pump();

      expect(retried, isTrue);
    });
  });

  testWidgets('EmptyView mostra a mensagem recebida', (tester) async {
    await tester.pumpWidget(_wrap(const EmptyView(message: 'Nenhuma transação encontrada.')));

    expect(find.text('Nenhuma transação encontrada.'), findsOneWidget);
  });

  group('OfflineBanner', () {
    testWidgets('mostra o aviso de offline sem horário quando cachedAt é nulo', (tester) async {
      await tester.pumpWidget(_wrap(const OfflineBanner()));

      expect(
        find.textContaining('Sem conexão. Exibindo os últimos dados salvos'),
        findsOneWidget,
      );
    });

    testWidgets('inclui o horário quando cachedAt é informado', (tester) async {
      final cachedAt = DateTime(2026, 8, 22, 9, 5);

      await tester.pumpWidget(_wrap(OfflineBanner(cachedAt: cachedAt)));

      expect(find.textContaining('09:05'), findsOneWidget);
    });
  });
}
