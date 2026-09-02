import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/financial_calculator.dart';
import '../../sales_vehicles/model/expense_model.dart';
import '../../sales_vehicles/model/payment_model.dart';
import '../../sales_vehicles/model/sale_model.dart';
import '../../sales_vehicles/model/vehicle_model.dart';
import '../../sales_vehicles/model/vehicle_status.dart';
import '../../sales_vehicles/model/vehicle_type.dart';
import '../../sales_vehicles/provider/vehicle_provider.dart';

class CompletedVehicleItem {
  final VehicleModel vehicle;
  final List<VehicleExpenseModel> expenses;
  final VehicleSaleModel sale;
  final List<VehiclePaymentModel> payments;

  final double totalExpenses;
  final double totalCost;
  final double totalPaid;
  final double balance;
  final double profitLoss;

  CompletedVehicleItem({
    required this.vehicle,
    required this.expenses,
    required this.sale,
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
        );
}

class CompletedVehicleFilter {
  final String searchQuery;
  final VehicleType? typeFilter;
  final VehicleStatus? statusFilter;
  final bool? profitOnly; // true: profit, false: loss, null: all
  final int page;
  final int pageSize;

  const CompletedVehicleFilter({
    this.searchQuery = '',
    this.typeFilter,
    this.statusFilter,
    this.profitOnly,
    this.page = 1,
    this.pageSize = 12,
  });

  CompletedVehicleFilter copyWith({
    String? searchQuery,
    VehicleType? typeFilter,
    VehicleStatus? statusFilter,
    bool? profitOnly,
    int? page,
    int? pageSize,
    bool clearType = false,
    bool clearStatus = false,
    bool clearProfit = false,
  }) {
    return CompletedVehicleFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      typeFilter: clearType ? null : (typeFilter ?? this.typeFilter),
      statusFilter: clearStatus ? null : (statusFilter ?? this.statusFilter),
      profitOnly: clearProfit ? null : (profitOnly ?? this.profitOnly),
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

class CompletedVehiclesResult {
  final List<CompletedVehicleItem> items;
  final int totalCount;
  final int currentPage;
  final int pageSize;

  int get totalPages => (totalCount / pageSize).ceil() == 0 ? 1 : (totalCount / pageSize).ceil();
  bool get hasPrevPage => currentPage > 1;
  bool get hasNextPage => currentPage < totalPages;

  CompletedVehiclesResult({
    required this.items,
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
  });
}

final completedVehicleFilterProvider =
    StateProvider<CompletedVehicleFilter>((ref) => const CompletedVehicleFilter());

final completedVehiclesProvider = FutureProvider<CompletedVehiclesResult>((ref) async {
  final vehicleRepo = ref.watch(vehicleRepositoryProvider);
  final expenseRepo = ref.watch(expenseRepositoryProvider);
  final salesRepo = ref.watch(salesRepositoryProvider);
  final filter = ref.watch(completedVehicleFilterProvider);

  final totalCount = await vehicleRepo.getVehiclesCount(
    filterStatus: filter.statusFilter,
    filterType: filter.typeFilter,
    searchQuery: filter.searchQuery,
    isCompletedOnly: true,
  );

  final offset = (filter.page - 1) * filter.pageSize;

  // Fetch paginated vehicles for completed module
  final vehicles = await vehicleRepo.getVehicles(
    filterStatus: filter.statusFilter,
    filterType: filter.typeFilter,
    searchQuery: filter.searchQuery,
    isCompletedOnly: true,
    limit: filter.pageSize,
    offset: offset,
  );

  final List<CompletedVehicleItem> items = [];

  for (var v in vehicles) {
    if (v.id != null) {
      final expenses = await expenseRepo.getExpensesByVehicleId(v.id!);
      final sale = await salesRepo.getSaleByVehicleId(v.id!);
      final payments = await salesRepo.getPaymentsByVehicleId(v.id!);

      if (sale != null) {
        final item = CompletedVehicleItem(
          vehicle: v,
          expenses: expenses,
          sale: sale,
          payments: payments,
        );

        // Apply profit/loss filter if active
        if (filter.profitOnly != null) {
          if (filter.profitOnly! && item.profitLoss < 0) continue;
          if (!filter.profitOnly! && item.profitLoss >= 0) continue;
        }

        items.add(item);
      }
    }
  }

  return CompletedVehiclesResult(
    items: items,
    totalCount: totalCount,
    currentPage: filter.page,
    pageSize: filter.pageSize,
  );
});
