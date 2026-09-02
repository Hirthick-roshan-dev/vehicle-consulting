import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/loading_widget.dart';
import '../model/expense_model.dart';
import '../model/payment_model.dart';
import '../model/sale_model.dart';
import '../model/vehicle_model.dart';
import '../model/vehicle_status.dart';
import '../model/vehicle_type.dart';
import '../provider/vehicle_details_provider.dart';
import '../provider/vehicle_filter_provider.dart';
import '../provider/vehicle_provider.dart';
import '../../completed_vehicles/provider/completed_vehicle_provider.dart';
import 'widgets/add_expense_dialog.dart';
import 'widgets/add_payment_dialog.dart';
import 'widgets/add_vehicle_dialog.dart';
import 'widgets/sale_form_dialog.dart';

class VehicleDetailsScreen extends ConsumerWidget {
  final int vehicleId;

  const VehicleDetailsScreen({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(vehicleDetailsProvider(vehicleId));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Vehicle Details',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: detailsAsync.when(
        loading: () =>
            const LoadingWidget(message: 'Loading vehicle details...'),
        error: (err, stack) => Center(
          child: Text(
            'Error loading vehicle: $err',
            style: const TextStyle(color: AppColors.loss),
          ),
        ),
        data: (data) {
          if (data == null) {
            return const Center(child: Text('Vehicle not found.'));
          }

          final vehicle = data.vehicle;
          final expenses = data.expenses;
          final sale = data.sale;
          final payments = data.payments;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Card with Perfect Square Image on Left
                _buildHeaderCard(context, ref, vehicle, data),
                const SizedBox(height: 24),

                // Financial Overview Bar with Commission Included
                _buildFinancialOverviewBar(data),
                const SizedBox(height: 24),

                // Two Column Layout
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Column 1: Info & Expenses
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildVehicleInformationCard(vehicle),
                          const SizedBox(height: 20),
                          _buildExpensesCard(context, ref, vehicle, expenses),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Column 2: Sales & Payments
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSalesInformationCard(
                            context,
                            ref,
                            vehicle,
                            sale,
                            payments,
                            data,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(
    BuildContext context,
    WidgetRef ref,
    VehicleModel vehicle,
    VehicleDetailsData data,
  ) {
    Color statusColor;
    switch (vehicle.status) {
      case VehicleStatus.available:
        statusColor = AppColors.primary;
        break;
      case VehicleStatus.partialPayment:
        statusColor = const Color(0xFFEA580C);
        break;
      case VehicleStatus.completed:
        statusColor = AppColors.profit;
        break;
    }

    final hasImage =
        vehicle.imagePath != null && File(vehicle.imagePath!).existsSync();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                // Perfect Square Photo on Left Side
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: hasImage
                      ? Image.file(
                          File(vehicle.imagePath!),
                          fit: BoxFit.cover,
                          width: 130,
                          height: 130,
                        )
                      : Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF1E3A5F), Color(0xFF334155)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              vehicle.vehicleType == VehicleType.twoWheeler
                                  ? Icons.two_wheeler
                                  : Icons.directions_car,
                              size: 48,
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 20),

                // Vehicle Details Text Block
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Text(
                            vehicle.vehicleNumber,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryText,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: statusColor,
                                width: 1.2,
                              ),
                            ),
                            child: Text(
                              vehicle.status.displayName.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${vehicle.vehicleName} (${vehicle.vehicleModel}) • ${vehicle.vehicleType.displayName}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 15,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Owner: ${vehicle.ownerName} (${vehicle.ownerPhone})',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Reg: ${vehicle.registrationYear} | Mfg: ${vehicle.manufacturingYear}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Actions on the Far Right: Edit Vehicle / Record Sale
          Row(
            children: [
              AppButton(
                text: 'Edit Vehicle',
                icon: Icons.edit_outlined,
                isSecondary: true,
                onPressed: () async {
                  final updated = await showDialog<VehicleModel>(
                    context: context,
                    builder: (ctx) => AddVehicleDialog(vehicleToEdit: vehicle),
                  );
                  if (updated != null) {
                    await ref
                        .read(vehicleProvider.notifier)
                        .updateVehicle(updated);
                    ref.invalidate(vehicleDetailsProvider(vehicle.id!));
                    ref
                        .read(vehicleProvider.notifier)
                        .loadSalesVehicles(ref.read(vehicleFilterProvider));
                  }
                },
              ),
              const SizedBox(width: 10),
              if (vehicle.status == VehicleStatus.available)
                AppButton(
                  text: 'Sell / Complete',
                  icon: Icons.point_of_sale,
                  color: AppColors.profit,
                  onPressed: () async {
                    final result = await showDialog<SaleFormResult>(
                      context: context,
                      builder: (ctx) => SaleFormDialog(
                        vehicleId: vehicle.id!,
                        vehicleName: vehicle.vehicleName,
                        vehicleNumber: vehicle.vehicleNumber,
                        suggestedPrice: vehicle.salePrice > 0
                            ? vehicle.salePrice
                            : data.totalCost,
                      ),
                    );
                    if (result != null) {
                      final now = DateTime.now().toIso8601String();
                      final saleModel = VehicleSaleModel(
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
                      );

                      await ref
                          .read(salesRepositoryProvider)
                          .recordSale(
                            sale: saleModel,
                            advanceAmount: result.advanceAmount,
                            paymentMethod: result.paymentType,
                          );

                      ref.invalidate(vehicleDetailsProvider(vehicle.id!));
                      ref
                          .read(vehicleProvider.notifier)
                          .loadSalesVehicles(ref.read(vehicleFilterProvider));
                    }
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialOverviewBar(VehicleDetailsData data) {
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
          // Purchase Price in Warm Amber / Yellow
          _buildStatItem(
            'Purchase Price',
            CurrencyUtils.format(data.vehicle.purchaseAmount),
            valueColor: const Color(0xFFD97706),
            isBold: true,
          ),
          if (data.vehicle.commissionAmount > 0) ...[
            const SizedBox(width: 1, height: 36, child: VerticalDivider()),
            _buildStatItem(
              'Commission',
              CurrencyUtils.format(data.vehicle.commissionAmount),
              valueColor: const Color(0xFF7C3AED),
              isBold: true,
            ),
          ],
          const SizedBox(width: 1, height: 36, child: VerticalDivider()),
          // Total Expenses in Red
          _buildStatItem(
            'Total Expenses',
            CurrencyUtils.format(data.totalExpenses),
            valueColor: AppColors.loss,
            isBold: true,
          ),
          const SizedBox(width: 1, height: 36, child: VerticalDivider()),
          // Total Cost in Deep Blue
          _buildStatItem(
            'Total Cost',
            CurrencyUtils.format(data.totalCost),
            valueColor: AppColors.primary,
            isBold: true,
          ),
          if (data.vehicle.salePrice > 0 && data.sale == null) ...[
            const SizedBox(width: 1, height: 36, child: VerticalDivider()),
            // Target Selling Price in Green
            _buildStatItem(
              'Target Sale Price',
              CurrencyUtils.format(data.vehicle.salePrice),
              valueColor: const Color(0xFF059669),
              isBold: true,
            ),
          ],
          if (data.sale != null) ...[
            const SizedBox(width: 1, height: 36, child: VerticalDivider()),
            // Sale Amount in Green
            _buildStatItem(
              'Sale Amount',
              CurrencyUtils.format(data.sale!.totalAmount),
              valueColor: const Color(0xFF059669),
              isBold: true,
            ),
            const SizedBox(width: 1, height: 36, child: VerticalDivider()),
            // Total Paid in Green
            _buildStatItem(
              'Total Paid',
              CurrencyUtils.format(data.totalPaid),
              valueColor: AppColors.profit,
              isBold: true,
            ),
            const SizedBox(width: 1, height: 36, child: VerticalDivider()),
            // Balance Due in Warning Orange
            _buildStatItem(
              'Balance Due',
              CurrencyUtils.format(data.balance),
              valueColor: data.balance > 0
                  ? const Color(0xFFEA580C)
                  : AppColors.profit,
              isBold: true,
            ),
            const SizedBox(width: 1, height: 36, child: VerticalDivider()),
            _buildStatItem(
              data.profitLoss >= 0 ? 'Net Profit' : 'Net Loss',
              CurrencyUtils.format(data.profitLoss.abs()),
              valueColor: data.profitLoss >= 0
                  ? AppColors.profit
                  : AppColors.loss,
              isBold: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? AppColors.primaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleInformationCard(VehicleModel vehicle) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vehicle & Owner Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const Divider(height: 24),
            _infoRow('Owner Name', vehicle.ownerName),
            _infoRow('Owner Mobile', vehicle.ownerPhone),
            _infoRow(
              'Manufacturing Year',
              vehicle.manufacturingYear.toString(),
            ),
            _infoRow('Registration Year', vehicle.registrationYear.toString()),
            _infoRow(
              'Purchase Date',
              AppDateUtils.formatDisplay(vehicle.purchaseDate),
            ),
            _infoRow('Payment Method', vehicle.paymentMethod.displayName),
            if (vehicle.referenceName != null)
              _infoRow('Reference / Broker', vehicle.referenceName!),
            if (vehicle.commissionAmount > 0)
              _infoRow(
                'Commission Amount',
                CurrencyUtils.format(vehicle.commissionAmount),
                valueColor: const Color(0xFF7C3AED),
              ),
            if (vehicle.salePrice > 0)
              _infoRow(
                'Target Selling Price',
                CurrencyUtils.format(vehicle.salePrice),
                valueColor: const Color(0xFF059669),
              ),
            if (vehicle.notes != null)
              _infoRow('Remarks & Notes', vehicle.notes!),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: valueColor ?? AppColors.primaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesCard(
    BuildContext context,
    WidgetRef ref,
    VehicleModel vehicle,
    List<VehicleExpenseModel> expenses,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Expenses Breakdown',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                AppButton(
                  text: 'Add Expense',
                  icon: Icons.add,
                  onPressed: () async {
                    final expense = await showDialog<VehicleExpenseModel>(
                      context: context,
                      builder: (ctx) =>
                          AddExpenseDialog(vehicleId: vehicle.id!),
                    );
                    if (expense != null) {
                      await ref
                          .read(expenseRepositoryProvider)
                          .addExpense(expense);
                      ref.invalidate(vehicleDetailsProvider(vehicle.id!));
                    }
                  },
                ),
              ],
            ),
            const Divider(height: 24),
            if (expenses.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'No expenses recorded for this vehicle.',
                    style: TextStyle(
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: expenses.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1),
                itemBuilder: (ctx, index) {
                  final e = expenses[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      e.expenseTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      AppDateUtils.formatDisplay(e.expenseDate) +
                          (e.description != null ? ' • ${e.description}' : ''),
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 12,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          CurrencyUtils.format(e.amount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.loss,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: 'Edit Expense',
                          onPressed: () async {
                            final updated =
                                await showDialog<VehicleExpenseModel>(
                                  context: context,
                                  builder: (ctx) => AddExpenseDialog(
                                    vehicleId: vehicle.id!,
                                    expenseToEdit: e,
                                  ),
                                );
                            if (updated != null) {
                              await ref
                                  .read(expenseRepositoryProvider)
                                  .updateExpense(updated);
                              ref.invalidate(
                                vehicleDetailsProvider(vehicle.id!),
                              );
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: AppColors.loss,
                          ),
                          tooltip: 'Delete Expense',
                          onPressed: () async {
                            await ref
                                .read(expenseRepositoryProvider)
                                .deleteExpense(e.id!);
                            ref.invalidate(vehicleDetailsProvider(vehicle.id!));
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesInformationCard(
    BuildContext context,
    WidgetRef ref,
    VehicleModel vehicle,
    VehicleSaleModel? sale,
    List<VehiclePaymentModel> payments,
    VehicleDetailsData data,
  ) {
    if (sale == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Icon(
                Icons.info_outline,
                size: 48,
                color: AppColors.primary,
              ),
              const SizedBox(height: 12),
              const Text(
                'Vehicle is Currently Available for Sale',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Click "Sell / Complete" at the top to record customer sale information and initial advance payment.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sales & Payment Records',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Row(
                  children: [
                    // Option to Edit Sales Information
                    AppButton(
                      text: 'Edit',
                      icon: Icons.edit_note,
                      isSecondary: true,
                      onPressed: () async {
                        final result = await showDialog<SaleFormResult>(
                          context: context,
                          builder: (ctx) => SaleFormDialog(
                            vehicleId: vehicle.id!,
                            vehicleName: vehicle.vehicleName,
                            vehicleNumber: vehicle.vehicleNumber,
                            suggestedPrice: data.totalCost,
                            saleToEdit: sale,
                          ),
                        );
                        if (result != null) {
                          final updatedSale = VehicleSaleModel(
                            id: sale.id,
                            vehicleId: vehicle.id!,
                            customerName: result.customerName,
                            customerPhone: result.customerPhone,
                            saleDate: result.saleDate,
                            paymentType: result.paymentType,
                            isEmi: result.isEmi,
                            financeName: result.financeName,
                            totalAmount: result.totalSaleAmount,
                            notes: result.notes,
                            createdAt: sale.createdAt,
                            updatedAt: DateTime.now().toIso8601String(),
                          );
                          await ref
                              .read(salesRepositoryProvider)
                              .updateSale(sale: updatedSale);
                          ref.invalidate(vehicleDetailsProvider(vehicle.id!));
                          ref
                              .read(vehicleProvider.notifier)
                              .loadSalesVehicles(
                                ref.read(vehicleFilterProvider),
                              );
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    // Option to Delete / Cancel Sale & Restore to Sales Catalog
                    Tooltip(
                      message:
                          'Cancel / Delete Sale & Restore to Sales Catalog',
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.loss,
                          side: const BorderSide(color: AppColors.loss),
                        ),
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: AppColors.loss,
                        ),
                        label: const Text('Delete'),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Cancel / Delete Sale?'),
                              content: Text(
                                'Are you sure you want to delete the sale record for ${vehicle.vehicleNumber}? '
                                'This will clear all payment history and restore the vehicle back to "FOR SALE" status in the sales catalog.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.loss,
                                  ),
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: const Text('Delete Sale & Restore'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await ref
                                .read(salesRepositoryProvider)
                                .deleteSale(vehicleId: vehicle.id!);
                            ref.invalidate(vehicleDetailsProvider(vehicle.id!));
                            ref
                                .read(vehicleProvider.notifier)
                                .loadSalesVehicles(
                                  ref.read(vehicleFilterProvider),
                                );
                            ref.invalidate(completedVehiclesProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Sale removed. Vehicle restored to Sales Catalog!',
                                  ),
                                  backgroundColor: AppColors.profit,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                    if (data.balance > 0) ...[
                      const SizedBox(width: 8),
                      AppButton(
                        text: 'Pay',
                        icon: Icons.payment,
                        color: const Color(0xFFEA580C),
                        onPressed: () async {
                          final payment = await showDialog<VehiclePaymentModel>(
                            context: context,
                            builder: (ctx) => AddPaymentDialog(
                              vehicleId: vehicle.id!,
                              saleId: sale.id!,
                              currentBalance: data.balance,
                            ),
                          );
                          if (payment != null) {
                            await ref
                                .read(salesRepositoryProvider)
                                .addPayment(
                                  payment: payment,
                                  totalSaleAmount: sale.totalAmount,
                                );
                            ref.invalidate(vehicleDetailsProvider(vehicle.id!));
                            ref
                                .read(vehicleProvider.notifier)
                                .loadSalesVehicles(
                                  ref.read(vehicleFilterProvider),
                                );
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            _infoRow('Customer Name', sale.customerName),
            _infoRow('Customer Mobile', sale.customerPhone),
            _infoRow('Sale Date', AppDateUtils.formatDisplay(sale.saleDate)),
            _infoRow('Payment Type', sale.paymentType.displayName),
            _infoRow(
              'Sold via EMI / Finance',
              sale.isEmi ? 'Yes (${sale.financeName ?? '-'})' : 'No',
            ),
            _infoRow(
              'Total Sale Price',
              CurrencyUtils.format(sale.totalAmount),
              valueColor: const Color(0xFF059669),
            ),
            _infoRow(
              'Total Paid So Far',
              CurrencyUtils.format(data.totalPaid),
              valueColor: AppColors.profit,
            ),
            _infoRow(
              'Balance Due',
              CurrencyUtils.format(data.balance),
              valueColor: data.balance > 0
                  ? const Color(0xFFEA580C)
                  : AppColors.profit,
            ),
            if (sale.notes != null && sale.notes!.isNotEmpty)
              _infoRow('Sale Notes / Remarks', sale.notes!),
            const SizedBox(height: 20),
            const Text(
              'Payment History',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            if (payments.isEmpty)
              const Text(
                'No payment entries recorded yet.',
                style: TextStyle(
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w500,
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: payments.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1),
                itemBuilder: (ctx, index) {
                  final p = payments[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Payment #${payments.length - index} (${p.paymentMethod.displayName})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      'Date: ${AppDateUtils.formatDisplay(p.paymentDate)}${p.notes != null ? ' • ${p.notes}' : ''}',
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 12,
                      ),
                    ),
                    trailing: Text(
                      CurrencyUtils.format(p.amount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.profit,
                        fontSize: 14,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
