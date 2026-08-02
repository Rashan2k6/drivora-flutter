import '../models/vehicle.dart';
import '../models/document_record.dart';
import '../models/service_record.dart';
import 'database_helper.dart';

class MockDataProvider {
  static List<Vehicle> getVehicles() {
    return [
      Vehicle(
        id: 'v1',
        plateNumber: 'CAB-1234',
        make: 'Toyota',
        model: 'Aqua',
        year: 2015,
      ),
      Vehicle(
        id: 'v2',
        plateNumber: 'KV-4321',
        make: 'Honda',
        model: 'Fit',
        year: 2010,
      ),
    ];
  }

  static List<DocumentRecord> getDocuments() {
    final now = DateTime.now();
    return [
      DocumentRecord(
        id: 'd1',
        vehicleId: 'v1',
        type: DocumentType.insurance,
        expiryDate: now.add(const Duration(days: 5)), // expiring soon
        policyNumber: 'INS-99213',
        issuer: 'Sri Lanka Insurance',
      ),
      DocumentRecord(
        id: 'd2',
        vehicleId: 'v1',
        type: DocumentType.revenueLicense,
        expiryDate: now.add(const Duration(days: 45)), // valid
      ),
      DocumentRecord(
        id: 'd3',
        vehicleId: 'v2',
        type: DocumentType.insurance,
        expiryDate: now.subtract(const Duration(days: 3)), // expired
        policyNumber: 'INS-44120',
        issuer: 'Ceylinco Insurance',
      ),
    ];
  }

  static List<ServiceRecord> getServiceRecords() {
    return [
      ServiceRecord(
        id: 's1',
        vehicleId: 'v1',
        date: DateTime.now().subtract(const Duration(days: 30)),
        mileage: 45000,
        description: 'Oil change and air filter replacement',
        cost: 8500,
        garageName: 'AutoCare Negombo',
      ),
      ServiceRecord(
        id: 's2',
        vehicleId: 'v2',
        date: DateTime.now().subtract(const Duration(days: 90)),
        mileage: 22000,
        description: 'Full service, brake pads replaced',
        cost: 21500,
        garageName: 'Honda Service Center',
      ),
    ];
  }

  static Future<void> seedDatabase() async {
    final db = DatabaseHelper.instance;
    for (final v in getVehicles()) {
      await db.insertVehicle(v);
    }
    for (final d in getDocuments()) {
      await db.insertDocument(d);
    }
    for (final s in getServiceRecords()) {
      await db.insertServiceRecord(s);
    }
  }
}
