enum PaymentMethod {
  cash('Cash'),
  bankTransfer('Bank Transfer'),
  upi('UPI'),
  other('Other');

  final String displayName;

  const PaymentMethod(this.displayName);

  static PaymentMethod fromString(String val) {
    switch (val.toLowerCase().replaceAll(' ', '')) {
      case 'banktransfer':
        return PaymentMethod.bankTransfer;
      case 'upi':
        return PaymentMethod.upi;
      case 'other':
        return PaymentMethod.other;
      case 'cash':
      default:
        return PaymentMethod.cash;
    }
  }
}
