import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/service_record.dart';
import '../services/database_helper.dart';
import '../services/ai_extraction_service.dart';
import '../widgets/scan_error_bottom_sheet.dart';

class AddServiceRecordScreen extends StatefulWidget {
  final String vehicleId;
  final ServiceRecord? initialRecord;

  const AddServiceRecordScreen({
    super.key,
    required this.vehicleId,
    this.initialRecord,
  });

  @override
  State<AddServiceRecordScreen> createState() => _AddServiceRecordScreenState();
}

class _AddServiceRecordScreenState extends State<AddServiceRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mileageController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();
  final _garageController = TextEditingController();

  DateTime _serviceDate = DateTime.now();
  bool _saving = false;
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialRecord != null) {
      _serviceDate = widget.initialRecord!.date;
      _mileageController.text = widget.initialRecord!.mileage.toString();
      _descriptionController.text = widget.initialRecord!.description;
      _costController.text = widget.initialRecord!.cost?.toString() ?? '';
      _garageController.text = widget.initialRecord!.garageName ?? '';
    }
  }

  @override
  void dispose() {
    _mileageController.dispose();
    _descriptionController.dispose();
    _costController.dispose();
    _garageController.dispose();
    super.dispose();
  }

  Future<void> _pickServiceDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _serviceDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
      lastDate: DateTime.now(),
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
      setState(() => _serviceDate = picked);
    }
  }

  DateTime? _parseDate(String? dateString) {
    if (dateString == null) return null;
    try {
      return DateTime.parse(dateString);
    } catch (_) {
      return null;
    }
  }

  Future<void> _scanServiceReceipt() async {
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
      final extracted = await AiExtractionService.extractServiceRecordFromImage(
        File(pickedFile.path),
      );

      final parsedDate = _parseDate(extracted.date);

      setState(() {
        if (parsedDate != null) _serviceDate = parsedDate;
        if (extracted.mileage != null) {
          _mileageController.text = extracted.mileage.toString();
        }
        if (extracted.description != null) {
          _descriptionController.text = extracted.description!;
        }
        if (extracted.cost != null) {
          _costController.text = extracted.cost.toString();
        }
        if (extracted.garageName != null) {
          _garageController.text = extracted.garageName!;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service receipt scanned successfully! Please review details before saving.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } on ScanException catch (e) {
      if (mounted) {
        ScanErrorBottomSheet.show(
          context: context,
          exception: e,
          onRetry: () => _scanServiceReceipt(),
        );
      }
    } catch (e) {
      if (mounted) {
        ScanErrorBottomSheet.show(
          context: context,
          exception: ScanException.unknown(e),
          onRetry: () => _scanServiceReceipt(),
        );
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final isEditing = widget.initialRecord != null;

    final record = ServiceRecord(
      id: isEditing ? widget.initialRecord!.id : const Uuid().v4(),
      vehicleId: widget.vehicleId,
      date: _serviceDate,
      mileage: int.parse(_mileageController.text.trim()),
      description: _descriptionController.text.trim(),
      cost: _costController.text.trim().isEmpty
          ? null
          : double.tryParse(_costController.text.trim()),
      garageName: _garageController.text.trim().isEmpty
          ? null
          : _garageController.text.trim(),
    );

    if (isEditing) {
      await DatabaseHelper.instance.updateServiceRecord(record);
    } else {
      await DatabaseHelper.instance.insertServiceRecord(record);
    }

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

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialRecord != null;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 72,
        titleSpacing: 20,
        title: Text(isEditing ? 'Edit Service Record' : 'Add Service Record'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Scan button — sits above manual form fields
              OutlinedButton.icon(
                onPressed: _scanning ? null : _scanServiceReceipt,
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
                  _scanning ? 'Scanning...' : 'Scan Receipt / Invoice',
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
                'Scan a photo of your receipt or invoice to auto-fill, or enter details manually below',
                style: TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: _pickServiceDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: _inputStyle('Service Date'),
                  child: Text(
                    '${_serviceDate.toLocal()}'.split(' ')[0],
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mileageController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: _inputStyle('Mileage (km)'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (int.tryParse(v.trim()) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: _inputStyle(
                  'What was done (e.g. oil change, brake pads)',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _costController,
                style: const TextStyle(color: Colors.white),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _inputStyle('Cost in Rs. (optional)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _garageController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputStyle('Garage/Mechanic Name (optional)'),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saving ? null : _saveRecord,
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
                    : Text(
                        isEditing ? 'Update Record' : 'Add Record',
                        style: const TextStyle(
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
