import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../models/document_record.dart';
import '../services/database_helper.dart';
import 'vehicle_detail_screen.dart';
import 'add_vehicle_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<Map<String, dynamic>> _loadData() async {
    final db = DatabaseHelper.instance;
    final vehicles = await db.getVehicles();
    final documents = await db.getLatestDocumentsForAllVehicles();
    return {'vehicles': vehicles, 'documents': documents};
  }

  void _refresh() {
    setState(() {
      _dataFuture = _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        title: const Text('Drivora'),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF3B82F6),
        onPressed: () async {
          final added = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddVehicleScreen()),
          );
          if (added == true) _refresh();
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading data: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final vehicles = snapshot.data!['vehicles'] as List<Vehicle>;
          final documents =
              snapshot.data!['documents'] as List<DocumentRecord>;

          if (vehicles.isEmpty) {
            return const Center(
              child: Text(
                'No vehicles yet — tap + to add one',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              final vehicle = vehicles[index];
              final vehicleDocs = documents
                  .where((d) => d.vehicleId == vehicle.id)
                  .toList();

              return _VehicleCard(vehicle: vehicle, documents: vehicleDocs);
            },
          );
        },
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final List<DocumentRecord> documents;

  const _VehicleCard({required this.vehicle, required this.documents});

  Color _statusColor(int daysUntilExpiry) {
    if (daysUntilExpiry < 0) return Colors.redAccent;
    if (daysUntilExpiry <= 14) return Colors.amber;
    return Colors.greenAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E1E24),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VehicleDetailScreen(vehicle: vehicle),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${vehicle.make} ${vehicle.model}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                vehicle.plateNumber,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: documents.map((doc) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(
                        doc.daysUntilExpiry,
                      ).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _statusColor(doc.daysUntilExpiry),
                      ),
                    ),
                    child: Text(
                      doc.type.name,
                      style: TextStyle(
                        color: _statusColor(doc.daysUntilExpiry),
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}