import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/vehicle.dart';
import '../services/database_helper.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _plateController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final vehicle = Vehicle(
      id: const Uuid().v4(),
      plateNumber: _plateController.text.trim(),
      make: _makeController.text.trim(),
      model: _modelController.text.trim(),
      year: _yearController.text.trim().isEmpty
          ? null
          : int.tryParse(_yearController.text.trim()),
    );

    await DatabaseHelper.instance.insertVehicle(vehicle);

    if (mounted) {
      Navigator.pop(context, true); // true = signal dashboard to refresh
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
        title: const Text('Add Vehicle'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _plateController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputStyle('Plate Number'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _makeController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputStyle('Make (e.g. Toyota)'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _modelController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputStyle('Model (e.g. Aqua)'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _yearController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: _inputStyle('Year (optional)'),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saving ? null : _saveVehicle,
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
                    : const Text(
                      'Save Vehicle', 
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