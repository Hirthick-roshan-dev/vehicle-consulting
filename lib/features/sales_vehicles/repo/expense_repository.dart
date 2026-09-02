import '../../../core/database/app_database.dart';
import '../../../core/database/database_constants.dart';
import '../model/expense_model.dart';

class ExpenseRepositoryException implements Exception {
  final String message;
  ExpenseRepositoryException(this.message);

  @override
  String toString() => message;
}

class ExpenseRepository {
  final AppDatabase _appDatabase;

  ExpenseRepository(this._appDatabase);

  Future<List<VehicleExpenseModel>> getExpensesByVehicleId(int vehicleId) async {
    try {
      final db = await _appDatabase.database;
      final results = await db.query(
        DatabaseConstants.tableExpenses,
        where: 'vehicle_id = ?',
        whereArgs: [vehicleId],
        orderBy: 'expense_date DESC',
      );
      return results.map((map) => VehicleExpenseModel.fromMap(map)).toList();
    } catch (e) {
      throw ExpenseRepositoryException('Failed to load expenses for vehicle.');
    }
  }

  Future<int> addExpense(VehicleExpenseModel expense) async {
    try {
      final db = await _appDatabase.database;
      return await db.insert(
        DatabaseConstants.tableExpenses,
        expense.toMap(),
      );
    } catch (e) {
      throw ExpenseRepositoryException('Failed to add expense record.');
    }
  }

  Future<void> updateExpense(VehicleExpenseModel expense) async {
    if (expense.id == null) {
      throw ExpenseRepositoryException('Cannot update expense without ID.');
    }
    try {
      final db = await _appDatabase.database;
      final count = await db.update(
        DatabaseConstants.tableExpenses,
        expense.toMap(),
        where: 'id = ?',
        whereArgs: [expense.id],
      );
      if (count == 0) {
        throw ExpenseRepositoryException('Expense record not found.');
      }
    } catch (e) {
      if (e is ExpenseRepositoryException) rethrow;
      throw ExpenseRepositoryException('Failed to update expense record.');
    }
  }

  Future<void> deleteExpense(int expenseId) async {
    try {
      final db = await _appDatabase.database;
      await db.delete(
        DatabaseConstants.tableExpenses,
        where: 'id = ?',
        whereArgs: [expenseId],
      );
    } catch (e) {
      throw ExpenseRepositoryException('Failed to delete expense record.');
    }
  }
}
