import 'package:flutter_test/flutter_test.dart';
import 'package:evergreen/features/amcs/domain/models/amc_contract.dart';

AmcContract contractEndingIn(int days) {
  final now = DateTime.now();
  return AmcContract(
    id: 'x',
    companyName: 'Co',
    branchName: 'B',
    pocName: 'P',
    mobile: '1',
    email: 'e',
    startDate: now.subtract(const Duration(days: 300)),
    endDate: DateTime(now.year, now.month, now.day).add(Duration(days: days)),
  );
}

void main() {
  group('AMC status derivation', () {
    test('active when > 30 days to expiry', () {
      expect(contractEndingIn(200).status(), AmcStatus.active);
    });

    test('expiring soon within the 30-day window', () {
      expect(contractEndingIn(30).status(), AmcStatus.expiringSoon);
      expect(contractEndingIn(1).status(), AmcStatus.expiringSoon);
    });

    test('expired when end date is in the past', () {
      expect(contractEndingIn(-1).status(), AmcStatus.expired);
      expect(contractEndingIn(-100).status(), AmcStatus.expired);
    });

    test('boundary: exactly 31 days is still active', () {
      expect(contractEndingIn(31).status(), AmcStatus.active);
    });

    test('daysUntilExpiry is accurate', () {
      expect(contractEndingIn(10).daysUntilExpiry(), 10);
      expect(contractEndingIn(-5).daysUntilExpiry(), -5);
    });
  });

  group('AMC JSON', () {
    test('round-trips all fields', () {
      final c = contractEndingIn(45);
      final restored = AmcContract.fromJson(c.toJson());
      expect(restored.companyName, c.companyName);
      expect(restored.endDate, c.endDate);
      expect(restored.status(), c.status());
    });
  });

  group('AmcStatus key', () {
    test('round-trips', () {
      for (final s in AmcStatus.values) {
        expect(AmcStatusX.fromKey(s.key), s);
      }
    });
  });
}
