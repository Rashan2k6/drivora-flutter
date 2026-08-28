import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/vehicle.dart';
import '../models/document_record.dart';
import '../models/service_record.dart';

class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'drivora.db');

    return openDatabase(
      path,
      version: 2,
      onUpgrade: (db, oldVersion, newVersion) async {
        await db.execute('DROP TABLE IF EXISTS service_records');
        await db.execute('DROP TABLE IF EXISTS documents');
        await db.execute('DROP TABLE IF EXISTS vehicles');
        await _createTables(db);
      },
      onCreate: (db, version) async {
        await _createTables(db);
      },
    );
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS vehicles (
        id TEXT PRIMARY KEY,
        plateNumber TEXT NOT NULL,
        make TEXT NOT NULL,
        model TEXT NOT NULL,
        year INTEGER,
        photoPath TEXT,
        type TEXT NOT NULL DEFAULT 'car'
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS documents (
        id TEXT PRIMARY KEY,
        vehicleId TEXT NOT NULL,
        type TEXT NOT NULL,
        expiryDate TEXT NOT NULL,
        policyNumber TEXT,
        issuer TEXT,
        documentPhotoPath TEXT,
        FOREIGN KEY (vehicleId) REFERENCES vehicles (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS service_records (
        id TEXT PRIMARY KEY,
        vehicleId TEXT NOT NULL,
        date TEXT NOT NULL,
        mileage INTEGER NOT NULL,
        description TEXT NOT NULL,
        cost REAL,
        garageName TEXT,
        FOREIGN KEY (vehicleId) REFERENCES vehicles (id) ON DELETE CASCADE
      )
    ''');
  }

  // ---------- VEHICLES ----------

  Future<void> insertVehicle(Vehicle vehicle) async {
    final db = await database;
    await db.insert(
      'vehicles',
      vehicle.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Vehicle>> getVehicles() async {
    final db = await database;
    final maps = await db.query('vehicles');
    return maps.map((m) => Vehicle.fromMap(m)).toList();
  }

  Future<void> deleteVehicle(String id) async {
    final db = await database;
    await db.delete('vehicles', where: 'id = ?', whereArgs: [id]);
    // Documents and service_records auto-delete via ON DELETE CASCADE
  }

  // ---------- DOCUMENTS ----------

  Future<void> insertDocument(DocumentRecord doc) async {
    final db = await database;
    await db.insert(
      'documents',
      doc.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Returns ALL document records (full history) for a vehicle.
  Future<List<DocumentRecord>> getAllDocuments(String vehicleId) async {
    final db = await database;
    final maps = await db.query(
      'documents',
      where: 'vehicleId = ?',
      whereArgs: [vehicleId],
      orderBy: 'expiryDate DESC',
    );
    return maps.map((m) => DocumentRecord.fromMap(m)).toList();
  }

  /// Returns only the LATEST document per type for a vehicle —
  /// this is what the dashboard should use.
  Future<List<DocumentRecord>> getLatestDocumentsPerType(
    String vehicleId,
  ) async {
    final db = await database;
    final maps = await db.rawQuery(
      '''
      SELECT d.* FROM documents d
      INNER JOIN (
        SELECT type, MAX(expiryDate) AS maxExpiry
        FROM documents
        WHERE vehicleId = ?
        GROUP BY type
      ) latest
      ON d.type = latest.type AND d.expiryDate = latest.maxExpiry
      WHERE d.vehicleId = ?
    ''',
      [vehicleId, vehicleId],
    );
    return maps.map((m) => DocumentRecord.fromMap(m)).toList();
  }

  /// Same as above, but across ALL vehicles — useful for the dashboard
  /// when showing every vehicle's status in one list query instead of
  /// looping per vehicle.
  Future<List<DocumentRecord>> getLatestDocumentsForAllVehicles() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT d.* FROM documents d
      INNER JOIN (
        SELECT vehicleId, type, MAX(expiryDate) AS maxExpiry
        FROM documents
        GROUP BY vehicleId, type
      ) latest
      ON d.vehicleId = latest.vehicleId
      AND d.type = latest.type
      AND d.expiryDate = latest.maxExpiry
    ''');
    return maps.map((m) => DocumentRecord.fromMap(m)).toList();
  }

  Future<void> updateDocument(DocumentRecord doc) async {
    final db = await database;
    await db.update(
      'documents',
      doc.toMap(),
      where: 'id = ?',
      whereArgs: [doc.id],
    );
  }

  Future<void> deleteDocument(String id) async {
    final db = await database;
    await db.delete('documents', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- SERVICE RECORDS ----------

  Future<void> insertServiceRecord(ServiceRecord record) async {
    final db = await database;
    await db.insert(
      'service_records',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateServiceRecord(ServiceRecord record) async {
    final db = await database;
    await db.update(
      'service_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<List<ServiceRecord>> getServiceRecords(String vehicleId) async {
    final db = await database;
    final maps = await db.query(
      'service_records',
      where: 'vehicleId = ?',
      whereArgs: [vehicleId],
      orderBy: 'date DESC',
    );
    return maps.map((m) => ServiceRecord.fromMap(m)).toList();
  }

  Future<void> deleteServiceRecord(String id) async {
    final db = await database;
    await db.delete('service_records', where: 'id = ?', whereArgs: [id]);
  }
}
