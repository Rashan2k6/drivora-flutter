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
    required String plateNumber,
    required this.make,
    required this.model,
    this.year,
    this.photoPath,
    this.type = VehicleType.car,
  }) : plateNumber = formatPlateNumber(plateNumber);

  String get displayName {
    final raw = '$make $model'.trim();
    if (raw.isEmpty) return '';
    return raw.split(RegExp(r'\s+')).map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }

  static String formatPlateNumber(String input) {
    final trimmed = input.trim().toUpperCase();

    // 1. If explicit hyphen or space exists: e.g. "19-5678", "300 1234", "CAB-1234"
    final explicitMatch =
        RegExp(r'^([A-Z]{2,3}|\d{2,3})[\s-]+(\d{1,4})$').firstMatch(trimmed);
    if (explicitMatch != null) {
      return '${explicitMatch.group(1)}-${explicitMatch.group(2)}';
    }

    // 2. Letters prefix without separator: e.g. "CAB1234", "WP1234"
    final letterMatch = RegExp(r'^([A-Z]{2,3})(\d{1,4})$').firstMatch(trimmed);
    if (letterMatch != null) {
      return '${letterMatch.group(1)}-${letterMatch.group(2)}';
    }

    // 3. Pure numbers without separator:
    // 6 or 5 digits: 2-digit prefix + number (e.g. "195678" -> "19-5678")
    // 7 digits: 3-digit prefix + 4-digit number (e.g. "3001234" -> "300-1234")
    final numMatch = RegExp(r'^(\d+)$').firstMatch(trimmed);
    if (numMatch != null) {
      final digits = numMatch.group(1)!;
      if (digits.length == 6 || digits.length == 5) {
        return '${digits.substring(0, 2)}-${digits.substring(2)}';
      } else if (digits.length == 7) {
        return '${digits.substring(0, 3)}-${digits.substring(3)}';
      }
    }

    return trimmed;
  }

  static bool isValidPlateNumber(String input) {
    final formatted = formatPlateNumber(input);
    return RegExp(r'^(?:[A-Z]{2,3}|\d{2,3})-\d{1,4}$').hasMatch(formatted);
  }

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
      plateNumber: map['plateNumber'] ?? '',
      make: map['make'] ?? '',
      model: map['model'] ?? '',
      year: map['year'],
      photoPath: map['photoPath'],
      type: VehicleType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => VehicleType.car,
      ),
    );
  }
}
