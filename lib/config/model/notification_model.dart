
class DocumentNotification {
  final String truckNo;
  final String documentType;
  final String expiryDate;

  DocumentNotification({
    required this.truckNo,
    required this.documentType,
    required this.expiryDate,
  });

  factory DocumentNotification.fromJson(Map<String, dynamic> json) {
    return DocumentNotification(
      truckNo: json['truck_no'] ?? '',
      documentType: json['field_name'] ?? '',
      expiryDate: json['end_date'] ?? '',
    );
  }
}