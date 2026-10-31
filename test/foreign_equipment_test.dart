import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:evergreen/core/data/evergreen_repository.dart';
import 'package:evergreen/core/errors/error_handler.dart';
import 'package:evergreen/core/errors/failures.dart';
import 'package:evergreen/core/network/api_client.dart';
import 'package:evergreen/core/network/api_exception.dart';
import 'package:evergreen/features/amcs/data/equipment_provider.dart';
import 'package:evergreen/features/auth/domain/models/user_model.dart';

/// Answers every `post` with [response] and records the paths called.
class _FakeApi implements ApiClient {
  _FakeApi(this.response);
  final Either<Failure, dynamic> response;
  final List<String> calls = [];

  @override
  Future<Either<Failure, T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic data)? parser,
  }) async {
    calls.add(path);
    return response.map((v) => v as T);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

User user(UserRole role, [List<int> companyIds = const []]) => User(
      id: '1',
      email: 'u@x.com',
      name: 'U',
      role: role,
      companies: [
        for (final id in companyIds) UserCompany(id: id, name: 'C$id')
      ],
    );

Map<String, dynamic> equipmentBody(int companyId) => {
      'success': 200,
      'data': {
        'id': 11,
        'name': 'Chiller',
        'company_link': companyId,
        'company': {'id': companyId, 'name': 'Co'},
        'tasks': const [],
      },
    };

Either<Failure, dynamic> forbiddenEnvelope() => Left(
      ErrorHandler.handleException(
        const ApiException(403, foreignEquipmentMessage),
      ),
    );

void main() {
  group('getInfo company scope', () {
    test('client sees equipment of their own company', () async {
      final api = EquipmentApi(_FakeApi(Right(equipmentBody(2))));
      final info = await api.getInfo('11', user: user(UserRole.client, [2]));
      expect(info.equipment.id, 11);
    });

    for (final role in [UserRole.client, UserRole.clientAdmin]) {
      test('${role.name} is blocked from another company', () async {
        final api = EquipmentApi(_FakeApi(Right(equipmentBody(3))));
        expect(
          api.getInfo('11', user: user(role, [2])),
          throwsA(isA<ForeignEquipmentException>()),
        );
      });
    }

    test('client with no linked companies is blocked', () async {
      final api = EquipmentApi(_FakeApi(Right(equipmentBody(3))));
      expect(
        api.getInfo('11', user: user(UserRole.client)),
        throwsA(isA<ForeignEquipmentException>()),
      );
    });

    for (final role in [
      UserRole.superAdmin,
      UserRole.manager,
      UserRole.seniorTechnician,
      UserRole.technician,
    ]) {
      test('${role.name} is unaffected', () async {
        final api = EquipmentApi(_FakeApi(Right(equipmentBody(3))));
        final info = await api.getInfo('11', user: user(role));
        expect(info.equipment.companyId, 3);
      });
    }

    test('backend 403 envelope becomes the company message for clients',
        () async {
      final api = EquipmentApi(_FakeApi(forbiddenEnvelope()));
      await expectLater(
        api.getInfo('11', user: user(UserRole.clientAdmin, [2])),
        throwsA(
          isA<ForeignEquipmentException>().having(
            (e) => '$e',
            'message',
            'This equipment does not belong to your company',
          ),
        ),
      );
    });

    test('bare HTTP 403 (Access denied) is treated the same for clients', () {
      expect(
        isForeignEquipmentFailure(
          Failure.authentication(message: 'Access denied'),
          UserRole.client,
        ),
        isTrue,
      );
    });

    test('other failures pass through unchanged', () async {
      final api = EquipmentApi(
        _FakeApi(
          Left(
            ErrorHandler.handleException(
              const ApiException(404, 'Data not found for equipment: 11'),
            ),
          ),
        ),
      );
      expect(
        api.getInfo('11', user: user(UserRole.client, [2])),
        throwsA(isA<FailureException>()),
      );
    });

    test('a 403 for an admin is not rewritten', () {
      expect(
        isForeignEquipmentFailure(
          Failure.server(message: 'nope', statusCode: 403),
          UserRole.manager,
        ),
        isFalse,
      );
    });

    test('verify is never called by getInfo', () async {
      final fake = _FakeApi(Right(equipmentBody(3)));
      await expectLater(
        EquipmentApi(fake).getInfo('11', user: user(UserRole.client, [2])),
        throwsA(isA<ForeignEquipmentException>()),
      );
      expect(fake.calls, ['user/getEquipmentInfo']);
    });
  });
}
