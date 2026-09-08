import 'package:flutter_test/flutter_test.dart';
import 'package:vehicle_consulting/features/reports/model/report_models.dart';
import 'package:vehicle_consulting/features/sales_vehicles/model/expense_model.dart';
import 'package:vehicle_consulting/features/sales_vehicles/model/payment_method.dart';
import 'package:vehicle_consulting/features/sales_vehicles/model/payment_model.dart';
import 'package:vehicle_consulting/features/sales_vehicles/model/sale_model.dart';
import 'package:vehicle_consulting/features/sales_vehicles/model/vehicle_model.dart';
import 'package:vehicle_consulting/features/sales_vehicles/model/vehicle_status.dart';
import 'package:vehicle_consulting/features/sales_vehicles/model/vehicle_type.dart';

void main() {
  group('Reports Module - Stock and Profit Analytics Tests', () {
    test('StockReportItem computes total invested and expenses correctly', () {
      final vehicle = VehicleModel(
        id: 1,
        vehicleNumber: 'TN38AB1234',
        vehicleName: 'Hyundai i20',
        vehicleModel: 'Asta',
        vehicleType: VehicleType.fourWheeler,
        ownerName: 'Ravi',
        ownerPhone: '9876543210',
        manufacturingYear: 2019,
        registrationYear: 2019,
        purchaseDate: '2026-08-01',
        purchaseAmount: 450000.0,
        paymentMethod: PaymentMethod.cash,
        commissionAmount: 5000.0,
        status: VehicleStatus.available,
        createdAt: '2026-08-01T10:00:00',
        updatedAt: '2026-08-01T10:00:00',
      );

      final expenses = [
        VehicleExpenseModel(
          id: 1,
          vehicleId: 1,
          expenseTitle: 'Teflon Coating',
          amount: 5000.0,
          expenseDate: '2026-08-02',
          createdAt: '2026-08-02T10:00:00',
          updatedAt: '2026-08-02T10:00:00',
        ),
        VehicleExpenseModel(
          id: 2,
          vehicleId: 1,
          expenseTitle: 'Battery Replacement',
          amount: 5000.0,
          expenseDate: '2026-08-03',
          createdAt: '2026-08-03T10:00:00',
          updatedAt: '2026-08-03T10:00:00',
        ),
      ];

      final stockItem = StockReportItem(vehicle: vehicle, expenses: expenses);

      expect(stockItem.totalExpenses, 10000.0);
      expect(stockItem.totalInvested, 465000.0); // 450000 + 5000 comm + 10000 exp
    });

    test('StockSummary aggregates 2W, 4W counts and financial totals correctly', () {
      final v1 = VehicleModel(
        id: 1,
        vehicleNumber: 'TN38AB1234',
        vehicleName: 'Hyundai i20',
        vehicleModel: 'Asta',
        vehicleType: VehicleType.fourWheeler,
        ownerName: 'Ravi',
        ownerPhone: '9876543210',
        manufacturingYear: 2019,
        registrationYear: 2019,
        purchaseDate: '2026-08-01',
        purchaseAmount: 400000.0,
        paymentMethod: PaymentMethod.cash,
        commissionAmount: 5000.0,
        status: VehicleStatus.available,
        createdAt: '2026-08-01T10:00:00',
        updatedAt: '2026-08-01T10:00:00',
      );

      final v2 = VehicleModel(
        id: 2,
        vehicleNumber: 'TN38XY9999',
        vehicleName: 'Royal Enfield Classic 350',
        vehicleModel: 'Gunmetal Grey',
        vehicleType: VehicleType.twoWheeler,
        ownerName: 'Kumar',
        ownerPhone: '9876543211',
        manufacturingYear: 2021,
        registrationYear: 2021,
        purchaseDate: '2026-08-10',
        purchaseAmount: 140000.0,
        paymentMethod: PaymentMethod.bankTransfer,
        commissionAmount: 2000.0,
        status: VehicleStatus.available,
        createdAt: '2026-08-10T10:00:00',
        updatedAt: '2026-08-10T10:00:00',
      );

      final item1 = StockReportItem(vehicle: v1, expenses: []);
      final item2 = StockReportItem(vehicle: v2, expenses: []);

      final summary = StockSummary.fromItems([item1, item2]);

      expect(summary.totalCount, 2);
      expect(summary.fourWheelerCount, 1);
      expect(summary.twoWheelerCount, 1);
      expect(summary.totalInvested, 547000.0); // 405000 + 142000
    });

    test('SalesReportItem and ProfitSummary calculate net profit, margins and receivables correctly', () {
      final vehicle = VehicleModel(
        id: 10,
        vehicleNumber: 'TN38ZZ1111',
        vehicleName: 'Maruti Swift',
        vehicleModel: 'VXI',
        vehicleType: VehicleType.fourWheeler,
        ownerName: 'Suresh',
        ownerPhone: '9876543210',
        manufacturingYear: 2020,
        registrationYear: 2020,
        purchaseDate: '2026-07-01',
        purchaseAmount: 500000.0,
        paymentMethod: PaymentMethod.cash,
        commissionAmount: 5000.0,
        status: VehicleStatus.completed,
        createdAt: '2026-07-01T10:00:00',
        updatedAt: '2026-07-01T10:00:00',
      );

      final sale = VehicleSaleModel(
        id: 1,
        vehicleId: 10,
        customerName: 'Anand',
        customerPhone: '9123456780',
        saleDate: '2026-08-15',
        paymentType: PaymentMethod.cash,
        isEmi: false,
        totalAmount: 580000.0,
        createdAt: '2026-08-15T12:00:00',
        updatedAt: '2026-08-15T12:00:00',
      );

      final payments = [
        VehiclePaymentModel(
          id: 1,
          vehicleId: 10,
          saleId: 1,
          amount: 580000.0,
          paymentDate: '2026-08-15',
          paymentMethod: PaymentMethod.cash,
          createdAt: '2026-08-15T12:00:00',
        ),
      ];

      final expenses = [
        VehicleExpenseModel(
          id: 1,
          vehicleId: 10,
          expenseTitle: 'General Service',
          amount: 10000.0,
          expenseDate: '2026-07-10',
          createdAt: '2026-07-10T10:00:00',
          updatedAt: '2026-07-10T10:00:00',
        ),
      ];

      final salesItem = SalesReportItem(
        vehicle: vehicle,
        sale: sale,
        payments: payments,
        expenses: expenses,
      );

      // Cost = 500000 + 5000 + 10000 = 515000
      // Sale = 580000
      // Profit = 65000
      expect(salesItem.totalCost, 515000.0);
      expect(salesItem.profitLoss, 65000.0);
      expect(salesItem.balance, 0.0);

      final profitSummary = ProfitSummary.fromItems([salesItem]);
      expect(profitSummary.totalVehiclesSold, 1);
      expect(profitSummary.totalRevenue, 580000.0);
      expect(profitSummary.totalCost, 515000.0);
      expect(profitSummary.totalProfitLoss, 65000.0);
      expect(profitSummary.totalCollected, 580000.0);
      expect(profitSummary.totalPendingReceivable, 0.0);
    });

    test('VehicleSaleModel serializes documentCharges correctly', () {
      final sale = VehicleSaleModel(
        id: 2,
        vehicleId: 20,
        customerName: 'Karthik',
        customerPhone: '9876543210',
        saleDate: '2026-09-01',
        paymentType: PaymentMethod.cash,
        isEmi: false,
        totalAmount: 300000.0,
        documentCharges: 4500.0,
        createdAt: '2026-09-01T10:00:00',
        updatedAt: '2026-09-01T10:00:00',
      );

      final map = sale.toMap();
      expect(map['document_charges'], 4500.0);

      final deserialized = VehicleSaleModel.fromMap(map);
      expect(deserialized.documentCharges, 4500.0);
      expect(deserialized.totalAmount, 300000.0);

      // Default when missing
      final defaultSale = VehicleSaleModel.fromMap({
        'id': 3,
        'vehicle_id': 21,
        'customer_name': 'Ramesh',
        'customer_phone': '9876543211',
        'sale_date': '2026-09-02',
        'payment_type': 'Cash',
        'is_emi': 0,
        'total_amount': 250000.0,
        'created_at': '2026-09-02T10:00:00',
        'updated_at': '2026-09-02T10:00:00',
      });
      expect(defaultSale.documentCharges, 0.0);
    });
  });
}
