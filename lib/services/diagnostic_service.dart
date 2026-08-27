import 'dart:convert';
import 'package:http/http.dart' as http;

/// Calls the Drivora Agent Backend's /diagnose endpoint.
///
/// IMPORTANT: update _baseUrl below to your computer's local network
/// IP address (not localhost/127.0.0.1) so your phone can reach it.
/// Find your IP with `ipconfig` on Windows (look for "IPv4 Address"
/// under your active network adapter, e.g. 192.168.1.42).
/// Your phone and computer must be on the SAME wifi network.
class DiagnosticService {
  // Candidate backend base URLs for local network, Android emulator (10.0.2.2), and localhost
  static const List<String> _candidateUrls = [
    'http://192.168.1.9:8000',
    'http://10.0.2.2:8000',
    'http://localhost:8000',
    'http://127.0.0.1:8000',
  ];

  static Future<String> diagnose({
    required String vehicleId,
    required String symptomDescription,
  }) async {
    Object? lastError;

    for (final baseUrl in _candidateUrls) {
      try {
        final response = await http
            .post(
              Uri.parse('$baseUrl/diagnose'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'vehicle_id': vehicleId,
                'symptom_description': symptomDescription,
              }),
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          return decoded['diagnosis'] as String;
        } else {
          lastError = 'Status ${response.statusCode}: ${response.body}';
        }
      } catch (e) {
        lastError = e;
      }
    }

    throw Exception(
      'Could not reach diagnostic backend service.\n'
      'Ensure the server is running with: uvicorn main:app --host 0.0.0.0 --port 8000\n\n'
      'Details: $lastError',
    );
  }
}
