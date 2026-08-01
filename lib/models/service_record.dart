class ServiceRecord {
  final String id;
  final String vehicleId;
  final DateTime date;
  final int mileage;
  final String description;
  final double? cost;
  final String? garageName;

  ServiceRecord({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.mileage,
    required this.description,
    this.cost,
    this.garageName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'date': date.toIso8601String(),
      'mileage': mileage,
      'description': description,
      'cost': cost,
      'garageName': garageName,
    };
  }

  factory ServiceRecord.fromMap(Map<String, dynamic> map) {
    return ServiceRecord(
      id: map['id'],
      vehicleId: map['vehicleId'],
      date: DateTime.parse(map['date']),
      mileage: map['mileage'],
      description: map['description'],
      cost: map['cost'],
      garageName: map['garageName'],
    );
  }
}
