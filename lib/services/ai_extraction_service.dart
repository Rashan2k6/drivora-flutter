import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Categories of errors that can occur during document scanning
enum ScanErrorType {
  missingApiKey,
  noInternet,
  timeout,
  unreadableDocument,
  apiError,
  unknown,
}

/// Custom structured exception for document scan failures with user-friendly strings
class ScanException implements Exception {
  final ScanErrorType type;
  final String title;
  final String message;
  final String hint;
  final String? originalError;

  ScanException({
    required this.type,
    required this.title,
    required this.message,
    required this.hint,
    this.originalError,
  });

  factory ScanException.missingApiKey() {
    return ScanException(
      type: ScanErrorType.missingApiKey,
      title: 'Scanner Unavailable',
      message: 'Document auto-scanning is currently unavailable.',
      hint: 'Please enter your document details manually below, or try scanning again later.',
    );
  }

  factory ScanException.noInternet() {
    return ScanException(
      type: ScanErrorType.noInternet,
      title: 'No Connection',
      message: 'Unable to connect to the document processing service.',
      hint: 'Please check your internet connection and try again, or enter details manually below.',
    );
  }

  factory ScanException.timeout() {
    return ScanException(
      type: ScanErrorType.timeout,
      title: 'Connection Timed Out',
      message: 'Processing your document photo took too long.',
      hint: 'Ensure you have a stable connection and try again, or enter details manually below.',
    );
  }

  factory ScanException.unreadableDocument([String? details]) {
    return ScanException(
      type: ScanErrorType.unreadableDocument,
      title: 'Document Unreadable',
      message: 'We couldn\'t clearly read the text from this document photo.',
      hint: 'Take a clear, well-lit photo of the entire document without heavy glare, or fill in details manually.',
      originalError: details,
    );
  }

  factory ScanException.apiError(int statusCode, String body) {
    return ScanException(
      type: ScanErrorType.apiError,
      title: 'Scanner Temporarily Unavailable',
      message: 'Auto-scanning is temporarily unavailable at the moment.',
      hint: 'Please fill in your document details manually below, or try scanning again in a few minutes.',
      originalError: 'Status $statusCode: $body',
    );
  }

  factory ScanException.unknown(Object e) {
    return ScanException(
      type: ScanErrorType.unknown,
      title: 'Scanning Failed',
      message: 'Something went wrong while processing the document photo.',
      hint: 'You can try scanning again with another photo, or enter document details manually below.',
      originalError: e.toString(),
    );
  }

  @override
  String toString() => '$title: $message ($hint)';
}

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

  bool get isEmpty =>
      documentType == null &&
      expiryDate == null &&
      policyNumber == null &&
      issuer == null;

  factory ExtractedDocumentData.fromJson(Map<String, dynamic> json) {
    return ExtractedDocumentData(
      documentType: json['document_type'] as String?,
      expiryDate: json['expiry_date'] as String?,
      policyNumber: json['policy_number'] as String?,
      issuer: json['issuer'] as String?,
    );
  }
}

/// Result of scanning a service receipt or invoice photo — mirrors the fields on
/// AddServiceRecordScreen's form so they can be used to pre-fill it.
class ExtractedServiceRecordData {
  final String? date; // ISO format: YYYY-MM-DD
  final int? mileage;
  final String? description;
  final double? cost;
  final String? garageName;

  ExtractedServiceRecordData({
    this.date,
    this.mileage,
    this.description,
    this.cost,
    this.garageName,
  });

  bool get isEmpty =>
      date == null &&
      mileage == null &&
      description == null &&
      cost == null &&
      garageName == null;

