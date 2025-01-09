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
      truckNo: json['truckNo'],
      make: json['make'],
      companyOwner: json['companyOwner'],
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
      filePath: json['file_path'],
      startDate: json['start_date'],
      endDate: json['end_date'],
      daysLeft: json['days_left'],
    );
  }
}