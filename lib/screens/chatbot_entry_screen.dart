import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../services/database_helper.dart';
import '../services/diagnostic_service.dart';

class ChatbotEntryScreen extends StatefulWidget {
  final String? initialVehicleId;

  const ChatbotEntryScreen({super.key, this.initialVehicleId});

  @override
  State<ChatbotEntryScreen> createState() => _ChatbotEntryScreenState();
}

class _ChatbotEntryScreenState extends State<ChatbotEntryScreen> {
  final _symptomController = TextEditingController();
  List<Vehicle> _vehicles = [];
  String? _selectedVehicleId;
  bool _loadingVehicles = true;
  bool _diagnosing = false;
  String? _diagnosis;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  @override
  void dispose() {
    _symptomController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    try {
      final vehicles = await DatabaseHelper.instance.getVehicles();
      setState(() {
        _vehicles = vehicles;
        if (vehicles.isNotEmpty) {
          if (widget.initialVehicleId != null &&
              vehicles.any((v) => v.id == widget.initialVehicleId)) {
            _selectedVehicleId = widget.initialVehicleId;
          } else {
            _selectedVehicleId = vehicles.first.id;
          }
        } else {
          _selectedVehicleId = null;
        }
        _loadingVehicles = false;
      });
    } catch (e) {
      setState(() {
        _loadingVehicles = false;
      });
    }
  }

  Future<void> _runDiagnosis() async {
    final symptom = _symptomController.text.trim();
    if (symptom.isEmpty) return;
    if (_selectedVehicleId == null) {
      setState(() {
        _error = 'Please select or add a vehicle first.';
      });
      return;
    }

    setState(() {
      _diagnosing = true;
      _diagnosis = null;
      _error = null;
    });

    try {
      final result = await DiagnosticService.diagnose(
        vehicleId: _selectedVehicleId!,
        symptomDescription: symptom,
      );
      setState(() => _diagnosis = result);
    } catch (e) {
      setState(
        () => _error =
            'Could not reach the diagnostic service. Ensure the backend server '
            'is running and reachable.\n\nDetails: $e',
      );
    } finally {
      setState(() => _diagnosing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeVehicleId =
        _vehicles.any((v) => v.id == _selectedVehicleId)
            ? _selectedVehicleId
            : (_vehicles.isNotEmpty ? _vehicles.first.id : null);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 72,
        titleSpacing: 20,
        title: Row(
          children: const [
            Icon(Icons.smart_toy_outlined, color: Color(0xFF3B82F6)),
            SizedBox(width: 10),
            Text(
              'AI Assistant',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: _loadingVehicles
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Vehicle',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_vehicles.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E24),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.3),
                        ),
                      ),
                      child: const Text(
                        'No vehicles found. Please add a vehicle on the home dashboard first.',
                        style: TextStyle(color: Colors.amber),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E24),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: activeVehicleId,
                          dropdownColor: const Color(0xFF1E1E24),
                          isExpanded: true,
                          style: const TextStyle(color: Colors.white),
                          items: _vehicles.map((v) {
                            return DropdownMenuItem<String>(
                              value: v.id,
                              child: Text('${v.displayName} (${v.plateNumber})'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedVehicleId = val;
                            });
                          },
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  const Text(
                    'Describe the Symptom or Issue',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _symptomController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText:
                          'e.g., "Hearing a squealing noise when braking at low speeds"',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFF1E1E24),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _diagnosing ? null : _runDiagnosis,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      minimumSize: const Size(double.infinity, 0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _diagnosing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Analyze & Diagnose',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),
                  if (_diagnosing)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Text(
                          'Analyzing symptoms with AI agent...',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  if (_error != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_diagnosis != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E24),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF3B82F6).withOpacity(0.4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.smart_toy_outlined,
                                color: Color(0xFF3B82F6),
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Diagnostic Report',
                                style: TextStyle(
                                  color: Color(0xFF3B82F6),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _diagnosis!,
                            style: const TextStyle(
                              color: Colors.white,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
