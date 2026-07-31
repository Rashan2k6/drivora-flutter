class Vehicle {
  final String id;
  final String plateNumber;
  final String make;
  final String model;
  final int? year;
  final String? photoPath; // local file path or asset path

  Vehicle({
    required this.id,
    required this.plateNumber,
    required this.make,
    required this.model,
    this.year,
    this.photoPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plateNumber': plateNumber,
      'make': make,
      'model': model,
      'year': year,
      'photoPath': photoPath,
    };
  }

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'],
      plateNumber: map['plateNumber'],
      make: map['make'],
      model: map['model'],
      year: map['year'],
      photoPath: map['photoPath'],
    );
  }
}
