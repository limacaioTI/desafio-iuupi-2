import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('debug: cria storage dentro de testWidgets', (tester) async {
    print('ANTES do createTestStorageService');
    final storage = await createTestStorageService();
    print('DEPOIS do createTestStorageService: token=${storage.token}');
  });

  testWidgets('debug: pump de um widget simples', (tester) async {
    print('ANTES do pumpWidget');
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('oi'))));
    print('DEPOIS do pumpWidget');
    expect(find.text('oi'), findsOneWidget);
  });
}
