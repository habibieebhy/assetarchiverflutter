// file: lib/models/brand_model.dart


class Brand {
  final int id; // Assuming 'id' is an auto-incrementing integer
  final String name;

  Brand({required this.id, required this.name});

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(id: json['id'], name: json['name']);
  }

  Map<String, dynamic> toJson() => {'name': name};
}