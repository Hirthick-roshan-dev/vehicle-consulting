import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../sales_vehicles/model/vehicle_type.dart';
import '../model/report_models.dart';
import '../repo/report_repository.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository(AppDatabase());
});

class ReportFilterState {
  final ReportPeriod period;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final VehicleType? typeFilter;

  const ReportFilterState({
    this.period = ReportPeriod.thisMonth,
    this.customStartDate,
    this.customEndDate,
    this.typeFilter,
  });

  DateTime? get effectiveStartDate {
    final now = DateTime.now();
    switch (period) {
      case ReportPeriod.thisWeek:
        return DateTime(now.year, now.month, now.day - (now.weekday - 1));
      case ReportPeriod.thisMonth:
        return DateTime(now.year, now.month, 1);
      case ReportPeriod.lastMonth:
        return DateTime(now.year, now.month - 1, 1);
      case ReportPeriod.thisYear:
        return DateTime(now.year, 1, 1);
      case ReportPeriod.allTime:
        return null;
      case ReportPeriod.custom:
        return customStartDate;
    }
  }

  DateTime? get effectiveEndDate {
    final now = DateTime.now();
    switch (period) {
      case ReportPeriod.thisWeek:
        final start = DateTime(now.year, now.month, now.day - (now.weekday - 1));
        return DateTime(start.year, start.month, start.day + 6, 23, 59, 59);
      case ReportPeriod.thisMonth:
        return DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      case ReportPeriod.lastMonth:
        return DateTime(now.year, now.month, 0, 23, 59, 59);
      case ReportPeriod.thisYear:
        return DateTime(now.year, 12, 31, 23, 59, 59);
      case ReportPeriod.allTime:
        return null;
      case ReportPeriod.custom:
        return customEndDate != null
            ? DateTime(customEndDate!.year, customEndDate!.month, customEndDate!.day, 23, 59, 59)
            : null;
    }
  }

  ReportFilterState copyWith({
    ReportPeriod? period,
    DateTime? customStartDate,
    DateTime? customEndDate,
    VehicleType? typeFilter,
    bool clearType = false,
  }) {
    return ReportFilterState(
      period: period ?? this.period,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
      typeFilter: clearType ? null : (typeFilter ?? this.typeFilter),
    );
  }
}

final reportFilterProvider =
    StateProvider<ReportFilterState>((ref) => const ReportFilterState());

class VehiclesReportBundle {
  final StockSummary stockSummary;
  final List<StockReportItem> stockItems;

  final ProfitSummary weeklyProfitSummary;
  final ProfitSummary monthlyProfitSummary;
  final ProfitSummary periodProfitSummary;
  final List<SalesReportItem> periodSalesItems;

  final ProfitSummary overallProfitSummary;

  VehiclesReportBundle({
    required this.stockSummary,
    required this.stockItems,
    required this.weeklyProfitSummary,
    required this.monthlyProfitSummary,
    required this.periodProfitSummary,
    required this.periodSalesItems,
    required this.overallProfitSummary,
  });
}

final vehiclesReportDataProvider =
    FutureProvider<VehiclesReportBundle>((ref) async {
  final repo = ref.watch(reportRepositoryProvider);
  final filter = ref.watch(reportFilterProvider);

  // 1. Stock items & stock summary
  final stockItems = await repo.getStockItems(filterType: filter.typeFilter);
  final stockSummary = StockSummary.fromItems(stockItems);

  // 2. Weekly profit (for current calendar week)
  final weeklySummary = await repo.getWeeklyProfitSummary(filterType: filter.typeFilter);

  // 3. Monthly profit (for current calendar month)
  final monthlySummary = await repo.getMonthlyProfitSummary(filterType: filter.typeFilter);

  // 4. Overall profit (all time)
  final overallSummary = await repo.getOverallProfitSummary(filterType: filter.typeFilter);

  // 5. Period sales items (based on selected period & date range)
  final periodSalesItems = await repo.getSalesItems(
    startDate: filter.effectiveStartDate,
    endDate: filter.effectiveEndDate,
    filterType: filter.typeFilter,
  );
  final periodProfitSummary = ProfitSummary.fromItems(periodSalesItems);

  return VehiclesReportBundle(
    stockSummary: stockSummary,
    stockItems: stockItems,
    weeklyProfitSummary: weeklySummary,
    monthlyProfitSummary: monthlySummary,
    periodProfitSummary: periodProfitSummary,
    periodSalesItems: periodSalesItems,
    overallProfitSummary: overallSummary,
  );
});
