// lib/models/pharmacy_model.dart

class PharmacyModel {
  final String id;
  final String name;
  final String? city;
  final String? licenseNumber;
  final double? latitude;
  final double? longitude;
  // ✨ Fields added to resolve errors
  final int numberSells;
  final int numberBuys;

  PharmacyModel({
    required this.id,
    required this.name,
    this.city,
    this.licenseNumber,
    this.latitude,
    this.longitude,
    // ✨ Added to constructor
    required this.numberSells,
    required this.numberBuys,
  });

  factory PharmacyModel.fromJson(dynamic json) {
    // A safe-parsing function to handle various numeric types from JSON
    double? parseCoordinate(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return PharmacyModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      city: json['city']?.toString(),
      licenseNumber: json['license_number']?.toString(),
      latitude: parseCoordinate(json['latitude']),
      longitude: parseCoordinate(json['longitude']),
      // ✨ Reading the new fields from JSON with a default value of 0
      numberSells: json['number_sells'] as int? ?? 0,
      numberBuys: json['number_buys'] as int? ?? 0,
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
      // ✨ Added to JSON serialization
      'number_sells': numberSells,
      'number_buys': numberBuys,
    };
  }

  @override
  String toString() {
    return 'PharmacyModel(id: $id, name: $name, city: $city, '
        'licenseNumber: $licenseNumber, latitude: $latitude, '
        'longitude: $longitude, numberSells: $numberSells, numberBuys: $numberBuys)';
  }
}