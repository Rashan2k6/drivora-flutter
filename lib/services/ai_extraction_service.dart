import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Result of scanning a document photo — mirrors the fields on
/// AddDocumentScreen's form so they can be used to pre-fill it.
class ExtractedDocumentData {
  final String? documentType; // 'insurance', 'license', 'revenueLicense', 'emissionTest'
  final String? expiryDate; // ISO format: YYYY-MM-DD
  final String? policyNumber;
  final String? issuer;

  ExtractedDocumentData({
    this.documentType,
    this.expiryDate,
    this.policyNumber,
    this.issuer,
  });

  factory ExtractedDocumentData.fromJson(Map<String, dynamic> json) {
    return ExtractedDocumentData(
      documentType: json['document_type'] as String?,
      expiryDate: json['expiry_date'] as String?,
      policyNumber: json['policy_number'] as String?,
      issuer: json['issuer'] as String?,
    );
  }
}

class AiExtractionService {
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';

  static const String _systemPrompt = '''
You extract structured data from photos of vehicle-related documents
(insurance certificates, driving licenses, revenue licenses, emission
test certificates) commonly used in Sri Lanka.

Respond with ONLY a raw JSON object, no markdown formatting, no code
fences, no explanation. Use this exact shape:

{
  "document_type": "insurance" | "license" | "revenueLicense" | "emissionTest" | null,
  "expiry_date": "YYYY-MM-DD" | null,
  "policy_number": "string or null",
  "issuer": "string or null"
}

If a field is not visible or not applicable, use null for that field.
If you cannot confidently determine the document type, use null.
Only extract what is actually visible in the image — never guess or
invent values.
''';

  /// Sends the document photo to OpenAI's vision model and returns
  /// extracted structured data. Throws an Exception on failure —
  /// caller should catch this and let the user fill the form manually.
  static Future<ExtractedDocumentData> extractFromImage(File imageFile) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('OpenAI API key not configured');
    }

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini', // vision-capable, cost-effective
        'messages': [
          {'role': 'system', 'content': _systemPrompt},
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': 'Extract the document data from this image.',
              },
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:image/jpeg;base64,$base64Image',
                },
              },
            ],
          },
        ],
        'max_tokens': 500,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'OpenAI API error (${response.statusCode}): ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    final content = decoded['choices'][0]['message']['content'] as String;

    // Model may occasionally wrap in markdown code fences despite
    // instructions — strip those defensively before parsing.
    final cleaned = content
        .replaceAll(RegExp(r'^```json\s*'), '')
        .replaceAll(RegExp(r'^```\s*'), '')
        .replaceAll(RegExp(r'```\s*$'), '')
        .trim();

    final Map<String, dynamic> jsonData = jsonDecode(cleaned);
    return ExtractedDocumentData.fromJson(jsonData);
  }
}