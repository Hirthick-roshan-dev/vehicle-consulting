import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../sales_vehicles/model/vehicle_status.dart';
import '../../../sales_vehicles/model/vehicle_type.dart';
import '../../provider/completed_vehicle_provider.dart';

class CompletedVehicleCard extends StatelessWidget {
  final CompletedVehicleItem item;
  final VoidCallback onView;
  final VoidCallback? onRecordPayment;

  const CompletedVehicleCard({
    super.key,
    required this.item,
    required this.onView,
    this.onRecordPayment,
  });

  @override
  Widget build(BuildContext context) {
    final vehicle = item.vehicle;
    final sale = item.sale;
    final hasImage = vehicle.imagePath != null && File(vehicle.imagePath!).existsSync();

    final isProfit = item.profitLoss >= 0;
    final plColor = isProfit ? AppColors.profit : AppColors.loss;
    final plLabel = isProfit
        ? 'Profit: +${CurrencyUtils.format(item.profitLoss)}'
        : 'Loss: -${CurrencyUtils.format(item.profitLoss.abs())}';

    Color statusColor = AppColors.profit;
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

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Banner / Photo
          Stack(
            children: [
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: hasImage
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xFF1E3A5F), Color(0xFF334155)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                ),
                child: hasImage
                    ? Image.file(
                        File(vehicle.imagePath!),
                        fit: BoxFit.cover,
                      )
                    : Center(
                        child: Icon(
                          vehicle.vehicleType == VehicleType.twoWheeler
                              ? Icons.two_wheeler
                              : Icons.directions_car,
                          size: 52,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
              ),

              // Top-Left 2W/4W Badge
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        vehicle.vehicleType == VehicleType.twoWheeler
                            ? Icons.two_wheeler
                            : Icons.directions_car,
                        size: 13,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        vehicle.vehicleType.code,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Top-Right Status Badge
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    vehicle.status.code,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Card Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              vehicle.vehicleNumber,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: plColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: plColor, width: 0.8),
                            ),
                            child: Text(
                              plLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: plColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${vehicle.vehicleName} (${vehicle.vehicleModel})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Financial Details Box
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border, width: 0.8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Sale Price:',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                            ),
                            Text(
                              CurrencyUtils.format(sale.totalAmount),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Paid Amount:',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                            ),
                            Text(
                              CurrencyUtils.format(item.totalPaid),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.profit),
                            ),
                          ],
                        ),
                        const Divider(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Balance Due:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryText),
                            ),
                            Text(
                              CurrencyUtils.format(item.balance),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: item.balance > 0 ? const Color(0xFFEA580C) : AppColors.profit,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Customer & Date Details
                  Row(
                    children: [
                      const Icon(Icons.person_pin, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${sale.customerName} (${sale.customerPhone})',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        AppDateUtils.formatDisplay(sale.saleDate),
                        style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border, width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onView,
                    icon: const Icon(Icons.visibility_outlined, size: 14),
                    label: const Text('View Breakdown', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                    ),
                  ),
                ),
                if (item.balance > 0 && onRecordPayment != null) ...[
                  const SizedBox(width: 6),
                  ElevatedButton.icon(
                    onPressed: onRecordPayment,
                    icon: const Icon(Icons.payment, size: 14),
                    label: const Text('Pay', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEA580C),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
