class VehicleExpenseModel {
  final int? id;
  final int vehicleId;
  final String expenseTitle;
  final String? description;
  final double amount;
  final String expenseDate;
  final String createdAt;
  final String updatedAt;

  VehicleExpenseModel({
    this.id,
    required this.vehicleId,
    required this.expenseTitle,
    this.description,
    required this.amount,
    required this.expenseDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VehicleExpenseModel.fromMap(Map<String, dynamic> map) {
    return VehicleExpenseModel(
      id: map['id'] as int?,
      vehicleId: map['vehicle_id'] as int,
      expenseTitle: map['expense_title'] as String,
      description: map['description'] as String?,
      amount: (map['amount'] as num).toDouble(),
      expenseDate: map['expense_date'] as String,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'vehicle_id': vehicleId,
      'expense_title': expenseTitle,
      'description': description,
      'amount': amount,
      'expense_date': expenseDate,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
