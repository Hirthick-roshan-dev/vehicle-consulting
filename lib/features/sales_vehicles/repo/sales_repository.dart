import '../../../core/database/app_database.dart';
import '../../../core/database/database_constants.dart';
import '../model/payment_method.dart';
import '../model/payment_model.dart';
import '../model/sale_model.dart';
import '../model/vehicle_status.dart';

class SalesRepositoryException implements Exception {
  final String message;
  SalesRepositoryException(this.message);

  @override
  String toString() => message;
}

class SalesRepository {
  final AppDatabase _appDatabase;

  SalesRepository(this._appDatabase);

  Future<VehicleSaleModel?> getSaleByVehicleId(int vehicleId) async {
    try {
      final db = await _appDatabase.database;
      final results = await db.query(
        DatabaseConstants.tableSales,
        where: 'vehicle_id = ?',
        whereArgs: [vehicleId],
      );
      if (results.isEmpty) return null;
      return VehicleSaleModel.fromMap(results.first);
    } catch (e) {
      throw SalesRepositoryException('Failed to load sale information.');
    }
  }

  Future<List<VehiclePaymentModel>> getPaymentsByVehicleId(int vehicleId) async {
    try {
      final db = await _appDatabase.database;
      final results = await db.query(
        DatabaseConstants.tablePayments,
        where: 'vehicle_id = ?',
        whereArgs: [vehicleId],
        orderBy: 'payment_date DESC',
      );
      return results.map((map) => VehiclePaymentModel.fromMap(map)).toList();
    } catch (e) {
      throw SalesRepositoryException('Failed to load payment history.');
    }
  }

  /// Records a new sale along with an optional initial advance payment inside an atomic transaction.
  Future<void> recordSale({
    required VehicleSaleModel sale,
    required double advanceAmount,
    required PaymentMethod paymentMethod,
  }) async {
    try {
      final db = await _appDatabase.database;
      await db.transaction((txn) async {
        // 1. Insert sale record
        final saleId = await txn.insert(
          DatabaseConstants.tableSales,
          sale.toMap(),
        );

        // 2. Insert advance payment if > 0
        if (advanceAmount > 0) {
          final now = DateTime.now().toIso8601String();
          final payment = VehiclePaymentModel(
            vehicleId: sale.vehicleId,
            saleId: saleId,
            amount: advanceAmount,
            paymentDate: sale.saleDate,
            paymentMethod: paymentMethod,
            notes: 'Advance Payment',
            createdAt: now,
          );
          await txn.insert(
            DatabaseConstants.tablePayments,
            payment.toMap(),
          );
        }

        // 3. Update vehicle status
        final balance = sale.totalAmount - advanceAmount;
        final newStatus = balance <= 0
            ? VehicleStatus.completed.code
            : VehicleStatus.partialPayment.code;

        await txn.update(
          DatabaseConstants.tableVehicles,
          {
            'status': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [sale.vehicleId],
        );
      });
    } catch (e) {
      throw SalesRepositoryException('Failed to complete vehicle sale: ${e.toString()}');
    }
  }

  /// Updates existing sale information and synchronizes vehicle completion status based on total paid vs updated sale amount.
  Future<void> updateSale({
    required VehicleSaleModel sale,
  }) async {
    if (sale.id == null) {
      throw SalesRepositoryException('Cannot update sale record without ID.');
    }
    try {
      final db = await _appDatabase.database;
      await db.transaction((txn) async {
        // 1. Update sale record
        await txn.update(
          DatabaseConstants.tableSales,
          sale.toMap(),
          where: 'id = ?',
          whereArgs: [sale.id],
        );

        // 2. Query total payments
        final paymentsResult = await txn.query(
          DatabaseConstants.tablePayments,
          columns: ['amount'],
          where: 'vehicle_id = ?',
          whereArgs: [sale.vehicleId],
        );

        double totalPaid = 0.0;
        for (var row in paymentsResult) {
          totalPaid += (row['amount'] as num).toDouble();
        }

        // 3. Update vehicle status based on updated totalAmount
        final newStatus = totalPaid >= sale.totalAmount
            ? VehicleStatus.completed.code
            : VehicleStatus.partialPayment.code;

        await txn.update(
          DatabaseConstants.tableVehicles,
          {
            'status': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [sale.vehicleId],
        );
      });
    } catch (e) {
      throw SalesRepositoryException('Failed to update sale information: ${e.toString()}');
    }
  }

  /// Deletes sales and payment records for a vehicle, restoring the vehicle status back to FOR SALE (available).
  Future<void> deleteSale({required int vehicleId}) async {
    try {
      final db = await _appDatabase.database;
      await db.transaction((txn) async {
        // 1. Delete associated payments
        await txn.delete(
          DatabaseConstants.tablePayments,
          where: 'vehicle_id = ?',
          whereArgs: [vehicleId],
        );

        // 2. Delete sale record
        await txn.delete(
          DatabaseConstants.tableSales,
          where: 'vehicle_id = ?',
          whereArgs: [vehicleId],
        );

        // 3. Update vehicle status back to FOR SALE (available)
        await txn.update(
          DatabaseConstants.tableVehicles,
          {
            'status': VehicleStatus.available.code,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [vehicleId],
        );
      });
    } catch (e) {
      throw SalesRepositoryException('Failed to delete sale information: ${e.toString()}');
    }
  }

  /// Adds a new payment record for a vehicle sale inside an atomic transaction, updating vehicle status if fully paid.
  Future<void> addPayment({
    required VehiclePaymentModel payment,
    required double totalSaleAmount,
  }) async {
    try {
      final db = await _appDatabase.database;
      await db.transaction((txn) async {
        // 1. Insert payment record
        await txn.insert(
          DatabaseConstants.tablePayments,
          payment.toMap(),
        );

        // 2. Calculate total payments so far
        final paymentsResult = await txn.query(
          DatabaseConstants.tablePayments,
          columns: ['amount'],
          where: 'vehicle_id = ?',
          whereArgs: [payment.vehicleId],
        );

        double totalPaid = 0.0;
        for (var row in paymentsResult) {
          totalPaid += (row['amount'] as num).toDouble();
        }

        // 3. Determine status: if totalPaid >= totalSaleAmount -> completed, else partialPayment
        final newStatus = totalPaid >= totalSaleAmount
            ? VehicleStatus.completed.code
            : VehicleStatus.partialPayment.code;

        await txn.update(
          DatabaseConstants.tableVehicles,
          {
            'status': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [payment.vehicleId],
        );
      });
    } catch (e) {
      throw SalesRepositoryException('Failed to record payment: ${e.toString()}');
    }
  }
}
