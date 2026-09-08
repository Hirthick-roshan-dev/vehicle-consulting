import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:vehicle_consulting/core/services/sample_data_service.dart';
import 'package:vehicle_consulting/features/sales_vehicles/model/payment_method.dart';
import 'package:vehicle_consulting/features/sales_vehicles/model/vehicle_status.dart';
import 'package:vehicle_consulting/features/sales_vehicles/model/vehicle_type.dart';

void main() {
  group('Sample Data & Asset Validation Tests', () {
    late Map<String, dynamic> sampleDataJson;
    late List<dynamic> vehicles;

    setUpAll(() {
      final file = File('assets/sample_vehicles.json');
      expect(file.existsSync(), isTrue, reason: 'assets/sample_vehicles.json must exist');
      final content = file.readAsStringSync();
      sampleDataJson = json.decode(content) as Map<String, dynamic>;
      vehicles = sampleDataJson['sample_vehicles'] as List<dynamic>;
    });

    test('sample_vehicles.json contains exactly 16 vehicles', () {
      expect(vehicles.length, 16);
    });

    test('sample vehicles cover FOR SALE, PARTIAL PAYMENT, and COMPLETED statuses', () {
      final statuses = vehicles.map((v) => v['status'] as String).toSet();
      expect(statuses.contains(VehicleStatus.available.code), isTrue);
      expect(statuses.contains(VehicleStatus.partialPayment.code), isTrue);
      expect(statuses.contains(VehicleStatus.completed.code), isTrue);

      final forSaleCount = vehicles.where((v) => v['status'] == VehicleStatus.available.code).length;
      final partialCount = vehicles.where((v) => v['status'] == VehicleStatus.partialPayment.code).length;
      final completedCount = vehicles.where((v) => v['status'] == VehicleStatus.completed.code).length;

      expect(forSaleCount, 7);
      expect(partialCount, 4);
      expect(completedCount, 5);
    });

    test('sample vehicles include both TWO_WHEELER and FOUR_WHEELER types', () {
      final types = vehicles.map((v) => v['vehicle_type'] as String).toSet();
      expect(types.contains(VehicleType.twoWheeler.code), isTrue);
      expect(types.contains(VehicleType.fourWheeler.code), isTrue);
    });

    test('each sample vehicle has all required fields and valid enums', () {
      for (final v in vehicles) {
        final vehicleMap = v as Map<String, dynamic>;
        expect(vehicleMap['vehicle_number'], startsWith(SampleDataService.sampleVehiclePrefix));
        expect(vehicleMap['vehicle_name'], isNotEmpty);
        expect(vehicleMap['vehicle_model'], isNotEmpty);
        expect((vehicleMap['purchase_amount'] as num), greaterThan(0));
        expect(vehicleMap['manufacturing_year'], greaterThan(2000));
        expect(vehicleMap['registration_year'], greaterThan(2000));

        // Validate payment method
        expect(
          PaymentMethod.fromString(vehicleMap['payment_method'] as String),
          isA<PaymentMethod>(),
        );

        // Validate vehicle type enum string
        expect(
          VehicleType.values.any((t) => t.code == vehicleMap['vehicle_type']),
          isTrue,
        );

        // Validate vehicle status enum string
        expect(
          VehicleStatus.values.any((s) => s.code == vehicleMap['status']),
          isTrue,
        );
      }
    });

    test('partially paid and completed vehicles have valid sales and payment records', () {
      final soldVehicles = vehicles.where(
        (v) =>
            v['status'] == VehicleStatus.partialPayment.code ||
            v['status'] == VehicleStatus.completed.code,
      );

      for (final v in soldVehicles) {
        final sale = v['sale'] as Map<String, dynamic>?;
        expect(sale, isNotNull);
        expect(sale!['customer_name'], isNotEmpty);
        expect(sale['customer_phone'], isNotEmpty);
        expect((sale['total_amount'] as num), greaterThan(0));
        expect((sale['document_charges'] as num), greaterThanOrEqualTo(0));

        final payments = v['payments'] as List<dynamic>?;
        expect(payments, isNotNull);
        expect(payments!, isNotEmpty);

        final totalPaid = payments.fold<double>(
          0.0,
          (sum, p) => sum + (p['amount'] as num).toDouble(),
        );

        if (v['status'] == VehicleStatus.completed.code) {
          // Fully paid
          expect(totalPaid, equals((sale['total_amount'] as num).toDouble()));
        } else if (v['status'] == VehicleStatus.partialPayment.code) {
          // Partially paid: paid < total
          expect(totalPaid, lessThan((sale['total_amount'] as num).toDouble()));
          expect(totalPaid, greaterThan(0));
        }
      }
    });

    test('all referenced image_asset files exist in assets/sample_vehicles/', () {
      for (final v in vehicles) {
        final assetPath = v['image_asset'] as String?;
        expect(assetPath, isNotNull);
        final file = File(assetPath!);
        expect(
          file.existsSync(),
          isTrue,
          reason: 'Asset image file $assetPath should exist on disk',
        );
        expect(file.lengthSync(), greaterThan(1000));
      }
    });
  });
}
