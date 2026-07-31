enum DocumentType { insurance, license, revenueLicense, emissionTest }

class DocumentRecord {
  final String id;
  final String vehicleId;
  final DocumentType type;
  final DateTime expiryDate;
  final String? policyNumber; // relevant for insurance
  final String? issuer; // e.g. insurer name
  final String? documentPhotoPath; // scanned image, if saved

  DocumentRecord({
    required this.id,
    required this.vehicleId,
    required this.type,
    required this.expiryDate,
    this.policyNumber,
    this.issuer,
    this.documentPhotoPath,
  });

  //how many days left until expiry
  int get daysUntilExpiry => expiryDate.difference(DateTime.now()).inDays;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'type': type.name,
      'expiryDate': expiryDate.toIso8601String(),
      'policyNumber': policyNumber,
      'issuer': issuer,
      'documentPhotoPath': documentPhotoPath,
    };
  }

  factory DocumentRecord.fromMap(Map<String, dynamic> map) {
    return DocumentRecord(
      id: map['id'],
      vehicleId: map['vehicleId'],
      type: DocumentType.values.byName(map['type']),
      expiryDate: DateTime.parse(map['expiryDate']),
      policyNumber: map['policyNumber'],
      issuer: map['issuer'],
      documentPhotoPath: map['documentPhotoPath'],
    );
  }
}
