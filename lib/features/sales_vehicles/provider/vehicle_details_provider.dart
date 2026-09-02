import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/financial_calculator.dart';
import '../model/expense_model.dart';
import '../model/payment_model.dart';
import '../model/sale_model.dart';
import '../model/vehicle_model.dart';
import 'vehicle_provider.dart';

class VehicleDetailsData {
  final VehicleModel vehicle;
  final List<VehicleExpenseModel> expenses;
  final VehicleSaleModel? sale;
  final List<VehiclePaymentModel> payments;

  // Derived financial metrics via central calculator
  final double totalExpenses;
  final double totalCost;
  final double totalPaid;
  final double balance;
  final double profitLoss;

  VehicleDetailsData({
    required this.vehicle,
    required this.expenses,
    this.sale,
    required this.payments,
  })  : totalExpenses = VehicleFinancialCalculator.calculateTotalExpenses(
          expenses.map((e) => e.amount).toList(),
        ),
        totalCost = VehicleFinancialCalculator.calculateTotalCost(
          vehicle.purchaseAmount,
          VehicleFinancialCalculator.calculateTotalExpenses(
            expenses.map((e) => e.amount).toList(),
          ),
          vehicle.commissionAmount,
        ),
        totalPaid = VehicleFinancialCalculator.calculateAmountPaid(
          payments.map((p) => p.amount).toList(),
        ),
        balance = sale != null
            ? VehicleFinancialCalculator.calculateBalance(
                sale.totalAmount,
                VehicleFinancialCalculator.calculateAmountPaid(
                  payments.map((p) => p.amount).toList(),
                ),
              )
            : 0.0,
        profitLoss = sale != null
            ? VehicleFinancialCalculator.calculateProfitLoss(
                saleAmount: sale.totalAmount,
                purchaseAmount: vehicle.purchaseAmount,
                commissionAmount: vehicle.commissionAmount,
                totalExpenses: VehicleFinancialCalculator.calculateTotalExpenses(
                  expenses.map((e) => e.amount).toList(),
                ),
              )
            : 0.0;
}

final vehicleDetailsProvider =
    FutureProvider.family<VehicleDetailsData?, int>((ref, vehicleId) async {
  final vehicleRepo = ref.watch(vehicleRepositoryProvider);
  final expenseRepo = ref.watch(expenseRepositoryProvider);
  final salesRepo = ref.watch(salesRepositoryProvider);

  final vehicle = await vehicleRepo.getVehicleById(vehicleId);
  if (vehicle == null) return null;

  final expenses = await expenseRepo.getExpensesByVehicleId(vehicleId);
  final sale = await salesRepo.getSaleByVehicleId(vehicleId);
  final payments = await salesRepo.getPaymentsByVehicleId(vehicleId);

  return VehicleDetailsData(
    vehicle: vehicle,
    expenses: expenses,
    sale: sale,
    payments: payments,
  );
});
