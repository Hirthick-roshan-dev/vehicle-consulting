class BusinessProfileModel {
  final int id;
  final String businessName;
  final String address;
  final String phone;
  final String? email;
  final String? gstNumber;
  final String updatedAt;

  BusinessProfileModel({
    required this.id,
    required this.businessName,
    required this.address,
    required this.phone,
    this.email,
    this.gstNumber,
    required this.updatedAt,
  });

  factory BusinessProfileModel.fromMap(Map<String, dynamic> map) {
    return BusinessProfileModel(
      id: map['id'] as int,
      businessName: map['business_name'] as String,
      address: map['address'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String?,
      gstNumber: map['gst_number'] as String?,
      updatedAt: map['updated_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_name': businessName,
      'address': address,
      'phone': phone,
      'email': email,
      'gst_number': gstNumber,
      'updated_at': updatedAt,
    };
  }
}
