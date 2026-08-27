import 'package:flutter/material.dart';
import '../services/diagnostic_service.dart';

class SymptomCheckerScreen extends StatefulWidget {
  final String vehicleId;
  final String vehicleName;

  const SymptomCheckerScreen({
    super.key,
    required this.vehicleId,
    required this.vehicleName,
  });

  @override
  State<SymptomCheckerScreen> createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends State<SymptomCheckerScreen> {
  final _symptomController = TextEditingController();
  bool _loading = false;
  String? _diagnosis;
  String? _error;

  @override
  void dispose() {
    _symptomController.dispose();
    super.dispose();
  }

  Future<void> _runDiagnosis() async {
    final symptom = _symptomController.text.trim();
    if (symptom.isEmpty) return;

    setState(() {
      _loading = true;
      _diagnosis = null;
      _error = null;
    });

    try {
      final result = await DiagnosticService.diagnose(
        vehicleId: widget.vehicleId,
        symptomDescription: symptom,
      );
      setState(() => _diagnosis = result);
    } catch (e) {
      setState(
        () => _error =
            'Could not reach the diagnostic service. Make sure the backend '
            'server is running and your phone is on the same wifi network.\n\n'
            'Details: $e',
      );
    } finally {
      setState(() => _loading = false);
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
        title: Text('Symptom Checker — ${widget.vehicleName}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Describe the problem',
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
                    'e.g. "Grinding noise when I brake" or "Engine warning light is on"',
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
              onPressed: _loading ? null : _runDiagnosis,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size(double.infinity, 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Get Diagnosis'),
            ),
            const SizedBox(height: 24),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Text(
                    'Analyzing — this may take a few seconds...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            if (_error != null)
              Container(
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
            if (_diagnosis != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
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
                              'Diagnosis',
                              style: TextStyle(
                                color: Color(0xFF3B82F6),
                                fontWeight: FontWeight.w600,
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
                ),
              ),
          ],
        ),
      ),
    );
  }
}