  factory ExtractedServiceRecordData.fromJson(Map<String, dynamic> json) {
    return ExtractedServiceRecordData(
      date: json['date'] as String?,
      mileage: (json['mileage'] as num?)?.toInt(),
      description: json['description'] as String?,
      cost: (json['cost'] as num?)?.toDouble(),
      garageName: json['garage_name'] as String?,
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

  static const String _servicePrompt = '''
You extract structured data from photos of vehicle service receipts, invoices,
maintenance bills, or repair job sheets.

Respond with ONLY a raw JSON object, no markdown formatting, no code
fences, no explanation. Use this exact shape:

{
  "date": "YYYY-MM-DD" | null,
  "mileage": number | null,
  "description": "string or null",
  "cost": number | null,
  "garage_name": "string or null"
}

If a field is not visible or not applicable, use null for that field.
In description, summarize the key work done (e.g. "Oil change, brake pad replacement, general service").
Only extract what is actually visible in the image — never guess or invent values.
''';

  /// Sends the document photo to OpenAI's vision model and returns
  /// extracted structured data. Throws a [ScanException] on failure.
  static Future<ExtractedDocumentData> extractFromImage(File imageFile) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw ScanException.missingApiKey();
    }

    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${apiKey.trim()}',
            },
            body: jsonEncode({
              'model': 'gpt-4o-mini',
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
          )
          .timeout(const Duration(seconds: 25));

      if (response.statusCode != 200) {
        throw ScanException.apiError(response.statusCode, response.body);
      }

      final decoded = jsonDecode(response.body);
      final content = decoded['choices']?[0]?['message']?['content'] as String?;

      if (content == null || content.trim().isEmpty) {
        throw ScanException.unreadableDocument('Empty content from AI response');
      }

      // Model may occasionally wrap in markdown code fences despite
      // instructions — strip those defensively before parsing.
      final cleaned = content
          .replaceAll(RegExp(r'^```json\s*'), '')
          .replaceAll(RegExp(r'^```\s*'), '')
          .replaceAll(RegExp(r'```\s*$'), '')
          .trim();

      final Map<String, dynamic> jsonData = jsonDecode(cleaned);
      final result = ExtractedDocumentData.fromJson(jsonData);

      if (result.isEmpty) {
        throw ScanException.unreadableDocument('No structured fields could be recognized');
      }

      return result;
    } on ScanException {
      rethrow;
    } on SocketException {
      throw ScanException.noInternet();
    } on http.ClientException {
      throw ScanException.noInternet();
    } on TimeoutException {
      throw ScanException.timeout();
    } on FormatException catch (e) {
      throw ScanException.unreadableDocument('JSON parse error: ${e.message}');
    } catch (e) {
      throw ScanException.unknown(e);
    }
  }

  /// Sends a service receipt/invoice photo to OpenAI's vision model and returns
  /// extracted structured service data. Throws a [ScanException] on failure.
  static Future<ExtractedServiceRecordData> extractServiceRecordFromImage(File imageFile) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw ScanException.missingApiKey();
    }

    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${apiKey.trim()}',
            },
            body: jsonEncode({
              'model': 'gpt-4o-mini',
              'messages': [
                {'role': 'system', 'content': _servicePrompt},
                {
                  'role': 'user',
                  'content': [
                    {
                      'type': 'text',
                      'text': 'Extract the service record details from this receipt or invoice.',
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
          )
          .timeout(const Duration(seconds: 25));

      if (response.statusCode != 200) {
        throw ScanException.apiError(response.statusCode, response.body);
      }

      final decoded = jsonDecode(response.body);
      final content = decoded['choices']?[0]?['message']?['content'] as String?;

      if (content == null || content.trim().isEmpty) {
        throw ScanException.unreadableDocument('Empty content from AI response');
      }

      final cleaned = content
          .replaceAll(RegExp(r'^```json\s*'), '')
          .replaceAll(RegExp(r'^```\s*'), '')
          .replaceAll(RegExp(r'```\s*$'), '')
          .trim();

      final Map<String, dynamic> jsonData = jsonDecode(cleaned);
      final result = ExtractedServiceRecordData.fromJson(jsonData);

      if (result.isEmpty) {
        throw ScanException.unreadableDocument('No structured fields could be recognized');
      }

      return result;
    } on ScanException {
      rethrow;
    } on SocketException {
      throw ScanException.noInternet();
    } on http.ClientException {
      throw ScanException.noInternet();
    } on TimeoutException {
      throw ScanException.timeout();
    } on FormatException catch (e) {
      throw ScanException.unreadableDocument('JSON parse error: ${e.message}');
    } catch (e) {
      throw ScanException.unknown(e);
    }
  }
}