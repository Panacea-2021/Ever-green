import 'package:evergreen/core/errors/failures.dart';
import 'package:evergreen/features/audit/data/audit_log_provider.dart';
import 'package:evergreen/features/auth/presentation/screens/change_password_screen.dart';
import 'package:evergreen/features/profile/data/my_companies_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChangePasswordScreen.validate', () {
    String? v(String current, String next, String confirm) =>
        ChangePasswordScreen.validate(
          current: current,
          next: next,
          confirm: confirm,
        );

    test('requires the current password', () {
      expect(v('', 'abcdef', 'abcdef'), isNotNull);
    });

    test('new password is 6 to 20 characters', () {
      expect(v('old123', 'abcde', 'abcde'), contains('at least 6'));
      expect(v('old123', 'a' * 21, 'a' * 21), contains('at most 20'));
      expect(v('old123', 'abcdef', 'abcdef'), isNull);
      expect(v('old123', 'a' * 20, 'a' * 20), isNull);
    });

    test('confirmation must match and differ from current', () {
      expect(v('old123', 'abcdef', 'abcdeg'), 'Passwords do not match');
      expect(v('same12', 'same12', 'same12'), isNotNull);
    });
  });

  group('companiesFromMe', () {
    test('parses full company rows from auth/me', () {
      final companies = companiesFromMe({
        'status': 200,
        'data': {
          'id': 3,
          'company_user': [
            {
              'company': {
                'id': 7,
                'name': 'Acme',
                'branch_name': 'Madhapur',
                'gst_number': '36ABCDE1234F1Z5',
                'location': 'Hyderabad',
                'email': 'ops@acme.test',
                'service_type': 'amc',
                'is_active': true,
              },
            },
          ],
        },
      });
      expect(companies, hasLength(1));
      final c = companies.single;
      expect(c.id, 7);
      expect(c.name, 'Acme');
      expect(c.branchName, 'Madhapur');
      expect(c.gstNumber, '36ABCDE1234F1Z5');
      expect(c.location, 'Hyderabad');
    });

    test('no links yields an empty list', () {
      expect(companiesFromMe({'data': {'company_user': []}}), isEmpty);
      expect(companiesFromMe({'data': {}}), isEmpty);
      expect(companiesFromMe(null), isEmpty);
    });
  });

  group('audit isAccessDenied', () {
    test('body 403 and HTTP 403 are access denied', () {
      expect(
        isAccessDenied(ServerFailure(message: 'no', statusCode: 403)),
        isTrue,
      );
      expect(
        isAccessDenied(const AuthenticationFailure(message: 'Access denied')),
        isTrue,
      );
    });

    test('other failures are real errors', () {
      expect(
        isAccessDenied(ServerFailure(message: 'boom', statusCode: 500)),
        isFalse,
      );
      expect(isAccessDenied(const NoConnectionFailure()), isFalse);
      expect(isAccessDenied(null), isFalse);
    });
  });
}
