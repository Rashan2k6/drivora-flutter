import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/service_record.dart';
import '../services/database_helper.dart';

class AddServiceRecordScreen extends StatefulWidget {
  final String vehicleId;

  const AddServiceRecordScreen({super.key, required this.vehicleId});

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

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final record = ServiceRecord(
      id: const Uuid().v4(),
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

    await DatabaseHelper.instance.insertServiceRecord(record);

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
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        title: const Text('Add Service Record'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
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
                    : const Text('Save Service Record'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
