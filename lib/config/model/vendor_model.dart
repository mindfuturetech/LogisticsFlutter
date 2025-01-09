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
    return VendorModel(
      companyName: json['companyName'],
      companyOwner: json['companyOwner'],
      tdsRate: double.parse(json['tdsRate'].toString()),
      pan: json['pan'],
      gst: json['gst'],
    );
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
}
