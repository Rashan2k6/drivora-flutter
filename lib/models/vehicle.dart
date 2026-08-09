enum VehicleType { car, motorcycle, van, threeWheeler, truck, bus, other }

class Vehicle {
  final String id;
  final String plateNumber;
  final String make;
  final String model;
  final int? year;
  final String? photoPath;
  final VehicleType type;

  Vehicle({
    required this.id,
    required this.plateNumber,
    required this.make,
    required this.model,
    this.year,
    this.photoPath,
    this.type = VehicleType.car,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plateNumber': plateNumber,
      'make': make,
      'model': model,
      'year': year,
      'photoPath': photoPath,
      'type': type.name,
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
      type: VehicleType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => VehicleType.car,
      ),
    );
  }
}
