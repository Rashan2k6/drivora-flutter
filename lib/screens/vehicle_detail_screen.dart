import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';
import 'add_document_screen.dart';
import 'add_service_record_screen.dart';
import 'document_detail_screen.dart';
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

IconData _documentIcon(DocumentType type) {
  switch (type) {
    case DocumentType.insurance:
      return Icons.shield_outlined;
    case DocumentType.license:
      return Icons.badge_outlined;
    case DocumentType.revenueLicense:
      return Icons.receipt_long_outlined;
    case DocumentType.emissionTest:
      return Icons.eco_outlined;
  }
}

Color _statusColor(int daysUntilExpiry) {
  if (daysUntilExpiry < 0) return const Color(0xFFEF4444); // Red
  if (daysUntilExpiry <= 14) return const Color(0xFFF59E0B); // Yellow
  return const Color(0xFF10B981); // Green
}

String _statusLabel(int daysUntilExpiry) {
  if (daysUntilExpiry < 0) return 'Expired';
  if (daysUntilExpiry <= 14) return 'Expires Soon';
  return 'Valid';
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

  Future<void> _confirmDeleteVehicle() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 10),
            Text(
              'Remove Vehicle',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to remove ${widget.vehicle.displayName} (${widget.vehicle.plateNumber})? This will permanently delete all associated documents and service history.',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Remove',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteVehicle(widget.vehicle.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.vehicle.displayName} removed'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _editDocument(DocumentRecord doc) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddDocumentScreen(
          vehicleId: widget.vehicle.id,
          vehicleName: widget.vehicle.displayName,
          initialDocument: doc,
        ),
      ),
    );
    if (updated == true) _refresh();
  }

  Future<void> _deleteDocument(DocumentRecord doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Document',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete this ${_documentTypeLabel(doc.type)} record?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteDocument(doc.id);
      await NotificationService.cancelForDocument(doc.id);
      _refresh();
    }
  }

  Future<void> _editServiceRecord(ServiceRecord record) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddServiceRecordScreen(
          vehicleId: widget.vehicle.id,
          initialRecord: record,
        ),
      ),
    );
    if (updated == true) _refresh();
  }

  Future<void> _deleteServiceRecord(ServiceRecord record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Service Record',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to delete this service record?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteServiceRecord(record.id);
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: const Color(0xFF121212),
          elevation: 0,
          scrolledUnderElevation: 0,
          toolbarHeight: 80,
          titleSpacing: 20,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.vehicle.displayName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${widget.vehicle.plateNumber}${widget.vehicle.year != null ? ' • ${widget.vehicle.year}' : ''}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFEF4444),
              ),
              tooltip: 'Remove Vehicle',
              onPressed: _confirmDeleteVehicle,
            ),
            const SizedBox(width: 8),
          ],
          bottom: const TabBar(
            indicatorColor: Color(0xFF3B82F6),
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle: TextStyle(fontSize: 14),
            tabs: [
              Tab(
                icon: Icon(Icons.folder_copy_outlined, size: 22),
                text: 'Documents',
              ),
              Tab(
                icon: Icon(Icons.build_circle_outlined, size: 22),
                text: 'Service History',
              ),
            ],
          ),
        ),
        floatingActionButton: Builder(
          builder: (context) {
            final tabController = DefaultTabController.of(context);
            return AnimatedBuilder(
              animation: tabController,
              builder: (context, _) {
                final isDocumentsTab = tabController.index == 0;

                return SizedBox(
                  width: 170,
                  height: 50,
                  child: FloatingActionButton.extended(
                    heroTag: isDocumentsTab
                        ? 'addDocumentFab'
                        : 'addServiceRecordFab',
                    backgroundColor: const Color(0xFF2F80ED),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onPressed: () async {
                      final added = isDocumentsTab
                          ? await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddDocumentScreen(
                                  vehicleId: widget.vehicle.id,
                                  vehicleName: widget.vehicle.displayName,
                                ),
                              ),
                            )
                          : await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddServiceRecordScreen(
                                  vehicleId: widget.vehicle.id,
                                ),
                              ),
                            );
                      if (added == true) _refresh();
                    },
                    icon: const Icon(Icons.add_rounded, color: Colors.white),
                    label: Text(
                      isDocumentsTab ? 'Add Document' : 'Add Record',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
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

            final documents =
                snapshot.data!['documents'] as List<DocumentRecord>;
            final services = snapshot.data!['services'] as List<ServiceRecord>;

            return TabBarView(
              children: [
                documents.isEmpty
                    ? const Center(
                        child: Text(
                          'No documents yet — tap + Add Document to add one',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: documents.map((doc) {
                          final expiryDateStr = doc.expiryDate
                              .toLocal()
                              .toString()
                              .split(' ')[0];

                          return Card(
                            color: const Color(0xFF1E1E24),
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.only(
                                left: 14,
                                right: 4,
                              ),
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        DocumentDetailScreen(document: doc),
                                  ),
                                );
                                if (result == true) _refresh();
                              },
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF3B82F6,
                                  ).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _documentIcon(doc.type),
                                  color: const Color(0xFF3B82F6),
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                _documentTypeLabel(doc.type),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                'Expires: $expiryDateStr',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _statusColor(
                                        doc.daysUntilExpiry,
                                      ).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _statusColor(
                                          doc.daysUntilExpiry,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      _statusLabel(doc.daysUntilExpiry),
                                      style: TextStyle(
                                        color: _statusColor(
                                          doc.daysUntilExpiry,
                                        ),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(
                                      Icons.more_vert_rounded,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                                    color: const Color(0xFF1E1E24),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    onSelected: (value) {
                                      if (value == 'edit') _editDocument(doc);
                                      if (value == 'delete')
                                        _deleteDocument(doc);
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.edit_outlined,
                                              color: Colors.white70,
                                              size: 18,
                                            ),
                                            SizedBox(width: 10),
                                            Text(
                                              'Edit',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete_outline,
                                              color: Color(0xFFEF4444),
                                              size: 18,
                                            ),
                                            SizedBox(width: 10),
                                            Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: Color(0xFFEF4444),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                services.isEmpty
                    ? const Center(
                        child: Text(
                          'No service records yet — tap + Add Record to add one',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: services.map((s) {
                          final dateStr = s.date.toLocal().toString().split(
                            ' ',
                          )[0];
                          return Card(
                            color: const Color(0xFF1E1E24),
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.only(
                                left: 14,
                                right: 4,
                              ),
                              onTap: () => _editServiceRecord(s),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.build_circle_outlined,
                                  color: Color(0xFF10B981),
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                s.description,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '$dateStr • ${s.mileage}km' +
                                    (s.cost != null ? ' • Rs.${s.cost}' : '') +
                                    (s.garageName != null
                                        ? ' • ${s.garageName}'
                                        : ''),
                                style: const TextStyle(color: Colors.grey),
                              ),
                              trailing: PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(
                                  Icons.more_vert_rounded,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                                color: const Color(0xFF1E1E24),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                onSelected: (value) {
                                  if (value == 'edit') _editServiceRecord(s);
                                  if (value == 'delete')
                                    _deleteServiceRecord(s);
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.edit_outlined,
                                          color: Colors.white70,
                                          size: 18,
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          'Edit',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete_outline,
                                          color: Color(0xFFEF4444),
                                          size: 18,
                                        ),
                                        SizedBox(width: 10),
                                        Text(
                                          'Delete',
                                          style: TextStyle(
                                            color: Color(0xFFEF4444),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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
