import '../../../core/database/app_database.dart';
import '../../../core/database/database_constants.dart';
import '../../sales_vehicles/model/expense_model.dart';
import '../../sales_vehicles/model/payment_model.dart';
import '../../sales_vehicles/model/sale_model.dart';
import '../../sales_vehicles/model/vehicle_model.dart';
import '../../sales_vehicles/model/vehicle_status.dart';
import '../../sales_vehicles/model/vehicle_type.dart';
import '../model/report_models.dart';

class ReportRepository {
  final AppDatabase _appDatabase;

  ReportRepository(this._appDatabase);

  /// Fetches all vehicles currently available in stock ('FOR SALE') with their expenses.
  Future<List<StockReportItem>> getStockItems({VehicleType? filterType}) async {
    final db = await _appDatabase.database;
    final List<String> where = ['status = ?'];
    final List<dynamic> args = [VehicleStatus.available.code];

    if (filterType != null) {
      where.add('vehicle_type = ?');
      args.add(filterType.code);
    }

    final vehicleRows = await db.query(
      DatabaseConstants.tableVehicles,
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'purchase_date DESC',
    );

    final List<StockReportItem> items = [];

    for (final row in vehicleRows) {
      final vehicle = VehicleModel.fromMap(row);
      if (vehicle.id != null) {
        final expenseRows = await db.query(
          DatabaseConstants.tableExpenses,
          where: 'vehicle_id = ?',
          whereArgs: [vehicle.id],
        );
        final expenses = expenseRows.map((e) => VehicleExpenseModel.fromMap(e)).toList();
        items.add(StockReportItem(vehicle: vehicle, expenses: expenses));
      }
    }

    return items;
  }

  /// Fetches sales items for completed and partial payment vehicles within optional date range.
  Future<List<SalesReportItem>> getSalesItems({
    DateTime? startDate,
    DateTime? endDate,
    VehicleType? filterType,
  }) async {
    final db = await _appDatabase.database;

    final List<String> vehicleWhere = ['status IN (?, ?)'];
    final List<dynamic> vehicleArgs = [
      VehicleStatus.completed.code,
      VehicleStatus.partialPayment.code,
    ];

    if (filterType != null) {
      vehicleWhere.add('vehicle_type = ?');
      vehicleArgs.add(filterType.code);
    }

    final vehicleRows = await db.query(
      DatabaseConstants.tableVehicles,
      where: vehicleWhere.join(' AND '),
      whereArgs: vehicleArgs,
    );

    final List<SalesReportItem> items = [];

    // Normalize comparison dates
    final startComparable = startDate != null
        ? DateTime(startDate.year, startDate.month, startDate.day)
        : null;
    final endComparable = endDate != null
        ? DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59)
        : null;

    for (final vRow in vehicleRows) {
      final vehicle = VehicleModel.fromMap(vRow);
      if (vehicle.id == null) continue;

      final saleRows = await db.query(
        DatabaseConstants.tableSales,
        where: 'vehicle_id = ?',
        whereArgs: [vehicle.id],
      );

      if (saleRows.isEmpty) continue;
      final sale = VehicleSaleModel.fromMap(saleRows.first);

      final saleDate = DateTime.tryParse(sale.saleDate);
      if (saleDate != null) {
        if (startComparable != null && saleDate.isBefore(startComparable)) {
          continue;
        }
        if (endComparable != null && saleDate.isAfter(endComparable)) {
          continue;
        }
      }

      final expenseRows = await db.query(
        DatabaseConstants.tableExpenses,
        where: 'vehicle_id = ?',
        whereArgs: [vehicle.id],
      );
      final expenses = expenseRows.map((e) => VehicleExpenseModel.fromMap(e)).toList();

      final paymentRows = await db.query(
        DatabaseConstants.tablePayments,
        where: 'vehicle_id = ?',
        whereArgs: [vehicle.id],
        orderBy: 'payment_date DESC',
      );
      final payments = paymentRows.map((p) => VehiclePaymentModel.fromMap(p)).toList();

      items.add(
        SalesReportItem(
          vehicle: vehicle,
          sale: sale,
          payments: payments,
          expenses: expenses,
        ),
      );
    }

    // Sort by sale date descending (most recent first)
    items.sort((a, b) => b.saleDate.compareTo(a.saleDate));
    return items;
  }

  /// Convenience method for calculating weekly profit summary for current calendar week
  Future<ProfitSummary> getWeeklyProfitSummary({VehicleType? filterType}) async {
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final endOfWeek = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day + 6, 23, 59, 59);

    final items = await getSalesItems(
      startDate: startOfWeek,
      endDate: endOfWeek,
      filterType: filterType,
    );
    return ProfitSummary.fromItems(items);
  }

  /// Convenience method for calculating monthly profit summary for current calendar month
  Future<ProfitSummary> getMonthlyProfitSummary({VehicleType? filterType}) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final items = await getSalesItems(
      startDate: startOfMonth,
      endDate: endOfMonth,
      filterType: filterType,
    );
    return ProfitSummary.fromItems(items);
  }

  /// Convenience method for calculating total all-time profit summary
  Future<ProfitSummary> getOverallProfitSummary({VehicleType? filterType}) async {
    final items = await getSalesItems(filterType: filterType);
    return ProfitSummary.fromItems(items);
  }
}
