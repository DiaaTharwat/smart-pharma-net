class PharmacyModel {
  final String id;
  final String name;
  final String city;
  final String licenseNumber;
  final double latitude;
  final double longitude;

  PharmacyModel({
    required this.id,
    required this.name,
    required this.city,
    required this.licenseNumber,
    required this.latitude,
    required this.longitude,
  });

  factory PharmacyModel.fromJson(dynamic json) {
    // Handle different numeric formats for latitude/longitude
    double parseCoordinate(dynamic value) {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return PharmacyModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      licenseNumber: json['license_number']?.toString() ?? '',
      latitude: parseCoordinate(json['latitude']),
      longitude: parseCoordinate(json['longitude']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'license_number': licenseNumber,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  @override
  String toString() {
    return 'PharmacyModel(id: $id, name: $name, city: $city, '
        'licenseNumber: $licenseNumber, latitude: $latitude, '
        'longitude: $longitude)';
  }
}