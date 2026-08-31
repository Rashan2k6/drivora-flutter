import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../models/document_record.dart';
import '../services/database_helper.dart';
import 'vehicle_detail_screen.dart';
import 'add_vehicle_screen.dart';
import 'chatbot_entry_screen.dart';
import 'notification_center_screen.dart';

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
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 76,
        titleSpacing: 20,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/Logo_1.png',
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF3B82F6,
                          ).withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.directions_car_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Drivora',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Vehicle & Document Hub',
                  style: TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatbotEntryScreen()),
              );
            },
            tooltip: 'AI Diagnostic Assistant',
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E24),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF2F80ED).withValues(alpha: 0.35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2F80ED).withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: Color(0xFF2F80ED),
                size: 20,
              ),
            ),
          ),
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationCenterScreen()),
              );
              _refresh();
            },
            tooltip: 'Notification Center',
            icon: FutureBuilder<Map<String, dynamic>>(
              future: _dataFuture,
              builder: (context, snapshot) {
                int alertCount = 0;
                if (snapshot.hasData) {
                  final docs =
                      snapshot.data!['documents'] as List<DocumentRecord>? ?? [];
                  alertCount = docs.where((d) => d.daysUntilExpiry <= 14).length;
                }

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E24),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ),
                    if (alertCount > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            alertCount > 9 ? '9+' : '$alertCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: SizedBox(
        width: 170,
        height: 50,
        child: FloatingActionButton.extended(
          heroTag: 'addVehicleFab',
          backgroundColor: const Color(0xFF2F80ED),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          onPressed: () async {
            final added = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddVehicleScreen()),
            );
            if (added == true) _refresh();
          },
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text(
            'Add Vehicle',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        backgroundColor: const Color(0xFF1E1E24),
        color: const Color(0xFF3B82F6),
        onRefresh: () async {
          _refresh();
          await _dataFuture;
        },
        child: FutureBuilder<Map<String, dynamic>>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Text(
                        'Error loading data: ${snapshot.error}',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ),
                ],
              );
            }

            final vehicles = snapshot.data!['vehicles'] as List<Vehicle>;
            final documents = snapshot.data!['documents'] as List<DocumentRecord>;

            if (vehicles.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: const Center(
                      child: Text(
                        'No vehicles yet — tap + Add Vehicle to add one',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];
                final vehicleDocs = documents
                    .where((d) => d.vehicleId == vehicle.id)
                    .toList();

                return _VehicleCard(
                  vehicle: vehicle,
                  documents: vehicleDocs,
                  onRefresh: _refresh,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final List<DocumentRecord> documents;
  final VoidCallback onRefresh;

  const _VehicleCard({
    required this.vehicle,
    required this.documents,
    required this.onRefresh,
  });

  Color _statusColor(int daysUntilExpiry) {
    if (daysUntilExpiry < 0) {
      return const Color(0xFFEF4444); // Red: Expired
    }
    if (daysUntilExpiry <= 14) {
      return const Color(0xFFF59E0B); // Yellow: Expires Soon
    }
    return const Color(0xFF10B981); // Green: Valid
  }

  IconData _vehicleIcon(VehicleType type) {
    switch (type) {
      case VehicleType.car:
        return Icons.directions_car_outlined;
      case VehicleType.motorcycle:
        return Icons.two_wheeler_outlined;
      case VehicleType.van:
        return Icons.airport_shuttle_outlined;
      case VehicleType.threeWheeler:
        return Icons.electric_rickshaw_outlined;
      case VehicleType.truck:
        return Icons.local_shipping_outlined;
      case VehicleType.bus:
        return Icons.directions_bus_outlined;
      case VehicleType.other:
        return Icons.directions_car_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E1E24),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VehicleDetailScreen(vehicle: vehicle),
            ),
          );
          onRefresh();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.displayName,
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
                    if (documents.isNotEmpty) ...[
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
                              ).withValues(alpha: 0.15),
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
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _vehicleIcon(vehicle.type),
                  color: const Color(0xFF3B82F6),
                  size: 36,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
