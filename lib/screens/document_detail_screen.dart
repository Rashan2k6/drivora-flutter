import 'dart:io';
import 'package:flutter/material.dart';
import '../models/document_record.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';
import 'add_document_screen.dart';

class DocumentDetailScreen extends StatefulWidget {
  final DocumentRecord document;

  const DocumentDetailScreen({
    super.key,
    required this.document,
  });

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  late DocumentRecord _currentDoc;

  @override
  void initState() {
    super.initState();
    _currentDoc = widget.document;
  }

  String _documentTypeLabel(DocumentType type) {
    switch (type) {
      case DocumentType.insurance:
        return 'Insurance Certificate';
      case DocumentType.license:
        return 'Driving License';
      case DocumentType.revenueLicense:
        return 'Revenue License';
      case DocumentType.emissionTest:
        return 'Emission Test Certificate';
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
    if (daysUntilExpiry <= 14) return const Color(0xFFF59E0B); // Amber
    return const Color(0xFF10B981); // Emerald Green
  }

  String _statusLabel(int daysUntilExpiry) {
    if (daysUntilExpiry < 0) return 'Expired (${daysUntilExpiry.abs()} days ago)';
    if (daysUntilExpiry == 0) return 'Expires Today';
    if (daysUntilExpiry <= 14) return 'Expires Soon ($daysUntilExpiry days left)';
    return 'Valid ($daysUntilExpiry days left)';
  }

  Future<void> _editDocument() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddDocumentScreen(
          vehicleId: _currentDoc.vehicleId,
          initialDocument: _currentDoc,
        ),
      ),
    );

    if (updated == true && mounted) {
      // Reload document from DB
      final docs = await DatabaseHelper.instance.getAllDocuments(_currentDoc.vehicleId);
      final reloaded = docs.firstWhere(
        (d) => d.id == _currentDoc.id,
        orElse: () => _currentDoc,
      );
      setState(() {
        _currentDoc = reloaded;
      });
    }
  }

  Future<void> _deleteDocument() async {
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
              'Delete Document',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this ${_documentTypeLabel(_currentDoc.type)} record?',
          style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteDocument(_currentDoc.id);
      await NotificationService.cancelForDocument(_currentDoc.id);
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate change
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final daysLeft = _currentDoc.daysUntilExpiry;
    final statusColor = _statusColor(daysLeft);
    final expiryDateStr = _currentDoc.expiryDate.toLocal().toString().split(' ')[0];

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 72,
        titleSpacing: 20,
        title: const Text('Document Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF3B82F6)),
            tooltip: 'Edit Document',
            onPressed: _editDocument,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
            tooltip: 'Delete Document',
            onPressed: _deleteDocument,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E24),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _documentIcon(_currentDoc.type),
                      size: 40,
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _documentTypeLabel(_currentDoc.type),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor, width: 1.5),
                    ),
                    child: Text(
                      _statusLabel(daysLeft),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Detailed Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E24),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Information',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Expiry Date',
                    value: expiryDateStr,
                  ),
                  const Divider(color: Colors.white10, height: 28),
                  _DetailRow(
                    icon: Icons.numbers_outlined,
                    label: 'Policy / Reference No.',
                    value: _currentDoc.policyNumber != null &&
                            _currentDoc.policyNumber!.trim().isNotEmpty
                        ? _currentDoc.policyNumber!
                        : 'Not specified',
                  ),
                  const Divider(color: Colors.white10, height: 28),
                  _DetailRow(
                    icon: Icons.business_outlined,
                    label: 'Issuer / Organization',
                    value: _currentDoc.issuer != null &&
                            _currentDoc.issuer!.trim().isNotEmpty
                        ? _currentDoc.issuer!
                        : 'Not specified',
                  ),
                ],
              ),
            ),

            // Scanned Photo Preview (if exists)
            if (_currentDoc.documentPhotoPath != null &&
                _currentDoc.documentPhotoPath!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E24),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Scanned Document Photo',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_currentDoc.documentPhotoPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => const Text(
                          'Photo file not found',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _editDocument,
                    icon: const Icon(Icons.edit_outlined, color: Color(0xFF3B82F6)),
                    label: const Text(
                      'Edit Details',
                      style: TextStyle(
                        color: Color(0xFF3B82F6),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFF3B82F6)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _deleteDocument,
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    label: const Text(
                      'Delete',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF3B82F6), size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
