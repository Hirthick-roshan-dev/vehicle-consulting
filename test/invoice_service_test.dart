import 'package:flutter_test/flutter_test.dart';
import 'package:vehicle_consulting/core/services/invoice_service.dart';
import 'package:vehicle_consulting/features/sales_vehicles/model/payment_method.dart';
import 'package:vehicle_consulting/features/sales_vehicles/model/sale_model.dart';
import 'package:vehicle_consulting/features/sales_vehicles/model/vehicle_model.dart';
import 'package:vehicle_consulting/features/sales_vehicles/model/vehicle_status.dart';
import 'package:vehicle_consulting/features/sales_vehicles/model/vehicle_type.dart';

void main() {
  group('InvoiceService & InvoiceData Tests', () {
    final testVehicle = VehicleModel(
      id: 101,
      vehicleNumber: 'TN 38 AB 1234',
      vehicleName: 'Hyundai Creta',
      vehicleModel: 'SX (O) Petrol',
      vehicleType: VehicleType.fourWheeler,
      ownerName: 'Previous Owner',
      ownerPhone: '9988776655',
      manufacturingYear: 2021,
      registrationYear: 2021,
      purchaseDate: '2026-08-01',
      purchaseAmount: 950000.0,
      paymentMethod: PaymentMethod.bankTransfer,
      commissionAmount: 10000.0,
      status: VehicleStatus.completed,
      createdAt: '2026-08-01T10:00:00',
      updatedAt: '2026-08-01T10:00:00',
    );

    final testSale = VehicleSaleModel(
      id: 501,
      vehicleId: 101,
      customerName: 'Anand Kumar',
      customerPhone: '9876543210',
      saleDate: '2026-09-05',
      paymentType: PaymentMethod.bankTransfer,
      isEmi: false,
      financeName: null,
      totalAmount: 1150000.0,
      documentCharges: 5000.0,
      notes: 'Clean full settlement sale',
      createdAt: '2026-09-05T11:00:00',
      updatedAt: '2026-09-05T11:00:00',
    );

    test('InvoiceData.fromVehicleAndSale correctly extracts customer info and prices', () {
      final invoiceData = InvoiceData.fromVehicleAndSale(
        vehicle: testVehicle,
        sale: testSale,
        totalPaid: 1155000.0,
        balance: 0.0,
      );

      expect(invoiceData.customerName, equals('Anand Kumar'));
      expect(invoiceData.customerPhone, equals('9876543210'));
      expect(invoiceData.vehicleNumber, equals('TN 38 AB 1234'));
      expect(invoiceData.vehicleName, equals('Hyundai Creta'));
      expect(invoiceData.salePrice, equals(1150000.0));
      expect(invoiceData.documentCharges, equals(5000.0));
      expect(invoiceData.totalAmount, equals(1155000.0));
      expect(invoiceData.totalPaid, equals(1155000.0));
      expect(invoiceData.balance, equals(0.0));
      expect(invoiceData.invoiceNumber.contains('TN38AB1234'), isTrue);
    });

    test('buildHtmlInvoice contains customer information and price breakdown', () {
      final service = InvoiceService();
      final invoiceData = InvoiceData.fromVehicleAndSale(
        vehicle: testVehicle,
        sale: testSale,
        totalPaid: 1155000.0,
        balance: 0.0,
      );

      final html = service.buildHtmlInvoice(invoiceData);

      expect(html.contains('Anand Kumar'), isTrue);
      expect(html.contains('9876543210'), isTrue);
      expect(html.contains('TN 38 AB 1234'), isTrue);
      expect(html.contains('Hyundai Creta'), isTrue);
      expect(html.contains('TAX / SALE INVOICE'), isTrue);
      expect(html.contains('COMPLETED / FULLY SETTLED'), isTrue);
      expect(html.contains('VEHICLE CONSULTING'), isTrue);
    });

    test('canGenerateInvoice returns true ONLY for completed vehicles', () {
      expect(InvoiceService.canGenerateInvoice(testVehicle), isTrue);

      final availableVehicle = testVehicle.copyWith(status: VehicleStatus.available);
      expect(InvoiceService.canGenerateInvoice(availableVehicle), isFalse);

      final partialVehicle = testVehicle.copyWith(status: VehicleStatus.partialPayment);
      expect(InvoiceService.canGenerateInvoice(partialVehicle), isFalse);
    });
  });
}
