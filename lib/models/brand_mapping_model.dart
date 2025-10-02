// file: lib/models/brand_mapping_model.dart

class BrandMapping {
  final String dealerId;
  final int brandId;
  final double capacityMT;

  BrandMapping({
    required this.dealerId,
    required this.brandId,
    required this.capacityMT,
  });

  // fromJson might not be needed if you only create, but it's good practice
  factory BrandMapping.fromJson(Map<String, dynamic> json) {
    return BrandMapping(
      dealerId: json['dealerId'],
      brandId: json['brandId'],
      capacityMT: double.parse(json['capacityMT']),
    );
  }

  Map<String, dynamic> toJson() => {
        'dealerId': dealerId,
        'brandId': brandId,
        'capacityMT': capacityMT,
      };
}