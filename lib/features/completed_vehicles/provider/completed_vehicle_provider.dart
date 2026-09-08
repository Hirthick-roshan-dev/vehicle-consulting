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

enum CompletedPeriod {
  all('All'),
  weekly('Weekly'),
  monthly('Monthly');

  final String displayName;
  const CompletedPeriod(this.displayName);

  DateTime? get startDate {
    final now = DateTime.now();
    switch (this) {
      case CompletedPeriod.weekly:
        return DateTime(now.year, now.month, now.day - (now.weekday - 1));
      case CompletedPeriod.monthly:
        return DateTime(now.year, now.month, 1);
      case CompletedPeriod.all:
        return null;
    }
  }

  DateTime? get endDate {
    final now = DateTime.now();
    switch (this) {
      case CompletedPeriod.weekly:
        final start = DateTime(now.year, now.month, now.day - (now.weekday - 1));
        return DateTime(start.year, start.month, start.day + 6, 23, 59, 59);
      case CompletedPeriod.monthly:
        return DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      case CompletedPeriod.all:
        return null;
    }
  }
}

class CompletedVehicleFilter {
  final String searchQuery;
  final VehicleType? typeFilter;
  final VehicleStatus? statusFilter;
  final bool? profitOnly; // true: profit, false: loss, null: all
  final CompletedPeriod period;
  final int page;
  final int pageSize;

  const CompletedVehicleFilter({
    this.searchQuery = '',
    this.typeFilter,
    this.statusFilter,
    this.profitOnly,
    this.period = CompletedPeriod.all,
    this.page = 1,
    this.pageSize = 12,
  });

  CompletedVehicleFilter copyWith({
    String? searchQuery,
    VehicleType? typeFilter,
    VehicleStatus? statusFilter,
    bool? profitOnly,
    CompletedPeriod? period,
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
      period: period ?? this.period,
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
  final double totalSales;
  final double totalCost;
  final double totalNetPL;
  final double totalBalanceDue;

  int get totalPages => (totalCount / pageSize).ceil() == 0 ? 1 : (totalCount / pageSize).ceil();
  bool get hasPrevPage => currentPage > 1;
  bool get hasNextPage => currentPage < totalPages;

  CompletedVehiclesResult({
    required this.items,
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
    this.totalSales = 0.0,
    this.totalCost = 0.0,
    this.totalNetPL = 0.0,
    this.totalBalanceDue = 0.0,
  });
}

final completedVehicleFilterProvider =
    StateProvider<CompletedVehicleFilter>((ref) => const CompletedVehicleFilter());

final completedVehiclesProvider = FutureProvider<CompletedVehiclesResult>((ref) async {
  final vehicleRepo = ref.watch(vehicleRepositoryProvider);
  final expenseRepo = ref.watch(expenseRepositoryProvider);
  final salesRepo = ref.watch(salesRepositoryProvider);
  final filter = ref.watch(completedVehicleFilterProvider);

  // Fetch all matching completed vehicles
  final vehicles = await vehicleRepo.getVehicles(
    filterStatus: filter.statusFilter,
    filterType: filter.typeFilter,
    searchQuery: filter.searchQuery,
    isCompletedOnly: true,
  );

  final List<CompletedVehicleItem> allMatchingItems = [];

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

        // Filter by time period (sale date)
        if (filter.period != CompletedPeriod.all) {
          final saleDate = DateTime.tryParse(sale.saleDate);
          if (saleDate != null) {
            final start = filter.period.startDate;
            final end = filter.period.endDate;
            if (start != null && saleDate.isBefore(start)) continue;
            if (end != null && saleDate.isAfter(end)) continue;
          }
        }

        // Apply profit/loss filter if active
        if (filter.profitOnly != null) {
          if (filter.profitOnly! && item.profitLoss < 0) continue;
          if (!filter.profitOnly! && item.profitLoss >= 0) continue;
        }

        allMatchingItems.add(item);
      }
    }
  }

  // Sort by sale date descending (most recent first)
  allMatchingItems.sort((a, b) {
    final dtA = DateTime.tryParse(a.sale.saleDate) ?? DateTime.fromMillisecondsSinceEpoch(0);
    final dtB = DateTime.tryParse(b.sale.saleDate) ?? DateTime.fromMillisecondsSinceEpoch(0);
    return dtB.compareTo(dtA);
  });

  final totalCount = allMatchingItems.length;
  final totalSales = allMatchingItems.fold(0.0, (sum, i) => sum + i.sale.totalAmount);
  final totalCost = allMatchingItems.fold(0.0, (sum, i) => sum + i.totalCost);
  final totalNetPL = allMatchingItems.fold(0.0, (sum, i) => sum + i.profitLoss);
  final totalBalanceDue = allMatchingItems.fold(0.0, (sum, i) => sum + i.balance);

  final offset = (filter.page - 1) * filter.pageSize;
  final paginatedItems = (offset >= totalCount)
      ? <CompletedVehicleItem>[]
      : allMatchingItems.skip(offset).take(filter.pageSize).toList();

  return CompletedVehiclesResult(
    items: paginatedItems,
    totalCount: totalCount,
    currentPage: filter.page,
    pageSize: filter.pageSize,
    totalSales: totalSales,
    totalCost: totalCost,
    totalNetPL: totalNetPL,
    totalBalanceDue: totalBalanceDue,
  );
});
