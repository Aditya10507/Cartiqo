class MallBillingSettings {
  final double gstPercent;
  final String taxLabel;
  final double taxPercent;
  final String extraChargeLabel;
  final double extraChargeAmount;

  const MallBillingSettings({
    this.gstPercent = 0,
    this.taxLabel = 'Tax',
    this.taxPercent = 0,
    this.extraChargeLabel = 'Extra Charges',
    this.extraChargeAmount = 0,
  });

  bool get hasGst => gstPercent > 0;
  bool get hasTax => taxPercent > 0;
  bool get hasExtraCharge => extraChargeAmount > 0;

  Map<String, dynamic> toMap() {
    return {
      'gstPercent': gstPercent,
      'taxLabel': taxLabel,
      'taxPercent': taxPercent,
      'extraChargeLabel': extraChargeLabel,
      'extraChargeAmount': extraChargeAmount,
    };
  }

  factory MallBillingSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const MallBillingSettings();
    }

    return MallBillingSettings(
      gstPercent: _toDouble(map['gstPercent']),
      taxLabel: (map['taxLabel'] ?? 'Tax').toString(),
      taxPercent: _toDouble(map['taxPercent']),
      extraChargeLabel: (map['extraChargeLabel'] ?? 'Extra Charges').toString(),
      extraChargeAmount: _toDouble(map['extraChargeAmount']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
