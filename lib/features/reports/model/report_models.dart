import '../../../core/utils/financial_calculator.dart';
import '../../sales_vehicles/model/expense_model.dart';
import '../../sales_vehicles/model/payment_model.dart';
import '../../sales_vehicles/model/sale_model.dart';
import '../../sales_vehicles/model/vehicle_model.dart';

enum ReportPeriod {
  thisWeek('This Week'),
  thisMonth('This Month'),
  lastMonth('Last Month'),
  thisYear('This Year'),
  allTime('All Time'),
  custom('Custom Range');

  final String displayName;
  const ReportPeriod(this.displayName);
}

class StockReportItem {
  final VehicleModel vehicle;
  final List<VehicleExpenseModel> expenses;
  final double totalExpenses;
  final double totalInvested; // purchase + commission + expenses
  final double expectedSalePrice;
  final double projectedProfit; // expectedSalePrice - totalInvested
  final int daysInStock;

  StockReportItem({
    required this.vehicle,
    required this.expenses,
  })  : totalExpenses = VehicleFinancialCalculator.calculateTotalExpenses(
          expenses.map((e) => e.amount).toList(),
        ),
        totalInvested = VehicleFinancialCalculator.calculateTotalCost(
          vehicle.purchaseAmount,
          VehicleFinancialCalculator.calculateTotalExpenses(
            expenses.map((e) => e.amount).toList(),
          ),
          vehicle.commissionAmount,
        ),
        expectedSalePrice = vehicle.salePrice,
        projectedProfit = vehicle.salePrice > 0
            ? vehicle.salePrice -
                VehicleFinancialCalculator.calculateTotalCost(
                  vehicle.purchaseAmount,
                  VehicleFinancialCalculator.calculateTotalExpenses(
                    expenses.map((e) => e.amount).toList(),
                  ),
                  vehicle.commissionAmount,
                )
            : 0.0,
        daysInStock = _calcDays(vehicle.purchaseDate);

  static int _calcDays(String purchaseDate) {
    final dt = DateTime.tryParse(purchaseDate);
    if (dt == null) return 0;
    final diff = DateTime.now().difference(dt).inDays;
    return diff < 0 ? 0 : diff;
  }
}

class SalesReportItem {
  final VehicleModel vehicle;
  final VehicleSaleModel sale;
  final List<VehiclePaymentModel> payments;
  final List<VehicleExpenseModel> expenses;

  final double totalExpenses;
  final double totalCost;
  final double totalPaid;
  final double balance;
  final double profitLoss;
  final double profitMarginPercent;
  final DateTime saleDate;

  SalesReportItem({
    required this.vehicle,
    required this.sale,
    required this.payments,
    required this.expenses,
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
        balance = VehicleFinancialCalculator.calculateBalance(
          sale.totalAmount,
          VehicleFinancialCalculator.calculateAmountPaid(
            payments.map((p) => p.amount).toList(),
          ),
        ),
        profitLoss = VehicleFinancialCalculator.calculateProfitLoss(
          saleAmount: sale.totalAmount,
          purchaseAmount: vehicle.purchaseAmount,
          commissionAmount: vehicle.commissionAmount,
          totalExpenses: VehicleFinancialCalculator.calculateTotalExpenses(
            expenses.map((e) => e.amount).toList(),
          ),
        ),
        profitMarginPercent = VehicleFinancialCalculator.calculateTotalCost(
                  vehicle.purchaseAmount,
                  VehicleFinancialCalculator.calculateTotalExpenses(
                    expenses.map((e) => e.amount).toList(),
                  ),
                  vehicle.commissionAmount,
                ) >
                0
            ? (VehicleFinancialCalculator.calculateProfitLoss(
                      saleAmount: sale.totalAmount,
                      purchaseAmount: vehicle.purchaseAmount,
                      commissionAmount: vehicle.commissionAmount,
                      totalExpenses: VehicleFinancialCalculator.calculateTotalExpenses(
                        expenses.map((e) => e.amount).toList(),
                      ),
                    ) /
                    VehicleFinancialCalculator.calculateTotalCost(
                      vehicle.purchaseAmount,
                      VehicleFinancialCalculator.calculateTotalExpenses(
                        expenses.map((e) => e.amount).toList(),
                      ),
                      vehicle.commissionAmount,
                    )) *
                100
            : 0.0,
        saleDate = DateTime.tryParse(sale.saleDate) ?? DateTime.now();
}

class StockSummary {
  final int totalCount;
  final int twoWheelerCount;
  final int fourWheelerCount;
  final double totalInvested;
  final double totalExpectedValue;
  final double projectedProfit;

  const StockSummary({
    this.totalCount = 0,
    this.twoWheelerCount = 0,
    this.fourWheelerCount = 0,
    this.totalInvested = 0.0,
    this.totalExpectedValue = 0.0,
    this.projectedProfit = 0.0,
  });

  factory StockSummary.fromItems(List<StockReportItem> items) {
    int twoW = 0;
    int fourW = 0;
    double invested = 0.0;
    double expectedVal = 0.0;
    double projProfit = 0.0;

    for (final item in items) {
      if (item.vehicle.vehicleType.code == '2W') {
        twoW++;
      } else {
        fourW++;
      }
      invested += item.totalInvested;
      expectedVal += item.expectedSalePrice;
      projProfit += item.projectedProfit;
    }

    return StockSummary(
      totalCount: items.length,
      twoWheelerCount: twoW,
      fourWheelerCount: fourW,
      totalInvested: invested,
      totalExpectedValue: expectedVal,
      projectedProfit: projProfit,
    );
  }
}

class ProfitSummary {
  final int totalVehiclesSold;
  final double totalRevenue;
  final double totalCost;
  final double totalExpenses;
  final double totalProfitLoss;
  final double profitMarginPercent;
  final double totalCollected;
  final double totalPendingReceivable;

  const ProfitSummary({
    this.totalVehiclesSold = 0,
    this.totalRevenue = 0.0,
    this.totalCost = 0.0,
    this.totalExpenses = 0.0,
    this.totalProfitLoss = 0.0,
    this.profitMarginPercent = 0.0,
    this.totalCollected = 0.0,
    this.totalPendingReceivable = 0.0,
  });

  factory ProfitSummary.fromItems(List<SalesReportItem> items) {
    double revenue = 0.0;
    double cost = 0.0;
    double expenses = 0.0;
    double profit = 0.0;
    double collected = 0.0;
    double pending = 0.0;

    for (final item in items) {
      revenue += item.sale.totalAmount;
      cost += item.totalCost;
      expenses += item.totalExpenses;
      profit += item.profitLoss;
      collected += item.totalPaid;
      pending += item.balance;
    }

    final margin = cost > 0 ? (profit / cost) * 100 : 0.0;

    return ProfitSummary(
      totalVehiclesSold: items.length,
      totalRevenue: revenue,
      totalCost: cost,
      totalExpenses: expenses,
      totalProfitLoss: profit,
      profitMarginPercent: margin,
      totalCollected: collected,
      totalPendingReceivable: pending,
    );
  }
}
