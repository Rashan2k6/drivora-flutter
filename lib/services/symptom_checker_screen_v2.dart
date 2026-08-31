import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

  String _cleanText(String input) {
    return input.replaceAll('**', '').replaceAll('*', '').trim();
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
      if (mounted) setState(() => _diagnosis = _cleanText(result));
    } catch (_) {
      try {
        final fallback = await _fetchFallbackDiagnosis(widget.vehicleName, symptom);
        if (mounted) setState(() => _diagnosis = _cleanText(fallback));
      } catch (_) {
        if (mounted) {
          setState(() {
            _error =
                'Unable to connect to the vehicle diagnostic service. Please check your internet connection and try again.';
          });
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String> _fetchFallbackDiagnosis(String vehicleName, String symptom) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];

    if (apiKey != null && apiKey.trim().isNotEmpty) {
      try {
        final response = await http
            .post(
              Uri.parse('https://api.openai.com/v1/chat/completions'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ${apiKey.trim()}',
              },
              body: jsonEncode({
                'model': 'gpt-4o-mini',
                'messages': [
                  {
                    'role': 'system',
                    'content':
                        'You are Drivora AI Vehicle Diagnostic Assistant. Provide a clear, structured diagnostic report for the reported vehicle symptom. Do NOT use markdown bold stars or asterisks (** or *) in your output.',
                  },
                  {
                    'role': 'user',
                    'content': 'Vehicle: $vehicleName\nSymptom: $symptom',
                  },
                ],
                'max_tokens': 500,
              }),
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          final content =
              decoded['choices']?[0]?['message']?['content'] as String?;
          if (content != null && content.trim().isNotEmpty) {
            return content.trim();
          }
        }
      } catch (_) {}
    }

    return _generateLocalDiagnosticReport(vehicleName, symptom);
  }

  String _generateLocalDiagnosticReport(String vehicleName, String symptom) {
    final s = symptom.toLowerCase();

    if (s.contains('light') ||
        s.contains('headlight') ||
        s.contains('lamp') ||
        s.contains('bulb')) {
      return '🔍 Diagnostic Report — $vehicleName\n\n'
          'Symptom: "$symptom"\n\n'
          '1. Most Likely Causes:\n'
          '• Burned-out bulb (filament or LED module failure)\n'
          '• Blown headlight fuse or faulty relay in engine fuse box\n'
          '• Loose or corroded wiring connector harness\n'
          '• Faulty headlight stalk switch on steering column\n\n'
          '2. Urgency & Safety Risk:\n'
          '⚠️ HIGH — Reduced night visibility poses severe road hazards and violates traffic safety regulations.\n\n'
          '3. Recommended Actions:\n'
          '1. Inspect fuses under hood / dashboard for any blown circuit.\n'
          '2. Swap with a known working bulb to verify bulb failure.\n'
          '3. Have an electrician test voltage at connector socket.\n\n'
          '4. Estimated Cost Range:\n'
          '• Fuse / Relay: Rs. 500 – Rs. 1,500\n'
          '• Replacement Bulb: Rs. 1,500 – Rs. 4,500';
    } else if (s.contains('brake') ||
        s.contains('squeal') ||
        s.contains('grind') ||
        s.contains('stop')) {
      return '🔍 Diagnostic Report — $vehicleName\n\n'
          'Symptom: "$symptom"\n\n'
          '1. Most Likely Causes:\n'
          '• Worn brake pads reaching squeal sensor indicator\n'
          '• Metal-on-metal rotor contact due to completely worn pads\n'
          '• Glazed brake rotors or trapped debris\n\n'
          '2. Urgency & Safety Risk:\n'
          '🚨 CRITICAL — Compromised braking distance directly affects stopping capability.\n\n'
          '3. Recommended Actions:\n'
          '1. Visually check brake pad thickness through wheel spokes.\n'
          '2. Have brake rotors resurfaced or replaced if grooved.\n\n'
          '4. Estimated Cost Range:\n'
          '• Front Brake Pad Set: Rs. 6,500 – Rs. 16,000';
    } else {
      return '🔍 Diagnostic Report — $vehicleName\n\n'
          'Symptom: "$symptom"\n\n'
          '1. Most Likely Causes:\n'
          '• Electrical connection or sensor communication issue\n'
          '• Wear and tear on mechanical component assembly\n'
          '• Fluid level imbalance or filter blockage\n\n'
          '2. Urgency & Safety Risk:\n'
          '⚠️ MODERATE — Schedule inspection with a qualified technician to prevent further wear.\n\n'
          '3. Recommended Actions:\n'
          '1. Perform visual inspection under hood for fluid leaks or loose wires.\n'
          '2. Scan vehicle with OBD-II scanner for error codes if check engine light is illuminated.\n\n'
          '4. Estimated Cost Range:\n'
          '• Diagnostic scan & basic check: Rs. 2,000 – Rs. 5,000';
    }
  }

  Widget _buildErrorCard(String errorMsg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF2C1C1E),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  color: Color(0xFFEF4444),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Diagnostic Service Unavailable',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            errorMsg,
            style: const TextStyle(
              color: Color(0xFFFCA5A5),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _loading ? null : _runDiagnosis,
              icon: const Icon(Icons.refresh_rounded,
                  size: 18, color: Colors.white),
              label: const Text(
                'Try Again',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: Color(0xFFEF4444)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
      body: SingleChildScrollView(
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
                  : const Text(
                      'Get Diagnosis',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
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
            if (_error != null) _buildErrorCard(_error!),
            if (_diagnosis != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E24),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
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
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SelectableText(
                      _cleanText(_diagnosis!),
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
