import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../database/app_database.dart';
import '../database/database_constants.dart';
import 'image_storage_service.dart';

class SampleDataService {
  static const String prefSampleDataLoaded = 'is_sample_data_loaded';
  static const String sampleVehiclePrefix = 'TN38DEMO';

  final AppDatabase _appDatabase;

  SampleDataService([AppDatabase? appDatabase])
      : _appDatabase = appDatabase ?? AppDatabase();

  /// Checks if sample data is currently loaded in the database.
  Future<bool> isSampleDataLoaded() async {
    final prefs = await SharedPreferences.getInstance();
    final prefVal = prefs.getBool(prefSampleDataLoaded) ?? false;
    
    // Also verify whether any demo vehicles actually exist in SQLite
    final db = await _appDatabase.database;
    final countRes = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseConstants.tableVehicles} WHERE vehicle_number LIKE ?',
      ['$sampleVehiclePrefix%'],
    );
    final count = (countRes.first['count'] as int?) ?? 0;

    final isActuallyLoaded = count > 0;
    if (prefVal != isActuallyLoaded) {
      await prefs.setBool(prefSampleDataLoaded, isActuallyLoaded);
    }
    return isActuallyLoaded;
  }

  /// Loads sample data from assets/sample_vehicles.json into SQLite.
  /// Copies asset photos to local app image storage.
  Future<int> loadSampleData() async {
    // If already loaded, remove first to prevent duplicates
    await removeSampleData();

    final jsonString = await rootBundle.loadString('assets/sample_vehicles.json');
    final Map<String, dynamic> data = json.decode(jsonString);
    final List<dynamic> vehicles = data['sample_vehicles'] as List<dynamic>? ?? [];

    final db = await _appDatabase.database;
    final imagesDir = await ImageStorageService.getImagesDirectory();
    final now = DateTime.now().toIso8601String();

    int insertedVehiclesCount = 0;

    await db.transaction((txn) async {
      for (final v in vehicles) {
        final vehicleMap = v as Map<String, dynamic>;
        final vehicleNumber = vehicleMap['vehicle_number'] as String;
        final imageAsset = vehicleMap['image_asset'] as String?;

        String? localImagePath;
        if (imageAsset != null && imageAsset.isNotEmpty) {
          try {
            final byteData = await rootBundle.load(imageAsset);
            final ext = p.extension(imageAsset).toLowerCase();
            final targetFileName = 'sample_${vehicleNumber.toLowerCase()}$ext';
            final targetFile = File(p.join(imagesDir, targetFileName));
            
            final buffer = byteData.buffer;
            await targetFile.writeAsBytes(
              buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
              flush: true,
            );
            localImagePath = targetFile.path;
          } catch (_) {
            // If asset image reading fails, proceed without photo
            localImagePath = null;
          }
        }

        // Insert vehicle record
        final vehicleId = await txn.insert(DatabaseConstants.tableVehicles, {
          'vehicle_number': vehicleNumber,
          'vehicle_name': vehicleMap['vehicle_name'],
          'vehicle_model': vehicleMap['vehicle_model'],
          'vehicle_type': vehicleMap['vehicle_type'],
          'owner_name': vehicleMap['owner_name'],
          'owner_phone': vehicleMap['owner_phone'],
          'manufacturing_year': vehicleMap['manufacturing_year'],
          'registration_year': vehicleMap['registration_year'],
          'purchase_date': vehicleMap['purchase_date'],
          'purchase_amount': (vehicleMap['purchase_amount'] as num).toDouble(),
          'payment_method': vehicleMap['payment_method'],
          'reference_name': vehicleMap['reference_name'],
          'commission_amount': (vehicleMap['commission_amount'] as num?)?.toDouble() ?? 0.0,
          'sale_price': 0.0,
          'status': vehicleMap['status'],
          'notes': vehicleMap['notes'],
          'image_path': localImagePath,
          'created_at': now,
          'updated_at': now,
        });

        insertedVehiclesCount++;

        // Insert expenses
        final expenses = vehicleMap['expenses'] as List<dynamic>? ?? [];
        for (final exp in expenses) {
          final expMap = exp as Map<String, dynamic>;
          await txn.insert(DatabaseConstants.tableExpenses, {
            'vehicle_id': vehicleId,
            'expense_title': expMap['expense_title'],
            'description': expMap['description'],
            'amount': (expMap['amount'] as num).toDouble(),
            'expense_date': expMap['expense_date'],
            'created_at': now,
            'updated_at': now,
          });
        }

        // Insert sale and payments if applicable
        final sale = vehicleMap['sale'] as Map<String, dynamic>?;
        if (sale != null) {
          final saleId = await txn.insert(DatabaseConstants.tableSales, {
            'vehicle_id': vehicleId,
            'customer_name': sale['customer_name'],
            'customer_phone': sale['customer_phone'],
            'sale_date': sale['sale_date'],
            'payment_type': sale['payment_type'],
            'is_emi': (sale['is_emi'] as int?) ?? 0,
            'finance_name': sale['finance_name'],
            'total_amount': (sale['total_amount'] as num).toDouble(),
            'document_charges': (sale['document_charges'] as num?)?.toDouble() ?? 0.0,
            'notes': sale['notes'],
            'created_at': now,
            'updated_at': now,
          });

          final payments = vehicleMap['payments'] as List<dynamic>? ?? [];
          for (final pay in payments) {
            final payMap = pay as Map<String, dynamic>;
            await txn.insert(DatabaseConstants.tablePayments, {
              'vehicle_id': vehicleId,
              'sale_id': saleId,
              'amount': (payMap['amount'] as num).toDouble(),
              'payment_date': payMap['payment_date'],
              'payment_method': payMap['payment_method'],
              'notes': payMap['notes'],
              'created_at': now,
            });
          }
        }
      }
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefSampleDataLoaded, true);

    return insertedVehiclesCount;
  }

  /// Removes only sample data (identified by TN38DEMO prefix) from SQLite.
  /// Also deletes local sample image files.
  Future<int> removeSampleData() async {
    final db = await _appDatabase.database;

    // Find all demo vehicles
    final sampleVehicles = await db.query(
      DatabaseConstants.tableVehicles,
      columns: ['id', 'image_path'],
      where: 'vehicle_number LIKE ?',
      whereArgs: ['$sampleVehiclePrefix%'],
    );

    if (sampleVehicles.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefSampleDataLoaded, false);
      return 0;
    }

    final vehicleIds = sampleVehicles.map((v) => v['id'] as int).toList();

    // Delete image files for sample vehicles
    for (final v in sampleVehicles) {
      final imgPath = v['image_path'] as String?;
      if (imgPath != null) {
        await ImageStorageService.deleteVehicleImage(imgPath);
      }
    }

    // Atomic removal of related tables
    final idPlaceholders = List.filled(vehicleIds.length, '?').join(',');
    await db.transaction((txn) async {
      await txn.delete(
        DatabaseConstants.tablePayments,
        where: 'vehicle_id IN ($idPlaceholders)',
        whereArgs: vehicleIds,
      );
      await txn.delete(
        DatabaseConstants.tableSales,
        where: 'vehicle_id IN ($idPlaceholders)',
        whereArgs: vehicleIds,
      );
      await txn.delete(
        DatabaseConstants.tableExpenses,
        where: 'vehicle_id IN ($idPlaceholders)',
        whereArgs: vehicleIds,
      );
      await txn.delete(
        DatabaseConstants.tableVehicles,
        where: 'id IN ($idPlaceholders)',
        whereArgs: vehicleIds,
      );
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefSampleDataLoaded, false);

    return vehicleIds.length;
  }
}
