import '../../../core/database/app_database.dart';
import '../../../core/database/database_constants.dart';
import '../../../core/services/image_storage_service.dart';
import '../model/vehicle_model.dart';
import '../model/vehicle_status.dart';
import '../model/vehicle_type.dart';

class VehicleRepositoryException implements Exception {
  final String message;
  VehicleRepositoryException(this.message);

  @override
  String toString() => message;
}

class VehicleRepository {
  final AppDatabase _appDatabase;

  VehicleRepository(this._appDatabase);

  Future<List<VehicleModel>> getVehicles({
    VehicleStatus? filterStatus,
    VehicleType? filterType,
    String? searchQuery,
    bool isCompletedOnly = false,
    int? limit,
    int? offset,
  }) async {
    try {
      final db = await _appDatabase.database;
      final List<String> whereClauses = [];
      final List<dynamic> whereArgs = [];

      if (isCompletedOnly) {
        if (filterStatus != null) {
          whereClauses.add('status = ?');
          whereArgs.add(filterStatus.code);
        } else {
          whereClauses.add('status IN (?, ?)');
          whereArgs.add(VehicleStatus.completed.code);
          whereArgs.add(VehicleStatus.partialPayment.code);
        }
      } else if (filterStatus != null) {
        whereClauses.add('status = ?');
        whereArgs.add(filterStatus.code);
      } else {
        // Sales catalog view: show available inventory only
        whereClauses.add('status = ?');
        whereArgs.add(VehicleStatus.available.code);
      }

      if (filterType != null) {
        whereClauses.add('vehicle_type = ?');
        whereArgs.add(filterType.code);
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final query = '%${searchQuery.trim().toLowerCase()}%';
        whereClauses.add('''
          (LOWER(vehicle_number) LIKE ? OR 
           LOWER(vehicle_name) LIKE ? OR 
           LOWER(vehicle_model) LIKE ? OR 
           LOWER(owner_name) LIKE ?)
        ''');
        whereArgs.addAll([query, query, query, query]);
      }

      final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

      final results = await db.query(
        DatabaseConstants.tableVehicles,
        where: whereString,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: 'created_at DESC',
        limit: limit,
        offset: offset,
      );

      return results.map((map) => VehicleModel.fromMap(map)).toList();
    } catch (e) {
      throw VehicleRepositoryException('Failed to load vehicles from database: ${e.toString()}');
    }
  }

  Future<int> getVehiclesCount({
    VehicleStatus? filterStatus,
    VehicleType? filterType,
    String? searchQuery,
    bool isCompletedOnly = false,
  }) async {
    try {
      final db = await _appDatabase.database;
      final List<String> whereClauses = [];
      final List<dynamic> whereArgs = [];

      if (isCompletedOnly) {
        if (filterStatus != null) {
          whereClauses.add('status = ?');
          whereArgs.add(filterStatus.code);
        } else {
          whereClauses.add('status IN (?, ?)');
          whereArgs.add(VehicleStatus.completed.code);
          whereArgs.add(VehicleStatus.partialPayment.code);
        }
      } else if (filterStatus != null) {
        whereClauses.add('status = ?');
        whereArgs.add(filterStatus.code);
      } else {
        whereClauses.add('status = ?');
        whereArgs.add(VehicleStatus.available.code);
      }

      if (filterType != null) {
        whereClauses.add('vehicle_type = ?');
        whereArgs.add(filterType.code);
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final query = '%${searchQuery.trim().toLowerCase()}%';
        whereClauses.add('''
          (LOWER(vehicle_number) LIKE ? OR 
           LOWER(vehicle_name) LIKE ? OR 
           LOWER(vehicle_model) LIKE ? OR 
           LOWER(owner_name) LIKE ?)
        ''');
        whereArgs.addAll([query, query, query, query]);
      }

      final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

      final countResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${DatabaseConstants.tableVehicles}${whereString != null ? ' WHERE $whereString' : ''}',
        whereArgs.isNotEmpty ? whereArgs : null,
      );

      return (countResult.first['count'] as num).toInt();
    } catch (e) {
      return 0;
    }
  }

  Future<VehicleModel?> getVehicleById(int id) async {
    try {
      final db = await _appDatabase.database;
      final results = await db.query(
        DatabaseConstants.tableVehicles,
        where: 'id = ?',
        whereArgs: [id],
      );
      if (results.isEmpty) return null;
      return VehicleModel.fromMap(results.first);
    } catch (e) {
      throw VehicleRepositoryException('Failed to find vehicle details.');
    }
  }

  Future<int> addVehicle(VehicleModel vehicle) async {
    try {
      final db = await _appDatabase.database;
      // Check for duplicate vehicle number
      final existing = await db.query(
        DatabaseConstants.tableVehicles,
        where: 'LOWER(vehicle_number) = LOWER(?)',
        whereArgs: [vehicle.vehicleNumber.trim()],
      );

      if (existing.isNotEmpty) {
        throw VehicleRepositoryException(
          'Vehicle with number "${vehicle.vehicleNumber}" already exists.',
        );
      }

      return await db.insert(
        DatabaseConstants.tableVehicles,
        vehicle.toMap(),
      );
    } catch (e) {
      if (e is VehicleRepositoryException) rethrow;
      throw VehicleRepositoryException('Failed to add vehicle: ${e.toString()}');
    }
  }

  Future<void> updateVehicle(VehicleModel vehicle) async {
    if (vehicle.id == null) {
      throw VehicleRepositoryException('Cannot update vehicle without an ID.');
    }
    try {
      final db = await _appDatabase.database;
      // Check for duplicate vehicle number with different ID
      final existing = await db.query(
        DatabaseConstants.tableVehicles,
        where: 'LOWER(vehicle_number) = LOWER(?) AND id != ?',
        whereArgs: [vehicle.vehicleNumber.trim(), vehicle.id],
      );

      if (existing.isNotEmpty) {
        throw VehicleRepositoryException(
          'Another vehicle with number "${vehicle.vehicleNumber}" already exists.',
        );
      }

      final count = await db.update(
        DatabaseConstants.tableVehicles,
        vehicle.toMap(),
        where: 'id = ?',
        whereArgs: [vehicle.id],
      );

      if (count == 0) {
        throw VehicleRepositoryException('Vehicle record not found.');
      }
    } catch (e) {
      if (e is VehicleRepositoryException) rethrow;
      throw VehicleRepositoryException('Failed to update vehicle.');
    }
  }

  Future<void> deleteVehicle(int vehicleId) async {
    try {
      final db = await _appDatabase.database;
      // 1. Query image path before deleting
      final vehicle = await getVehicleById(vehicleId);

      // 2. Transactional delete across related tables
      await db.transaction((txn) async {
        await txn.delete(
          DatabaseConstants.tablePayments,
          where: 'vehicle_id = ?',
          whereArgs: [vehicleId],
        );
        await txn.delete(
          DatabaseConstants.tableSales,
          where: 'vehicle_id = ?',
          whereArgs: [vehicleId],
        );
        await txn.delete(
          DatabaseConstants.tableExpenses,
          where: 'vehicle_id = ?',
          whereArgs: [vehicleId],
        );
        await txn.delete(
          DatabaseConstants.tableVehicles,
          where: 'id = ?',
          whereArgs: [vehicleId],
        );
      });

      // 3. Delete stored photo if present
      if (vehicle?.imagePath != null) {
        await ImageStorageService.deleteVehicleImage(vehicle!.imagePath);
      }
    } catch (e) {
      throw VehicleRepositoryException('Failed to delete vehicle and its associated records.');
    }
  }
}
