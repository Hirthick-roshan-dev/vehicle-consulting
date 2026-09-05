import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../auth/provider/auth_provider.dart';
import '../../sales_vehicles/model/vehicle_type.dart';
import '../model/report_models.dart';
import '../provider/report_provider.dart';

class VehiclesReportScreen extends ConsumerStatefulWidget {
  const VehiclesReportScreen({super.key});

  @override
  ConsumerState<VehiclesReportScreen> createState() => _VehiclesReportScreenState();
}

class _VehiclesReportScreenState extends ConsumerState<VehiclesReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _selectCustomDateRange(BuildContext context) async {
    final filter = ref.read(reportFilterProvider);
    final initialRange = DateTimeRange(
      start: filter.customStartDate ?? DateTime.now().subtract(const Duration(days: 30)),
      end: filter.customEndDate ?? DateTime.now(),
    );

    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.primaryText,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(reportFilterProvider.notifier).state = filter.copyWith(
        period: ReportPeriod.custom,
        customStartDate: picked.start,
        customEndDate: picked.end,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isAdmin = authState.user?.isAdmin ?? false;

    // RBAC Guard: Restricted to Admin only
    if (!isAdmin) {
      return Scaffold(
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.gavel, size: 64, color: AppColors.loss),
                SizedBox(height: 16),
                Text(
                  'Access Restricted',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.loss,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Executive Vehicles Stock and Financial Profit/Loss reports are strictly accessible to Admin users only.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final filter = ref.watch(reportFilterProvider);
    final reportAsync = ref.watch(vehiclesReportDataProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Screen Header & Filter Controls
            _buildHeader(context, filter),
            const SizedBox(height: 16),

            // Main Content Area
            Expanded(
              child: reportAsync.when(
                loading: () => const LoadingWidget(message: 'Compiling vehicles and financial report...'),
                error: (err, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.loss),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load report: $err',
                        style: const TextStyle(color: AppColors.loss, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => ref.refresh(vehiclesReportDataProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (bundle) => _buildReportContent(context, filter, bundle),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ReportFilterState filter) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.analytics_rounded, color: AppColors.primary, size: 28),
                    const SizedBox(width: 10),
                    const Text(
                      'Vehicles Report & Business Intelligence',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'ADMIN EXCLUSIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Live inventory stock value, weekly & monthly profit realization, and sales financial metrics.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                // Vehicle Type Filter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<VehicleType?>(
                      value: filter.typeFilter,
                      hint: const Text('All Types', style: TextStyle(fontSize: 13)),
                      items: [
                        const DropdownMenuItem<VehicleType?>(
                          value: null,
                          child: Text('All Types (2W & 4W)', style: TextStyle(fontSize: 13)),
                        ),
                        ...VehicleType.values.map(
                          (t) => DropdownMenuItem<VehicleType?>(
                            value: t,
                            child: Text(t.displayName, style: const TextStyle(fontSize: 13)),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        ref.read(reportFilterProvider.notifier).state = filter.copyWith(
                          typeFilter: val,
                          clearType: val == null,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Refresh Button
                OutlinedButton.icon(
                  onPressed: () => ref.refresh(vehiclesReportDataProvider),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Period Filters Bar
        Row(
          children: [
            const Text(
              'Sales Period: ',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(width: 8),
            Wrap(
              spacing: 8,
              children: ReportPeriod.values.map((p) {
                final isSelected = filter.period == p;
                return ChoiceChip(
                  label: Text(p.displayName),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.primaryText,
                  ),
                  onSelected: (selected) {
                    if (p == ReportPeriod.custom) {
                      _selectCustomDateRange(context);
                    } else {
                      ref.read(reportFilterProvider.notifier).state =
                          filter.copyWith(period: p);
                    }
                  },
                );
              }).toList(),
            ),
            if (filter.period == ReportPeriod.custom &&
                filter.customStartDate != null &&
                filter.customEndDate != null) ...[
              const SizedBox(width: 8),
              Chip(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                label: Text(
                  '${AppDateUtils.formatDisplay(filter.customStartDate)} - ${AppDateUtils.formatDisplay(filter.customEndDate)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                onDeleted: () => _selectCustomDateRange(context),
                deleteIcon: const Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildReportContent(
    BuildContext context,
    ReportFilterState filter,
    VehiclesReportBundle bundle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top 4 Executive KPI Cards
        _buildKpiCardsGrid(bundle, filter),
        const SizedBox(height: 20),

        // Tab Navigation Bar
        Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.secondaryText,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.receipt_long, size: 18),
                    const SizedBox(width: 8),
                    Text('Sales & Profit Ledger (${bundle.periodSalesItems.length})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.inventory_2, size: 18),
                    const SizedBox(width: 8),
                    Text('Available Stock Inventory (${bundle.stockItems.length})'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Tab Contents
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
              border: Border(
                left: BorderSide(color: AppColors.border),
                right: BorderSide(color: AppColors.border),
                bottom: BorderSide(color: AppColors.border),
              ),
            ),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSalesTab(bundle, filter),
                _buildStockTab(bundle),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCardsGrid(VehiclesReportBundle bundle, ReportFilterState filter) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - (3 * 16)) / 4;
        final useRow = cardWidth >= 230;

        final cards = [
          // 1. Current Vehicles Stock
          _buildKpiCard(
            title: 'TOTAL VEHICLES STOCK',
            value: '${bundle.stockSummary.totalCount} in Stock',
            valueColor: AppColors.primaryText,
            icon: Icons.directions_car_filled,
            iconBgColor: AppColors.primary.withValues(alpha: 0.1),
            iconColor: AppColors.primary,
            subtitle: '${bundle.stockSummary.twoWheelerCount} 2W  •  ${bundle.stockSummary.fourWheelerCount} 4W',
            metrics: [
              _KpiMetricRow(
                label: 'Capital Invested',
                value: CurrencyUtils.format(bundle.stockSummary.totalInvested),
              ),
              _KpiMetricRow(
                label: 'Expected Value',
                value: CurrencyUtils.format(bundle.stockSummary.totalExpectedValue),
              ),
              _KpiMetricRow(
                label: 'Projected Profit',
                value: CurrencyUtils.format(bundle.stockSummary.projectedProfit),
                valueColor: bundle.stockSummary.projectedProfit >= 0
                    ? AppColors.profit
                    : AppColors.loss,
              ),
            ],
          ),

          // 2. Weekly Profit
          _buildKpiCard(
            title: 'WEEKLY PROFIT',
            value: CurrencyUtils.format(bundle.weeklyProfitSummary.totalProfitLoss),
            valueColor: bundle.weeklyProfitSummary.totalProfitLoss >= 0
                ? AppColors.profit
                : AppColors.loss,
            icon: Icons.date_range,
            iconBgColor: AppColors.profit.withValues(alpha: 0.1),
            iconColor: AppColors.profit,
            subtitle: '${bundle.weeklyProfitSummary.totalVehiclesSold} vehicles sold this week',
            badgeText: bundle.weeklyProfitSummary.profitMarginPercent.abs() > 0
                ? '${bundle.weeklyProfitSummary.profitMarginPercent >= 0 ? '+' : ''}${bundle.weeklyProfitSummary.profitMarginPercent.toStringAsFixed(1)}% margin'
                : null,
            badgeColor: bundle.weeklyProfitSummary.profitMarginPercent >= 0
                ? AppColors.profit
                : AppColors.loss,
            metrics: [
              _KpiMetricRow(
                label: 'Weekly Revenue',
                value: CurrencyUtils.format(bundle.weeklyProfitSummary.totalRevenue),
              ),
              _KpiMetricRow(
                label: 'Total Cost',
                value: CurrencyUtils.format(bundle.weeklyProfitSummary.totalCost),
              ),
              _KpiMetricRow(
                label: 'Expenses Logged',
                value: CurrencyUtils.format(bundle.weeklyProfitSummary.totalExpenses),
              ),
            ],
          ),

          // 3. Monthly Profit
          _buildKpiCard(
            title: 'MONTHLY PROFIT',
            value: CurrencyUtils.format(bundle.monthlyProfitSummary.totalProfitLoss),
            valueColor: bundle.monthlyProfitSummary.totalProfitLoss >= 0
                ? AppColors.profit
                : AppColors.loss,
            icon: Icons.calendar_month,
            iconBgColor: AppColors.primary.withValues(alpha: 0.1),
            iconColor: AppColors.primary,
            subtitle: '${bundle.monthlyProfitSummary.totalVehiclesSold} vehicles sold this month',
            badgeText: bundle.monthlyProfitSummary.profitMarginPercent.abs() > 0
                ? '${bundle.monthlyProfitSummary.profitMarginPercent >= 0 ? '+' : ''}${bundle.monthlyProfitSummary.profitMarginPercent.toStringAsFixed(1)}% margin'
                : null,
            badgeColor: bundle.monthlyProfitSummary.profitMarginPercent >= 0
                ? AppColors.profit
                : AppColors.loss,
            metrics: [
              _KpiMetricRow(
                label: 'Monthly Revenue',
                value: CurrencyUtils.format(bundle.monthlyProfitSummary.totalRevenue),
              ),
              _KpiMetricRow(
                label: 'Total Cost',
                value: CurrencyUtils.format(bundle.monthlyProfitSummary.totalCost),
              ),
              _KpiMetricRow(
                label: 'Expenses Logged',
                value: CurrencyUtils.format(bundle.monthlyProfitSummary.totalExpenses),
              ),
            ],
          ),

          // 4. Period Net Profit & Collections
          _buildKpiCard(
            title: '${filter.period.displayName.toUpperCase()} PROFIT',
            value: CurrencyUtils.format(bundle.periodProfitSummary.totalProfitLoss),
            valueColor: bundle.periodProfitSummary.totalProfitLoss >= 0
                ? AppColors.profit
                : AppColors.loss,
            icon: Icons.account_balance_wallet,
            iconBgColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
            iconColor: const Color(0xFF6366F1),
            subtitle: '${bundle.periodProfitSummary.totalVehiclesSold} sold in selected period',
            metrics: [
              _KpiMetricRow(
                label: 'Period Revenue',
                value: CurrencyUtils.format(bundle.periodProfitSummary.totalRevenue),
              ),
              _KpiMetricRow(
                label: 'Cash Collected',
                value: CurrencyUtils.format(bundle.periodProfitSummary.totalCollected),
                valueColor: AppColors.profit,
              ),
              _KpiMetricRow(
                label: 'Pending Balance',
                value: CurrencyUtils.format(bundle.periodProfitSummary.totalPendingReceivable),
                valueColor: bundle.periodProfitSummary.totalPendingReceivable > 0
                    ? AppColors.partialPayment
                    : AppColors.secondaryText,
              ),
            ],
          ),
        ];

        if (useRow) {
          return Row(
            children: cards
                .map((c) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: c,
                      ),
                    ))
                .toList(),
          );
        } else {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: cards
                .map((c) => SizedBox(
                      width: constraints.maxWidth > 550 ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth,
                      child: c,
                    ))
                .toList(),
          );
        }
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required Color valueColor,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String subtitle,
    String? badgeText,
    Color? badgeColor,
    required List<_KpiMetricRow> metrics,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Title & Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                    color: AppColors.secondaryText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Main Big Figure & Badge
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: valueColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badgeText != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? AppColors.profit).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: badgeColor ?? AppColors.profit,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryText,
            ),
          ),
          const Divider(height: 16, color: AppColors.border),

          // Sub-metrics
          ...metrics.map(
            (m) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    m.label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  Text(
                    m.value,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: m.valueColor ?? AppColors.primaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesTab(VehiclesReportBundle bundle, ReportFilterState filter) {
    if (bundle.periodSalesItems.isEmpty) {
      return Center(
        child: EmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'No Sales in ${filter.period.displayName}',
          subtitle: 'There are no completed or partial payment vehicle sales recorded for this period.',
        ),
      );
    }

    return Column(
      children: [
        // Summary Performance Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.04),
            border: const Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.bar_chart, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Showing ${bundle.periodSalesItems.length} Sales Transactions in ${filter.period.displayName}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildInlineStat(
                    label: 'Total Revenue',
                    value: CurrencyUtils.format(bundle.periodProfitSummary.totalRevenue),
                  ),
                  const SizedBox(width: 16),
                  _buildInlineStat(
                    label: 'Total Expenses',
                    value: CurrencyUtils.format(bundle.periodProfitSummary.totalExpenses),
                  ),
                  const SizedBox(width: 16),
                  _buildInlineStat(
                    label: 'Net Profit Realized',
                    value: CurrencyUtils.format(bundle.periodProfitSummary.totalProfitLoss),
                    color: bundle.periodProfitSummary.totalProfitLoss >= 0
                        ? AppColors.profit
                        : AppColors.loss,
                    bold: true,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFFF1F5F9),
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: const Row(
            children: [
              Expanded(flex: 3, child: Text('VEHICLE & CUSTOMER', style: _tableHeaderStyle)),
              Expanded(flex: 2, child: Text('SALE DATE', style: _tableHeaderStyle)),
              Expanded(flex: 2, child: Text('PURCHASE COST', style: _tableHeaderStyle)),
              Expanded(flex: 2, child: Text('EXPENSES', style: _tableHeaderStyle)),
              Expanded(flex: 2, child: Text('SELLING PRICE', style: _tableHeaderStyle)),
              Expanded(flex: 2, child: Text('NET PROFIT / LOSS', style: _tableHeaderStyle)),
              Expanded(flex: 2, child: Text('PAYMENT STATUS', style: _tableHeaderStyle)),
            ],
          ),
        ),

        // Sales List
        Expanded(
          child: ListView.separated(
            itemCount: bundle.periodSalesItems.length,
            separatorBuilder: (ctx, i) => const Divider(height: 1, color: AppColors.border),
            itemBuilder: (context, index) {
              final item = bundle.periodSalesItems[index];
              final isProfit = item.profitLoss >= 0;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    // Vehicle & Customer
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                item.vehicle.vehicleNumber,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.primaryText,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.vehicle.vehicleType.code,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.vehicle.vehicleName} • Customer: ${item.sale.customerName}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF475569),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Sale Date
                    Expanded(
                      flex: 2,
                      child: Text(
                        AppDateUtils.formatDisplay(item.saleDate),
                        style: const TextStyle(fontSize: 12, color: AppColors.primaryText),
                      ),
                    ),

                    // Purchase Cost
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            CurrencyUtils.format(item.vehicle.purchaseAmount),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          if (item.vehicle.commissionAmount > 0)
                            Text(
                              '+${CurrencyUtils.format(item.vehicle.commissionAmount)} comm.',
                              style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                            ),
                        ],
                      ),
                    ),

                    // Expenses
                    Expanded(
                      flex: 2,
                      child: Text(
                        CurrencyUtils.format(item.totalExpenses),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: item.totalExpenses > 0 ? const Color(0xFFD97706) : AppColors.secondaryText,
                        ),
                      ),
                    ),

                    // Selling Price
                    Expanded(
                      flex: 2,
                      child: Text(
                        CurrencyUtils.format(item.sale.totalAmount),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ),

                    // Net Profit / Loss
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (isProfit ? AppColors.profit : AppColors.loss).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${isProfit ? '+' : ''}${CurrencyUtils.format(item.profitLoss)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isProfit ? AppColors.profit : AppColors.loss,
                                  ),
                                ),
                                Text(
                                  '${isProfit ? '+' : ''}${item.profitMarginPercent.toStringAsFixed(1)}% margin',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: isProfit ? AppColors.profit : AppColors.loss,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Payment Status
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (item.balance <= 0
                                      ? AppColors.profit
                                      : AppColors.partialPayment)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.balance <= 0 ? 'Fully Paid' : 'Partial Paid',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: item.balance <= 0
                                    ? AppColors.profit
                                    : AppColors.partialPayment,
                              ),
                            ),
                          ),
                          if (item.balance > 0)
                            Text(
                              'Bal: ${CurrencyUtils.format(item.balance)}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.partialPayment,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStockTab(VehiclesReportBundle bundle) {
    if (bundle.stockItems.isEmpty) {
      return const Center(
        child: EmptyState(
          icon: Icons.inventory_2_outlined,
          title: 'Stock is Empty',
          subtitle: 'There are currently no vehicles available for sale in stock.',
        ),
      );
    }

    return Column(
      children: [
        // Summary Performance Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.04),
            border: const Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.warehouse_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    '${bundle.stockItems.length} Vehicles In Yard Inventory',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildInlineStat(
                    label: 'Total Capital Tied Up',
                    value: CurrencyUtils.format(bundle.stockSummary.totalInvested),
                  ),
                  const SizedBox(width: 16),
                  _buildInlineStat(
                    label: 'Listed Expected Realization',
                    value: CurrencyUtils.format(bundle.stockSummary.totalExpectedValue),
                  ),
                  const SizedBox(width: 16),
                  _buildInlineStat(
                    label: 'Projected Potential Profit',
                    value: CurrencyUtils.format(bundle.stockSummary.projectedProfit),
                    color: AppColors.profit,
                    bold: true,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFFF1F5F9),
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: const Row(
            children: [
              Expanded(flex: 3, child: Text('VEHICLE DETAILS', style: _tableHeaderStyle)),
              Expanded(flex: 2, child: Text('PURCHASE DATE', style: _tableHeaderStyle)),
              Expanded(flex: 2, child: Text('STOCK DURATION', style: _tableHeaderStyle)),
              Expanded(flex: 2, child: Text('PURCHASE PRICE', style: _tableHeaderStyle)),
              Expanded(flex: 2, child: Text('CURRENT EXPENSES', style: _tableHeaderStyle)),
              Expanded(flex: 2, child: Text('TOTAL INVESTED', style: _tableHeaderStyle)),
              Expanded(flex: 2, child: Text('EXPECTED PRICE', style: _tableHeaderStyle)),
              Expanded(flex: 2, child: Text('PROJECTED PROFIT', style: _tableHeaderStyle)),
            ],
          ),
        ),

        // Stock List
        Expanded(
          child: ListView.separated(
            itemCount: bundle.stockItems.length,
            separatorBuilder: (ctx, i) => const Divider(height: 1, color: AppColors.border),
            itemBuilder: (context, index) {
              final item = bundle.stockItems[index];
              final isAging = item.daysInStock > 30;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    // Vehicle Details
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                item.vehicle.vehicleNumber,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.primaryText,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.vehicle.vehicleType.code,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.vehicle.vehicleName} (${item.vehicle.manufacturingYear}) • ${item.vehicle.ownerName}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF475569),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Purchase Date
                    Expanded(
                      flex: 2,
                      child: Text(
                        AppDateUtils.formatDisplay(item.vehicle.purchaseDate),
                        style: const TextStyle(fontSize: 12, color: AppColors.primaryText),
                      ),
                    ),

                    // Stock Duration (Days in Yard)
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: isAging
                                  ? AppColors.loss.withValues(alpha: 0.1)
                                  : AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${item.daysInStock} days',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isAging ? AppColors.loss : AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Purchase Price
                    Expanded(
                      flex: 2,
                      child: Text(
                        CurrencyUtils.format(item.vehicle.purchaseAmount),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),

                    // Current Expenses
                    Expanded(
                      flex: 2,
                      child: Text(
                        CurrencyUtils.format(item.totalExpenses),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: item.totalExpenses > 0 ? const Color(0xFFD97706) : AppColors.secondaryText,
                        ),
                      ),
                    ),

                    // Total Invested
                    Expanded(
                      flex: 2,
                      child: Text(
                        CurrencyUtils.format(item.totalInvested),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ),

                    // Expected Sale Price
                    Expanded(
                      flex: 2,
                      child: Text(
                        item.expectedSalePrice > 0
                            ? CurrencyUtils.format(item.expectedSalePrice)
                            : 'Not Listed',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: item.expectedSalePrice > 0
                              ? AppColors.primaryText
                              : AppColors.secondaryText,
                        ),
                      ),
                    ),

                    // Projected Profit
                    Expanded(
                      flex: 2,
                      child: item.expectedSalePrice > 0
                          ? Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (item.projectedProfit >= 0
                                            ? AppColors.profit
                                            : AppColors.loss)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${item.projectedProfit >= 0 ? '+' : ''}${CurrencyUtils.format(item.projectedProfit)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: item.projectedProfit >= 0
                                          ? AppColors.profit
                                          : AppColors.loss,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              '-',
                              style: TextStyle(color: AppColors.secondaryText),
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInlineStat({
    required String label,
    required String value,
    Color? color,
    bool bold = false,
  }) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.secondaryText,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            color: color ?? AppColors.primaryText,
          ),
        ),
      ],
    );
  }
}

class _KpiMetricRow {
  final String label;
  final String value;
  final Color? valueColor;

  const _KpiMetricRow({
    required this.label,
    required this.value,
    this.valueColor,
  });
}

const TextStyle _tableHeaderStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.bold,
  letterSpacing: 0.5,
  color: Color(0xFF475569),
);
