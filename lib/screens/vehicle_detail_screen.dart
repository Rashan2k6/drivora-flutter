import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../services/database_helper.dart';
import 'add_document_screen.dart';
import '../models/document_record.dart';
import '../models/service_record.dart';

String _documentTypeLabel(DocumentType type) {
  switch (type) {
    case DocumentType.insurance:
      return 'Insurance';
    case DocumentType.license:
      return 'Driving License';
    case DocumentType.revenueLicense:
      return 'Revenue License';
    case DocumentType.emissionTest:
      return 'Emission Test';
  }
}

class VehicleDetailScreen extends StatefulWidget {
  final Vehicle vehicle;

  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  late Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<Map<String, dynamic>> _loadData() async {
    final db = DatabaseHelper.instance;
    final documents = await db.getAllDocuments(widget.vehicle.id);
    final services = await db.getServiceRecords(widget.vehicle.id);
    return {'documents': documents, 'services': services};
  }

  void _refresh() {
    setState(() {
      _dataFuture = _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: const Color(0xFF121212),
          title: Text('${widget.vehicle.make} ${widget.vehicle.model}'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Documents'),
              Tab(text: 'Service History'),
            ],
          ),
        ),
        floatingActionButton: Builder(
          builder: (context) {
            final tabController = DefaultTabController.of(context);
            return AnimatedBuilder(
              animation: tabController,
              builder: (context, _) {
                // Only show "Add Document" FAB on the Documents tab (index 0)
                if (tabController.index != 0) {
                  return const SizedBox.shrink();
                }
                return FloatingActionButton(
                  backgroundColor: const Color(0xFF3B82F6),
                  onPressed: () async {
                    final added = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AddDocumentScreen(vehicleId: widget.vehicle.id),
                      ),
                    );
                    if (added == true) _refresh();
                  },
                  child: const Icon(Icons.add),
                );
              },
            );
          },
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
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              );
            }

            final documents = snapshot.data!['documents'] as List<DocumentRecord>;
            final services = snapshot.data!['services'] as List<ServiceRecord>;

            return TabBarView(
              children: [
                documents.isEmpty
                    ? const Center(
                        child: Text(
                          'No documents yet — tap + to add one',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: documents.map((doc) {
                          return Card(
                            color: const Color(0xFF1E1E24),
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              title: Text(
                                _documentTypeLabel(doc.type as DocumentType),
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                'Expires: ${doc.expiryDate.toLocal()}'
                                    .split(' ')[0],
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                services.isEmpty
                    ? const Center(
                        child: Text(
                          'No service records yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: services.map((s) {
                          return Card(
                            color: const Color(0xFF1E1E24),
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              title: Text(
                                s.description,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                '${s.date.toLocal()}'.split(' ')[0] +
                                    ' • ${s.mileage}km • Rs.${s.cost}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
              ],
            );
          },
        ),
      ),
    );
  }
}