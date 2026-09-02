import 'payment_method.dart';

class VehicleSaleModel {
  final int? id;
  final int vehicleId;
  final String customerName;
  final String customerPhone;
  final String saleDate;
  final PaymentMethod paymentType;
  final bool isEmi;
  final String? financeName;
  final double totalAmount;
  final String? notes;
  final String createdAt;
  final String updatedAt;

  VehicleSaleModel({
    this.id,
    required this.vehicleId,
    required this.customerName,
    required this.customerPhone,
    required this.saleDate,
    required this.paymentType,
    required this.isEmi,
    this.financeName,
    required this.totalAmount,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VehicleSaleModel.fromMap(Map<String, dynamic> map) {
    return VehicleSaleModel(
      id: map['id'] as int?,
      vehicleId: map['vehicle_id'] as int,
      customerName: map['customer_name'] as String,
      customerPhone: map['customer_phone'] as String,
      saleDate: map['sale_date'] as String,
      paymentType: PaymentMethod.fromString(map['payment_type'] as String),
      isEmi: (map['is_emi'] as int) == 1,
      financeName: map['finance_name'] as String?,
      totalAmount: (map['total_amount'] as num).toDouble(),
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'vehicle_id': vehicleId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'sale_date': saleDate,
      'payment_type': paymentType.displayName,
      'is_emi': isEmi ? 1 : 0,
      'finance_name': financeName,
      'total_amount': totalAmount,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
