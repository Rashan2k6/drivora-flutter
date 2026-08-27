import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/document_record.dart';
import '../services/database_helper.dart';
import '../services/ai_extraction_service.dart';
import '../widgets/scan_error_bottom_sheet.dart';

class AddDocumentScreen extends StatefulWidget {
  final String vehicleId;

  const AddDocumentScreen({super.key, required this.vehicleId});

  @override
  State<AddDocumentScreen> createState() => _AddDocumentScreenState();
}

class _AddDocumentScreenState extends State<AddDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _policyNumberController = TextEditingController();
  final _issuerController = TextEditingController();

  DocumentType _selectedType = DocumentType.insurance;
  DateTime? _expiryDate;
  bool _saving = false;
  bool _scanning = false;

  @override
  void dispose() {
    _policyNumberController.dispose();
    _issuerController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF3B82F6),
              surface: Color(0xFF1E1E24),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  DocumentType? _mapDocumentType(String? typeString) {
    if (typeString == null) return null;
    try {
      return DocumentType.values.byName(typeString);
    } catch (_) {
      return null; // AI returned something unexpected — ignore it
    }
  }

  DateTime? _parseDate(String? dateString) {
    if (dateString == null) return null;
    try {
      return DateTime.parse(dateString);
    } catch (_) {
      return null; // AI returned a bad/unparseable date — ignore it
    }
  }

  Future<void> _scanDocument() async {
    final picker = ImagePicker();
    final pickedFile = await showModalBottomSheet<XFile?>(
      context: context,
      backgroundColor: const Color(0xFF1E1E24),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text('Take Photo', style: TextStyle(color: Colors.white)),
              onTap: () async {
                final file = await picker.pickImage(source: ImageSource.camera);
                if (context.mounted) Navigator.pop(context, file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text('Choose from Gallery', style: TextStyle(color: Colors.white)),
              onTap: () async {
                final file = await picker.pickImage(source: ImageSource.gallery);
                if (context.mounted) Navigator.pop(context, file);
              },
            ),
          ],
        ),
      ),
    );

    if (pickedFile == null) return;

    setState(() => _scanning = true);

    try {
      final extracted = await AiExtractionService.extractFromImage(
        File(pickedFile.path),
      );

      final mappedType = _mapDocumentType(extracted.documentType);
      final parsedDate = _parseDate(extracted.expiryDate);

      setState(() {
        if (mappedType != null) _selectedType = mappedType;
        if (parsedDate != null) _expiryDate = parsedDate;
        if (extracted.policyNumber != null) {
          _policyNumberController.text = extracted.policyNumber!;
        }
        if (extracted.issuer != null) {
          _issuerController.text = extracted.issuer!;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document scanned successfully! Please review details before saving.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } on ScanException catch (e) {
      if (mounted) {
        ScanErrorBottomSheet.show(
          context: context,
          exception: e,
          onRetry: () => _scanDocument(),
        );
      }
    } catch (e) {
      if (mounted) {
        ScanErrorBottomSheet.show(
          context: context,
          exception: ScanException.unknown(e),
          onRetry: () => _scanDocument(),
        );
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _saveDocument() async {
    if (!_formKey.currentState!.validate()) return;
    if (_expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an expiry date')),
      );
      return;
    }

    setState(() => _saving = true);

    final doc = DocumentRecord(
      id: const Uuid().v4(),
      vehicleId: widget.vehicleId,
      type: _selectedType,
      expiryDate: _expiryDate!,
      policyNumber: _policyNumberController.text.trim().isEmpty
          ? null
          : _policyNumberController.text.trim(),
      issuer: _issuerController.text.trim().isEmpty
          ? null
          : _issuerController.text.trim(),
    );

    await DatabaseHelper.instance.insertDocument(doc);

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  InputDecoration _inputStyle(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF3B82F6)),
      ),
    );
  }

  String _typeLabel(DocumentType type) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 72,
        titleSpacing: 20,
        title: const Text('Add Document'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Scan button — sits above the manual form fields
              OutlinedButton.icon(
                onPressed: _scanning ? null : _scanDocument,
                icon: _scanning
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF3B82F6),
                        ),
                      )
                    : const Icon(Icons.document_scanner_outlined,
                        color: Color(0xFF3B82F6)),
                label: Text(
                  _scanning ? 'Scanning...' : 'Scan Document',
                  style: const TextStyle(
                    color: Color(0xFF3B82F6),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF3B82F6),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: Color(0xFF3B82F6)),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Scan a photo to auto-fill, or enter details manually below',
                style: TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<DocumentType>(
                initialValue: _selectedType,
                dropdownColor: const Color(0xFF1E1E24),
                style: const TextStyle(color: Colors.white),
                decoration: _inputStyle('Document Type'),
                items: DocumentType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_typeLabel(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedType = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickExpiryDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: _inputStyle('Expiry Date'),
                  child: Text(
                    _expiryDate == null
                        ? 'Select date'
                        : '${_expiryDate!.toLocal()}'.split(' ')[0],
                    style: TextStyle(
                      color: _expiryDate == null ? Colors.grey : Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _policyNumberController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputStyle('Policy/Reference Number (optional)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _issuerController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputStyle('Issuer (optional)'),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saving ? null : _saveDocument,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Add Document',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}