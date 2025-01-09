// lib/config/model/freight_model.dart

class Freight {
  final String id;
  final String from;
  final String to;
  final double rate;

  Freight({
    required this.id,
    required this.from,
    required this.to,
    required this.rate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from': from,
      'to': to,
      'rate': rate,
    };
  }

  factory Freight.fromJson(Map<String, dynamic> json) {
    return Freight(
      id: json['id'] ?? '',
      from: json['from'] ?? '',
      to: json['to'] ?? '',
      rate: (json['rate'] ?? 0.0).toDouble(),
    );
  }
}