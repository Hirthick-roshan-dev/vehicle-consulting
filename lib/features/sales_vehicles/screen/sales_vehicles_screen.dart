import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_widget.dart';
import '../model/sale_model.dart';
import '../model/vehicle_model.dart';
import '../model/vehicle_status.dart';
import '../model/vehicle_type.dart';
import '../provider/vehicle_filter_provider.dart';
import '../provider/vehicle_provider.dart';
import 'vehicle_details_screen.dart';
import 'widgets/add_vehicle_dialog.dart';
import 'widgets/sale_form_dialog.dart';
import 'widgets/vehicle_card.dart';

class SalesVehiclesScreen extends ConsumerStatefulWidget {
  const SalesVehiclesScreen({super.key});

  @override
  ConsumerState<SalesVehiclesScreen> createState() => _SalesVehiclesScreenState();
}

class _SalesVehiclesScreenState extends ConsumerState<SalesVehiclesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final filter = ref.read(vehicleFilterProvider);
      ref.read(vehicleProvider.notifier).loadSalesVehicles(filter);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    ref.read(vehicleFilterProvider.notifier).setSearchQuery(query);
    ref.read(vehicleProvider.notifier).loadSalesVehicles(
          ref.read(vehicleFilterProvider),
          page: 1,
        );
  }

  @override
  Widget build(BuildContext context) {
    final vehicleState = ref.watch(vehicleProvider);
    final filterState = ref.watch(vehicleFilterProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar Title & Add Vehicle Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sales Vehicles Catalog',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Product card catalog view for available inventory and sales.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                AppButton(
                  text: 'Add Vehicle',
                  icon: Icons.add,
                  onPressed: () async {
                    final newVehicle = await showDialog<VehicleModel>(
                      context: context,
                      builder: (ctx) => const AddVehicleDialog(),
                    );
                    if (newVehicle != null) {
                      final success = await ref.read(vehicleProvider.notifier).addVehicle(newVehicle);
                      if (success) {
                        ref.read(vehicleProvider.notifier).loadSalesVehicles(filterState);
                      }
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Controls Bar: Search + Type Filters
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search by Vehicle No, Name, Model, or Owner...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Vehicle Type Filter Buttons
                FilterChip(
                  label: const Text('All Types'),
                  selected: filterState.typeFilter == null,
                  onSelected: (sel) {
                    ref.read(vehicleFilterProvider.notifier).setTypeFilter(null);
                    ref.read(vehicleProvider.notifier).loadSalesVehicles(
                          ref.read(vehicleFilterProvider),
                          page: 1,
                        );
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('2 Wheeler'),
                  selected: filterState.typeFilter == VehicleType.twoWheeler,
                  onSelected: (sel) {
                    ref.read(vehicleFilterProvider.notifier).setTypeFilter(VehicleType.twoWheeler);
                    ref.read(vehicleProvider.notifier).loadSalesVehicles(
                          ref.read(vehicleFilterProvider),
                          page: 1,
                        );
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('4 Wheeler'),
                  selected: filterState.typeFilter == VehicleType.fourWheeler,
                  onSelected: (sel) {
                    ref.read(vehicleFilterProvider.notifier).setTypeFilter(VehicleType.fourWheeler);
                    ref.read(vehicleProvider.notifier).loadSalesVehicles(
                          ref.read(vehicleFilterProvider),
                          page: 1,
                        );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Content Grid View / States
            Expanded(
              child: vehicleState.isLoading
                  ? const LoadingWidget(message: 'Loading vehicles...')
                  : vehicleState.errorMessage != null
                      ? Center(
                          child: Text(
                            vehicleState.errorMessage!,
                            style: const TextStyle(color: AppColors.loss),
                          ),
                        )
                      : vehicleState.vehicles.isEmpty
                          ? const EmptyState(
                              title: 'No vehicles found',
                              subtitle: 'Add a new vehicle or adjust your search filter.',
                              icon: Icons.directions_car_outlined,
                            )
                          : Column(
                              children: [
                                Expanded(
                                  child: GridView.builder(
                                    itemCount: vehicleState.vehicles.length,
                                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                      maxCrossAxisExtent: 310,
                                      mainAxisExtent: 420,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                    ),
                                    itemBuilder: (context, index) {
                                      final vehicle = vehicleState.vehicles[index];
                                      final expensesTotal = vehicleState.vehicleExpensesMap[vehicle.id] ?? 0.0;
                                      final totalCost = vehicle.purchaseAmount + vehicle.commissionAmount + expensesTotal;

                                      return VehicleCard(
                                        vehicle: vehicle,
                                        expensesTotal: expensesTotal,
                                        onView: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (ctx) => VehicleDetailsScreen(vehicleId: vehicle.id!),
                                            ),
                                          ).then((_) {
                                            ref.read(vehicleProvider.notifier).loadSalesVehicles(
                                                  ref.read(vehicleFilterProvider),
                                                );
                                          });
                                        },
                                        onEdit: () async {
                                          final updated = await showDialog<VehicleModel>(
                                            context: context,
                                            builder: (ctx) => AddVehicleDialog(vehicleToEdit: vehicle),
                                          );
                                          if (updated != null) {
                                            await ref.read(vehicleProvider.notifier).updateVehicle(updated);
                                            ref.read(vehicleProvider.notifier).loadSalesVehicles(
                                                  ref.read(vehicleFilterProvider),
                                                );
                                          }
                                        },
                                        onSell: vehicle.status == VehicleStatus.available
                                            ? () async {
                                                final result = await showDialog<SaleFormResult>(
                                                  context: context,
                                                  builder: (ctx) => SaleFormDialog(
                                                    vehicleId: vehicle.id!,
                                                    vehicleName: vehicle.vehicleName,
                                                    vehicleNumber: vehicle.vehicleNumber,
                                                    suggestedPrice: vehicle.salePrice > 0 ? vehicle.salePrice : totalCost,
                                                  ),
                                                );
                                                if (result != null) {
                                                  final now = DateTime.now().toIso8601String();
                                                  await ref.read(salesRepositoryProvider).recordSale(
                                                        sale: VehicleSaleModel(
                                                          vehicleId: vehicle.id!,
                                                          customerName: result.customerName,
                                                          customerPhone: result.customerPhone,
                                                          saleDate: result.saleDate,
                                                          paymentType: result.paymentType,
                                                          isEmi: result.isEmi,
                                                          financeName: result.financeName,
                                                          totalAmount: result.totalSaleAmount,
                                                          notes: result.notes,
                                                          createdAt: now,
                                                          updatedAt: now,
                                                        ),
                                                        advanceAmount: result.advanceAmount,
                                                        paymentMethod: result.paymentType,
                                                      );
                                                  ref.read(vehicleProvider.notifier).loadSalesVehicles(
                                                        ref.read(vehicleFilterProvider),
                                                      );
                                                }
                                              }
                                            : null,
                                        onDelete: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Delete Vehicle?'),
                                              content: Text(
                                                'Are you sure you want to delete ${vehicle.vehicleNumber}? This will also remove associated expenses, sales, and payment history.',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(ctx).pop(false),
                                                  child: const Text('Cancel'),
                                                ),
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.loss),
                                                  onPressed: () => Navigator.of(ctx).pop(true),
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            await ref.read(vehicleProvider.notifier).deleteVehicle(vehicle.id!);
                                            ref.read(vehicleProvider.notifier).loadSalesVehicles(
                                                  ref.read(vehicleFilterProvider),
                                                );
                                          }
                                        },
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Pagination Bar
                                _buildPaginationBar(context, ref, vehicleState, filterState),
                              ],
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationBar(
    BuildContext context,
    WidgetRef ref,
    VehicleState state,
    VehicleFilterState filter,
  ) {
    final startIdx = state.totalCount == 0 ? 0 : (state.currentPage - 1) * state.pageSize + 1;
    final endIdx = min(state.currentPage * state.pageSize, state.totalCount);

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
            'Showing $startIdx - $endIdx of ${state.totalCount} vehicles',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous Page',
                onPressed: state.hasPrevPage
                    ? () => ref.read(vehicleProvider.notifier).prevPage(filter)
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Page ${state.currentPage} of ${state.totalPages}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryText),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next Page',
                onPressed: state.hasNextPage
                    ? () => ref.read(vehicleProvider.notifier).nextPage(filter)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
