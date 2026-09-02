enum VehicleType {
  twoWheeler('2W', 'Two Wheeler'),
  fourWheeler('4W', 'Four Wheeler');

  final String code;
  final String displayName;

  const VehicleType(this.code, this.displayName);

  static VehicleType fromString(String val) {
    if (val.toLowerCase() == '2w' || val.toLowerCase().contains('two')) {
      return VehicleType.twoWheeler;
    }
    return VehicleType.fourWheeler;
  }
}
