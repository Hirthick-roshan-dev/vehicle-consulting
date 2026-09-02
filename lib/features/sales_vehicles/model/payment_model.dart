import 'payment_method.dart';

class VehiclePaymentModel {
  final int? id;
  final int vehicleId;
  final int saleId;
  final double amount;
  final String paymentDate;
  final PaymentMethod paymentMethod;
  final String? notes;
  final String createdAt;

  VehiclePaymentModel({
    this.id,
    required this.vehicleId,
    required this.saleId,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    this.notes,
    required this.createdAt,
  });

  factory VehiclePaymentModel.fromMap(Map<String, dynamic> map) {
    return VehiclePaymentModel(
      id: map['id'] as int?,
      vehicleId: map['vehicle_id'] as int,
      saleId: map['sale_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      paymentDate: map['payment_date'] as String,
      paymentMethod: PaymentMethod.fromString(map['payment_method'] as String),
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'vehicle_id': vehicleId,
      'sale_id': saleId,
      'amount': amount,
      'payment_date': paymentDate,
      'payment_method': paymentMethod.displayName,
      'notes': notes,
      'created_at': createdAt,
    };
  }
}
