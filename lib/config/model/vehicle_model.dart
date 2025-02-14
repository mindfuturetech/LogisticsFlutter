// vehicle_model.dart
class Vehicle {
  final String truckNo;
  final String make;
  final String companyOwner;
  // final Map<String, Document> documents;
  final Map<String, DocumentInfo> documents;

  Vehicle({
    required this.truckNo,
    required this.make,
    required this.companyOwner,
    required this.documents,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    // Map<String, Document> docs = {};
    // if (json['documents'] != null) {
    //   json['documents'].forEach((key, value) {
    //     if (value != null) {
    //       docs[key] = Document.fromJson(value);
    //     }
    //   });
    // }

    Map<String, DocumentInfo> docs = {
      // 'registration': DocumentInfo.fromJson(json['registration'] ?? {}),
      // 'insurance': DocumentInfo.fromJson(json['insurance'] ?? {}),
      // 'fitness': DocumentInfo.fromJson(json['fitness'] ?? {}),
      // 'mv_tax': DocumentInfo.fromJson(json['mv_tax'] ?? {}),
      // 'puc': DocumentInfo.fromJson(json['puc'] ?? {}),
      // 'ka_tax': DocumentInfo.fromJson(json['ka_tax'] ?? {}),
      // 'basic_and_KA_permit': DocumentInfo.fromJson(json['basic_and_KA_permit'] ?? {}),
    };
    if (json.containsKey('documents') && json['documents'] != null) {
      json['documents'].forEach((key, value) {
        print('📄 Document Key: $key, Value: $value'); // Debugging document data
        docs[key] = DocumentInfo.fromJson(value ?? {});  // Pass data to DocumentInfo
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

// class Document {
//   final String? filePath;
//   final String? startDate;
//   final String? endDate;
//   final int? daysLeft;
//
//   Document({
//     this.filePath,
//     this.startDate,
//     this.endDate,
//     this.daysLeft,
//   });
//
//   factory Document.fromJson(Map<String, dynamic> json) {
//     return Document(
//       filePath: json['file_path'], // Changed from filePath to file_path
//       startDate: json['start_date'], // Changed from startDate to start_date
//       endDate: json['end_date'], // Changed from endDate to end_date
//       daysLeft: json['days_left'], // Changed from daysLeft to days_left
//     );
//   }
// }

class DocumentInfo {
  final String startDate;
  final String endDate;
  final String filePath;
  final int? daysLeft;

  DocumentInfo({
    required this.startDate,
    required this.endDate,
    required this.filePath,
    this.daysLeft,
  });

  factory DocumentInfo.fromJson(Map<String, dynamic> json) {
    // print('Raw JSON for Document: $json');  // Debugging log
    // print('Extracted days_left: ${json['days_left']}');  // Debugging log
    return DocumentInfo(
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      filePath: json['file_path'] ?? '',
      // daysLeft: json['days_left'],
      daysLeft: json['days_left'] ?? 0, // Ensure days_left is parsed correctly
    );
  }
}
