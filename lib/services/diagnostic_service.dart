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
  static const String _baseUrl = 'https://drivora-agent-backend.onrender.com';

  static Future<String> diagnose({
    required String vehicleId,
    required String symptomDescription,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/diagnose'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'vehicle_id': vehicleId,
              'symptom_description': symptomDescription,
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded['diagnosis'] as String;
      } else {
        throw Exception(
          'Server returned error status ${response.statusCode}: ${response.body}',
        );
      }
    } catch (_) {
      throw Exception(
        'Unable to connect to the vehicle diagnostic service. Please check your internet connection and try again.',
      );
    }
  }
}
