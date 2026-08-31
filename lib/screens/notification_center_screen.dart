import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../models/document_record.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';
import 'vehicle_detail_screen.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  late Future<Map<String, dynamic>> _dataFuture;
  String _selectedFilter = 'All'; // 'All', 'Urgent', 'Compliant'

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

  String _formatDocTypeName(DocumentType type) {
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

  Color _statusColor(int daysUntilExpiry) {
    if (daysUntilExpiry < 0) {
      return const Color(0xFFEF4444); // Red: Expired
    }
    if (daysUntilExpiry <= 14) {
      return const Color(0xFFF59E0B); // Amber: Expiring Soon
    }
    return const Color(0xFF10B981); // Green: Valid
  }

  String _statusText(int daysUntilExpiry) {
    if (daysUntilExpiry < 0) {
      final daysPast = daysUntilExpiry.abs();
      return daysPast == 1 ? 'Expired yesterday' : 'Expired $daysPast days ago';
    }
    if (daysUntilExpiry == 0) {
      return 'Expires today';
    }
    if (daysUntilExpiry == 1) {
      return 'Expires tomorrow';
    }
    if (daysUntilExpiry <= 14) {
      return 'Expires in $daysUntilExpiry days';
    }
    return 'Valid ($daysUntilExpiry days remaining)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Notification Center',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Document Expiries & System Alerts',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
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
                'Error loading notifications: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final vehicles = snapshot.data!['vehicles'] as List<Vehicle>;
          final documents = snapshot.data!['documents'] as List<DocumentRecord>;

          final expiredDocs = documents.where((d) => d.daysUntilExpiry < 0).toList();
          final warningDocs =
              documents.where((d) => d.daysUntilExpiry >= 0 && d.daysUntilExpiry <= 14).toList();
          final validDocs = documents.where((d) => d.daysUntilExpiry > 14).toList();

          // Sort documents: expired first, then expiring soon, then valid
          final sortedDocs = List<DocumentRecord>.from(documents)
            ..sort((a, b) => a.daysUntilExpiry.compareTo(b.daysUntilExpiry));

          final filteredDocs = sortedDocs.where((doc) {
            if (_selectedFilter == 'Urgent') {
              return doc.daysUntilExpiry <= 14;
            }
            if (_selectedFilter == 'Compliant') {
              return doc.daysUntilExpiry > 14;
            }
            return true;
          }).toList();

          return RefreshIndicator(
            backgroundColor: const Color(0xFF1E1E24),
            color: const Color(0xFF3B82F6),
            onRefresh: () async {
              _refresh();
              await _dataFuture;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                // Summary Header Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E24),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _SummaryBadge(
                            label: 'Expired',
                            count: expiredDocs.length,
                            color: const Color(0xFFEF4444),
                            icon: Icons.error_outline_rounded,
                          ),
                          Container(
                            width: 1,
                            height: 36,
                            color: Colors.white10,
                          ),
                          _SummaryBadge(
                            label: 'Expiring Soon',
                            count: warningDocs.length,
                            color: const Color(0xFFF59E0B),
                            icon: Icons.warning_amber_rounded,
                          ),
                          Container(
                            width: 1,
                            height: 36,
                            color: Colors.white10,
                          ),
                          _SummaryBadge(
                            label: 'Valid',
                            count: validDocs.length,
                            color: const Color(0xFF10B981),
                            icon: Icons.check_circle_outline_rounded,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: Colors.white10, height: 1),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'System Push Alerts',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          InkWell(
                            onTap: () async {
                              await NotificationService.showTestNotification(
                                title: 'Drivora Document Alert Test',
                                body:
                                    'Notifications active! We will remind you before document expiries.',
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Test notification triggered!'),
                                    backgroundColor: Color(0xFF3B82F6),
                                  ),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.notifications_active_outlined,
                                    color: Color(0xFF3B82F6),
                                    size: 14,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Test Notification',
                                    style: TextStyle(
                                      color: Color(0xFF3B82F6),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Filter Segment Controls
                Row(
                  children: [
                    _FilterChip(
                      label: 'All (${sortedDocs.length})',
                      isSelected: _selectedFilter == 'All',
                      onSelected: () => setState(() => _selectedFilter = 'All'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Urgent (${expiredDocs.length + warningDocs.length})',
                      isSelected: _selectedFilter == 'Urgent',
                      badgeColor: const Color(0xFFEF4444),
                      onSelected: () => setState(() => _selectedFilter = 'Urgent'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Compliant (${validDocs.length})',
                      isSelected: _selectedFilter == 'Compliant',
                      badgeColor: const Color(0xFF10B981),
                      onSelected: () => setState(() => _selectedFilter = 'Compliant'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Notification Items List
                if (filteredDocs.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.notifications_off_outlined,
                          color: Colors.grey,
                          size: 48,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No document alerts in this filter.',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                else
                  ...filteredDocs.map((doc) {
                    final vehicle = vehicles.firstWhere(
                      (v) => v.id == doc.vehicleId,
                      orElse: () => Vehicle(
                        id: doc.vehicleId,
                        plateNumber: 'Unknown',
                        make: 'Vehicle',
                        model: '',
                        year: 2024,
                      ),
                    );

                    final statusColor = _statusColor(doc.daysUntilExpiry);
                    final typeTitle = _formatDocTypeName(doc.type);
                    final statusMessage = _statusText(doc.daysUntilExpiry);

                    return Card(
                      color: const Color(0xFF1E1E24),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: statusColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VehicleDetailScreen(vehicle: vehicle),
                            ),
                          );
                          _refresh();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  doc.daysUntilExpiry < 0
                                      ? Icons.error_rounded
                                      : doc.daysUntilExpiry <= 14
                                          ? Icons.warning_amber_rounded
                                          : Icons.assignment_turned_in_rounded,
                                  color: statusColor,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '$typeTitle Alert',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${doc.expiryDate.year}-${doc.expiryDate.month.toString().padLeft(2, '0')}-${doc.expiryDate.day.toString().padLeft(2, '0')}',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${vehicle.displayName} (${vehicle.plateNumber})',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        statusMessage,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.grey,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _SummaryBadge({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 11),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;
  final Color? badgeColor;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? (badgeColor ?? const Color(0xFF3B82F6)).withValues(alpha: 0.2)
                : const Color(0xFF1E1E24),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? (badgeColor ?? const Color(0xFF3B82F6))
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? (badgeColor ?? const Color(0xFF3B82F6))
                  : Colors.grey,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
