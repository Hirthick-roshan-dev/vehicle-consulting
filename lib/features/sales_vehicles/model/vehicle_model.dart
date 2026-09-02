import 'payment_method.dart';
import 'vehicle_status.dart';
import 'vehicle_type.dart';

class VehicleModel {
  final int? id;
  final String vehicleNumber;
  final String vehicleName;
  final String vehicleModel;
  final VehicleType vehicleType;
  final String ownerName;
  final String ownerPhone;
  final int manufacturingYear;
  final int registrationYear;
  final String purchaseDate;
  final double purchaseAmount;
  final PaymentMethod paymentMethod;
  final String? referenceName;
  final double commissionAmount;
  final double salePrice; // Expected / Listed selling price
  final VehicleStatus status;
  final String? notes;
  final String? imagePath;
  final String createdAt;
  final String updatedAt;

  VehicleModel({
    this.id,
    required this.vehicleNumber,
    required this.vehicleName,
    required this.vehicleModel,
    required this.vehicleType,
    required this.ownerName,
    required this.ownerPhone,
    required this.manufacturingYear,
    required this.registrationYear,
    required this.purchaseDate,
    required this.purchaseAmount,
    required this.paymentMethod,
    this.referenceName,
    this.commissionAmount = 0.0,
    this.salePrice = 0.0,
    this.status = VehicleStatus.available,
    this.notes,
    this.imagePath,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VehicleModel.fromMap(Map<String, dynamic> map) {
    return VehicleModel(
      id: map['id'] as int?,
      vehicleNumber: map['vehicle_number'] as String,
      vehicleName: map['vehicle_name'] as String,
      vehicleModel: map['vehicle_model'] as String,
      vehicleType: VehicleType.fromString(map['vehicle_type'] as String),
      ownerName: map['owner_name'] as String,
      ownerPhone: map['owner_phone'] as String,
      manufacturingYear: map['manufacturing_year'] as int,
      registrationYear: map['registration_year'] as int,
      purchaseDate: map['purchase_date'] as String,
      purchaseAmount: (map['purchase_amount'] as num).toDouble(),
      paymentMethod: PaymentMethod.fromString(map['payment_method'] as String),
      referenceName: map['reference_name'] as String?,
      commissionAmount: (map['commission_amount'] as num?)?.toDouble() ?? 0.0,
      salePrice: (map['sale_price'] as num?)?.toDouble() ?? 0.0,
      status: VehicleStatus.fromString(map['status'] as String),
      notes: map['notes'] as String?,
      imagePath: map['image_path'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'vehicle_number': vehicleNumber,
      'vehicle_name': vehicleName,
      'vehicle_model': vehicleModel,
      'vehicle_type': vehicleType.code,
      'owner_name': ownerName,
      'owner_phone': ownerPhone,
      'manufacturing_year': manufacturingYear,
      'registration_year': registrationYear,
      'purchase_date': purchaseDate,
      'purchase_amount': purchaseAmount,
      'payment_method': paymentMethod.displayName,
      'reference_name': referenceName,
      'commission_amount': commissionAmount,
      'sale_price': salePrice,
      'status': status.code,
      'notes': notes,
      'image_path': imagePath,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  VehicleModel copyWith({
    int? id,
    String? vehicleNumber,
    String? vehicleName,
    String? vehicleModel,
    VehicleType? vehicleType,
    String? ownerName,
    String? ownerPhone,
    int? manufacturingYear,
    int? registrationYear,
    String? purchaseDate,
    double? purchaseAmount,
    PaymentMethod? paymentMethod,
    String? referenceName,
    double? commissionAmount,
    double? salePrice,
    VehicleStatus? status,
    String? notes,
    String? imagePath,
    bool clearImagePath = false,
    String? createdAt,
    String? updatedAt,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      vehicleName: vehicleName ?? this.vehicleName,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleType: vehicleType ?? this.vehicleType,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      manufacturingYear: manufacturingYear ?? this.manufacturingYear,
      registrationYear: registrationYear ?? this.registrationYear,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchaseAmount: purchaseAmount ?? this.purchaseAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      referenceName: referenceName ?? this.referenceName,
      commissionAmount: commissionAmount ?? this.commissionAmount,
      salePrice: salePrice ?? this.salePrice,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
