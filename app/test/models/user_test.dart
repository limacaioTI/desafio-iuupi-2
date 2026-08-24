import 'package:carteira_digital_escolar/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('User.fromJson', () {
    test('mapeia todos os campos do JSON da API', () {
      final json = {
        'id': 1,
        'name': 'João da Silva',
        'cpf': '12345678900',
        'school': 'Escola Exemplo',
        'registration': '20260001',
        'balance': 58.4,
        'avatar_url': 'https://i.pravatar.cc/300?img=12',
      };

      final user = User.fromJson(json);

      expect(user.id, 1);
      expect(user.name, 'João da Silva');
      expect(user.cpf, '12345678900');
      expect(user.school, 'Escola Exemplo');
      expect(user.registration, '20260001');
      expect(user.balance, 58.4);
      expect(user.avatarUrl, 'https://i.pravatar.cc/300?img=12');
    });

    test('aceita avatar_url nulo', () {
      final json = {
        'id': 1,
        'name': 'João da Silva',
        'cpf': '12345678900',
        'school': 'Escola Exemplo',
        'registration': '20260001',
        'balance': 58.4,
        'avatar_url': null,
      };

      final user = User.fromJson(json);

      expect(user.avatarUrl, isNull);
    });

    test('converte balance inteiro (num) para double', () {
      final json = {
        'id': 1,
        'name': 'João',
        'cpf': '12345678900',
        'school': 'Escola',
        'registration': '1',
        'balance': 100, // int, não double
        'avatar_url': null,
      };

      final user = User.fromJson(json);

      expect(user.balance, 100.0);
      expect(user.balance, isA<double>());
    });
  });

  group('User.toJson', () {
    test('faz o round-trip com fromJson', () {
      const user = User(
        id: 2,
        name: 'Maria',
        cpf: '00000000000',
        school: 'Escola X',
        registration: '999',
        balance: 12.5,
        avatarUrl: null,
      );

      final roundTripped = User.fromJson(user.toJson());

      expect(roundTripped.id, user.id);
      expect(roundTripped.name, user.name);
      expect(roundTripped.balance, user.balance);
    });
  });
}
