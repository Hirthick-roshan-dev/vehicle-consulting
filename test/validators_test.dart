import 'package:flutter_test/flutter_test.dart';
import 'package:vehicle_consulting/core/utils/validators.dart';

void main() {
  group('Validators Tests', () {
    test('vehicleNumber validates invalid and valid numbers', () {
      expect(Validators.vehicleNumber(''), isNotNull);
      expect(Validators.vehicleNumber('TN'), isNotNull);
      expect(Validators.vehicleNumber('TN-39-AB-1234'), isNull);
    });

    test('positiveAmount validates numeric values', () {
      expect(Validators.positiveAmount('-50'), isNotNull);
      expect(Validators.positiveAmount('abc'), isNotNull);
      expect(Validators.positiveAmount('500'), isNull);
    });

    test('phoneNumber validates 10-digit mobile numbers', () {
      expect(Validators.phoneNumber(''), isNotNull);
      expect(Validators.phoneNumber('12345'), isNotNull);
      expect(Validators.phoneNumber('9841012345'), isNull);
      expect(Validators.phoneNumber('+91 9841012345'), isNull);
    });

    test('formatIndianPhone formats numbers with +91', () {
      expect(Validators.formatIndianPhone('9841012345'), equals('+91 9841012345'));
      expect(Validators.formatIndianPhone('+919841012345'), equals('+91 9841012345'));
      expect(Validators.extract10Digits('+91 9841012345'), equals('9841012345'));
    });

    test('validatePayment prevents advance > total sale', () {
      final err = Validators.validatePayment(advancePaid: 600000, totalSaleAmount: 500000);
      expect(err, contains('cannot exceed total sale amount'));
    });
  });
}
