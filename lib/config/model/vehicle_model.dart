// vehicle_model.dart
class Vehicle {
  final String truckNo;
  final String make;
  final String companyOwner;
  final Map<String, Document> documents;

  Vehicle({
    required this.truckNo,
    required this.make,
    required this.companyOwner,
    required this.documents,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    Map<String, Document> docs = {};
    if (json['documents'] != null) {
      json['documents'].forEach((key, value) {
        if (value != null) {
          docs[key] = Document.fromJson(value);
        }
      });
    }

    return Vehicle(
      truckNo: json['truck_no'] ?? '', // Changed from truckNo to truck_no
      make: json['make'] ?? '',
      companyOwner: json['companyOwner'] ?? '',
      documents: docs,
    );
  }
}

class Document {
  final String? filePath;
  final String? startDate;
  final String? endDate;
  final int? daysLeft;

  Document({
    this.filePath,
    this.startDate,
    this.endDate,
    this.daysLeft,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      filePath: json['file_path'], // Changed from filePath to file_path
      startDate: json['start_date'], // Changed from startDate to start_date
      endDate: json['end_date'], // Changed from endDate to end_date
      daysLeft: json['days_left'], // Changed from daysLeft to days_left
    );
  }
}