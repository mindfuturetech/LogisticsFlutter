class VendorModel {
  final String companyName;
  final String companyOwner;
  final double tdsRate;
  final String pan;
  final String gst;

  VendorModel({
    required this.companyName,
    required this.companyOwner,
    required this.tdsRate,
    required this.pan,
    required this.gst,
  });

  factory VendorModel.fromJson(Map<String, dynamic> json) {
    // Handle potential null values with null-aware operators and defaults
    return VendorModel(
      companyName: json['companyName']?.toString() ?? '',
      companyOwner: json['companyOwner']?.toString() ?? '',
      tdsRate: _parseDouble(json['tdsRate']) ?? 0.0,
      pan: json['pan']?.toString() ?? '',
      gst: json['gst']?.toString() ?? '',
    );
  }

  // Helper method to safely parse double values
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'companyName': companyName,
      'companyOwner': companyOwner,
      'tdsRate': tdsRate,
      'pan': pan,
      'gst': gst,
    };
  }

  @override
  String toString() {
    return 'VendorModel{companyName: $companyName, companyOwner: $companyOwner, tdsRate: $tdsRate, pan: $pan, gst: $gst}';
  }
}