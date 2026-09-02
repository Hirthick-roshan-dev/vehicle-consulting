enum VehicleStatus {
  available('FOR SALE', 'Available'),
  partialPayment('PARTIAL PAYMENT', 'Partial Payment'),
  completed('COMPLETED', 'Completed');

  final String code;
  final String displayName;

  const VehicleStatus(this.code, this.displayName);

  static VehicleStatus fromString(String val) {
    switch (val.toLowerCase().replaceAll(' ', '')) {
      case 'partialpayment':
      case 'partial':
        return VehicleStatus.partialPayment;
      case 'completed':
      case 'sold':
        return VehicleStatus.completed;
      case 'forsale':
      case 'available':
      default:
        return VehicleStatus.available;
    }
  }
}
