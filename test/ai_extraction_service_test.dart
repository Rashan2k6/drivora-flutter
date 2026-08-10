import 'package:flutter_test/flutter_test.dart';
import 'package:drivora_flutter/services/ai_extraction_service.dart';

void main() {
  group('ScanException tests', () {
    test('missingApiKey constructor sets correct error type and strings', () {
      final e = ScanException.missingApiKey();
      expect(e.type, ScanErrorType.missingApiKey);
      expect(e.title, contains('Scanner Unavailable'));
      expect(e.message, contains('currently unavailable'));
      expect(e.hint, isNotEmpty);
    });

    test('noInternet constructor sets correct error type', () {
      final e = ScanException.noInternet();
      expect(e.type, ScanErrorType.noInternet);
      expect(e.title, contains('No Connection'));
    });

    test('timeout constructor sets correct error type', () {
      final e = ScanException.timeout();
      expect(e.type, ScanErrorType.timeout);
      expect(e.title, contains('Timed Out'));
    });

    test('unreadableDocument constructor sets correct error type', () {
      final e = ScanException.unreadableDocument('Blurry photo');
      expect(e.type, ScanErrorType.unreadableDocument);
      expect(e.title, contains('Unreadable'));
      expect(e.originalError, equals('Blurry photo'));
    });

    test('apiError handles customer-facing status messages', () {
      final e401 = ScanException.apiError(401, 'Unauthorized');
      expect(e401.type, ScanErrorType.apiError);
      expect(e401.title, equals('Scanner Temporarily Unavailable'));

      final e429 = ScanException.apiError(429, 'Rate Limit');
      expect(e429.type, ScanErrorType.apiError);
      expect(e429.title, equals('Scanner Temporarily Unavailable'));

      final e500 = ScanException.apiError(500, 'Server Error');
      expect(e500.type, ScanErrorType.apiError);
      expect(e500.title, equals('Scanner Temporarily Unavailable'));
    });
  });

  group('ExtractedDocumentData tests', () {
    test('isEmpty returns true when all fields are null', () {
      final data = ExtractedDocumentData();
      expect(data.isEmpty, isTrue);
    });

    test('isEmpty returns false when at least one field is provided', () {
      final data = ExtractedDocumentData(policyNumber: 'POL-12345');
      expect(data.isEmpty, isFalse);
    });
  });
}
