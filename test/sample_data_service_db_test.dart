import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vehicle_consulting/core/database/app_database.dart';
import 'package:vehicle_consulting/core/database/database_constants.dart';
import 'package:vehicle_consulting/core/services/sample_data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});

    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return Directory.systemTemp.path;
    });
  });

  group('SampleDataService Database Operations', () {
    test('loads and removes sample data in SQLite database correctly', () async {
      final appDb = AppDatabase();
      final db = await appDb.database;

      final service = SampleDataService(appDb);

      // Initially, sample data should not be loaded
      final initialLoaded = await service.isSampleDataLoaded();
      expect(initialLoaded, isFalse);

      // Load sample data
      final insertedCount = await service.loadSampleData();
      expect(insertedCount, 16);

      // Verify loaded status
      final isLoadedNow = await service.isSampleDataLoaded();
      expect(isLoadedNow, isTrue);

      // Verify vehicles in database
      final vehicles = await db.query(
        DatabaseConstants.tableVehicles,
        where: 'vehicle_number LIKE ?',
        whereArgs: ['${SampleDataService.sampleVehiclePrefix}%'],
      );
      expect(vehicles.length, 16);

      // Verify expenses inserted
      final expenses = await db.query(DatabaseConstants.tableExpenses);
      expect(expenses, isNotEmpty);

      // Verify sales inserted for partially paid & completed vehicles
      final sales = await db.query(DatabaseConstants.tableSales);
      expect(sales.length, 9); // 4 partial + 5 completed

      // Verify payments inserted
      final payments = await db.query(DatabaseConstants.tablePayments);
      expect(payments.length, greaterThanOrEqualTo(9));

      // Remove sample data
      final removedCount = await service.removeSampleData();
      expect(removedCount, 16);

      // Verify sample vehicles removed
      final remainingSampleVehicles = await db.query(
        DatabaseConstants.tableVehicles,
        where: 'vehicle_number LIKE ?',
        whereArgs: ['${SampleDataService.sampleVehiclePrefix}%'],
      );
      expect(remainingSampleVehicles.length, 0);

      // Verify status is now false
      final isLoadedAfterRemoval = await service.isSampleDataLoaded();
      expect(isLoadedAfterRemoval, isFalse);
    });
  });
}
