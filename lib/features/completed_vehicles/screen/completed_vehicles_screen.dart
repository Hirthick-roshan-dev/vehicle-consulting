import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../auth/provider/auth_provider.dart';
import '../../sales_vehicles/model/payment_model.dart';
import '../../sales_vehicles/model/vehicle_status.dart';
import '../../sales_vehicles/model/vehicle_type.dart';
import '../../sales_vehicles/provider/vehicle_details_provider.dart';
import '../../sales_vehicles/provider/vehicle_provider.dart';
import '../../sales_vehicles/screen/vehicle_details_screen.dart';
import '../../sales_vehicles/screen/widgets/add_payment_dialog.dart';
import '../provider/completed_vehicle_provider.dart';
import 'widgets/completed_vehicle_card.dart';

class CompletedVehiclesScreen extends ConsumerStatefulWidget {
  const CompletedVehiclesScreen({super.key});

  @override
  ConsumerState<CompletedVehiclesScreen> createState() => _CompletedVehiclesScreenState();
}

class _CompletedVehiclesScreenState extends ConsumerState<CompletedVehiclesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isAdmin = authState.user?.isAdmin ?? false;

    // RBAC Protection
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
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.loss),
                ),
                SizedBox(height: 8),
                Text(
                  'Completed Vehicles, Partial Payment Tracking, and Financial Profit/Loss records are accessible to Admin users only.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final filter = ref.watch(completedVehicleFilterProvider);
    final completedAsync = ref.watch(completedVehiclesProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Completed & Partial Sales Archive',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Product card catalog for completed and partially paid vehicle records with Profit/Loss analysis.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Controls & Filters Bar
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (query) {
                      ref.read(completedVehicleFilterProvider.notifier).state =
                          filter.copyWith(searchQuery: query, page: 1);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by Vehicle No, Name, Model...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                ref.read(completedVehicleFilterProvider.notifier).state =
                                    filter.copyWith(searchQuery: '', page: 1);
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Status Filter Chips
                FilterChip(
                  label: const Text('All Statuses'),
                  selected: filter.statusFilter == null,
                  onSelected: (sel) {
                    ref.read(completedVehicleFilterProvider.notifier).state =
                        filter.copyWith(clearStatus: true, page: 1);
                  },
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: const Text('Partial Payment'),
                  selected: filter.statusFilter == VehicleStatus.partialPayment,
                  onSelected: (sel) {
                    ref.read(completedVehicleFilterProvider.notifier).state =
                        filter.copyWith(statusFilter: sel ? VehicleStatus.partialPayment : null, page: 1);
                  },
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: const Text('Fully Paid'),
                  selected: filter.statusFilter == VehicleStatus.completed,
                  onSelected: (sel) {
                    ref.read(completedVehicleFilterProvider.notifier).state =
                        filter.copyWith(statusFilter: sel ? VehicleStatus.completed : null, page: 1);
                  },
                ),
                const SizedBox(width: 12),
                // Type Filter Chips
                FilterChip(
                  label: const Text('2W'),
                  selected: filter.typeFilter == VehicleType.twoWheeler,
                  onSelected: (sel) {
                    ref.read(completedVehicleFilterProvider.notifier).state = filter.copyWith(
                      typeFilter: sel ? VehicleType.twoWheeler : null,
                      clearType: !sel,
                      page: 1,
                    );
                  },
                ),
                const SizedBox(width: 6),
                FilterChip(
                  label: const Text('4W'),
                  selected: filter.typeFilter == VehicleType.fourWheeler,
                  onSelected: (sel) {
                    ref.read(completedVehicleFilterProvider.notifier).state = filter.copyWith(
                      typeFilter: sel ? VehicleType.fourWheeler : null,
                      clearType: !sel,
                      page: 1,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Async Data Content
            Expanded(
              child: completedAsync.when(
                loading: () => const LoadingWidget(message: 'Calculating completed vehicles metrics...'),
                error: (err, stack) => Center(
                  child: Text('Error: $err', style: const TextStyle(color: AppColors.loss)),
                ),
                data: (result) {
                  final items = result.items;
                  if (items.isEmpty) {
                    return const EmptyState(
                      title: 'No records found',
                      subtitle: 'Vehicles will appear here once sales information is recorded.',
                      icon: Icons.task_alt,
                    );
                  }

                  // Financial Summary Cards for current view
                  final totalSales = items.fold(0.0, (sum, i) => sum + i.sale.totalAmount);
                  final totalCost = items.fold(0.0, (sum, i) => sum + i.totalCost);
                  final totalNetPL = items.fold(0.0, (sum, i) => sum + i.profitLoss);
                  final totalBalanceDue = items.fold(0.0, (sum, i) => sum + i.balance);

                  return Column(
                    children: [
                      _buildSummaryBar(result.totalCount, totalSales, totalCost, totalNetPL, totalBalanceDue),
                      const SizedBox(height: 16),
                      // Product Card Grid
                      Expanded(
                        child: GridView.builder(
                          itemCount: items.length,
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 320,
                            mainAxisExtent: 400,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final v = item.vehicle;

                            return CompletedVehicleCard(
                              item: item,
                              onView: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (ctx) => VehicleDetailsScreen(vehicleId: v.id!),
                                  ),
                                ).then((_) {
                                  ref.invalidate(completedVehiclesProvider);
                                });
                              },
                              onRecordPayment: item.balance > 0
                                  ? () async {
                                      final payment = await showDialog<VehiclePaymentModel>(
                                        context: context,
                                        builder: (ctx) => AddPaymentDialog(
                                          vehicleId: v.id!,
                                          saleId: item.sale.id!,
                                          currentBalance: item.balance,
                                        ),
                                      );
                                      if (payment != null) {
                                        await ref.read(salesRepositoryProvider).addPayment(
                                              payment: payment,
                                              totalSaleAmount: item.sale.totalAmount,
                                            );
                                        ref.invalidate(completedVehiclesProvider);
                                        ref.invalidate(vehicleDetailsProvider(v.id!));
                                      }
                                    }
                                  : null,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Pagination Bar
                      _buildPaginationBar(context, ref, result, filter),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBar(
    int count,
    double totalSales,
    double totalCost,
    double totalNetPL,
    double totalBalanceDue,
  ) {
    final isNetProfit = totalNetPL >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat('Archive Count', count.toString(), isBold: true),
          const SizedBox(width: 1, height: 36, child: VerticalDivider()),
          _stat('Total Sales', CurrencyUtils.format(totalSales), color: const Color(0xFF059669)),
          const SizedBox(width: 1, height: 36, child: VerticalDivider()),
          _stat('Total Cost', CurrencyUtils.format(totalCost), color: AppColors.primary),
          const SizedBox(width: 1, height: 36, child: VerticalDivider()),
          _stat(
            'Total Balance Due',
            CurrencyUtils.format(totalBalanceDue),
            color: totalBalanceDue > 0 ? const Color(0xFFEA580C) : AppColors.profit,
            isBold: true,
          ),
          const SizedBox(width: 1, height: 36, child: VerticalDivider()),
          _stat(
            isNetProfit ? 'Net Total Profit' : 'Net Total Loss',
            CurrencyUtils.format(totalNetPL.abs()),
            color: isNetProfit ? AppColors.profit : AppColors.loss,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationBar(
    BuildContext context,
    WidgetRef ref,
    CompletedVehiclesResult result,
    CompletedVehicleFilter filter,
  ) {
    final startIdx = result.totalCount == 0 ? 0 : (result.currentPage - 1) * result.pageSize + 1;
    final endIdx = min(result.currentPage * result.pageSize, result.totalCount);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing $startIdx - $endIdx of ${result.totalCount} records',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous Page',
                onPressed: result.hasPrevPage
                    ? () {
                        ref.read(completedVehicleFilterProvider.notifier).state =
                            filter.copyWith(page: result.currentPage - 1);
                      }
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Page ${result.currentPage} of ${result.totalPages}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryText),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next Page',
                onPressed: result.hasNextPage
                    ? () {
                        ref.read(completedVehicleFilterProvider.notifier).state =
                            filter.copyWith(page: result.currentPage + 1);
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, {Color? color, bool isBold = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color ?? AppColors.primaryText,
          ),
        ),
      ],
    );
  }
}
