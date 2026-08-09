import 'package:flutter_test/flutter_test.dart';

import 'package:drivora_flutter/main.dart';
import 'package:drivora_flutter/models/vehicle.dart';

void main() {
  testWidgets('DrivoraApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DrivoraApp());

    // Verify that Drivora title is displayed in AppBar
    expect(find.text('Drivora'), findsOneWidget);
  });

  group('Sri Lankan Plate Number Formatting & Validation', () {
    test('Format 3-letter prefix (XXX-0000)', () {
      expect(Vehicle.formatPlateNumber('cab-1234'), equals('CAB-1234'));
      expect(Vehicle.formatPlateNumber('cbb 5678'), equals('CBB-5678'));
      expect(Vehicle.formatPlateNumber('cbb5678'), equals('CBB-5678'));
      expect(Vehicle.isValidPlateNumber('cab-1234'), isTrue);
    });

    test('Format 2-letter prefix (XX-0000)', () {
      expect(Vehicle.formatPlateNumber('wp-1234'), equals('WP-1234'));
      expect(Vehicle.formatPlateNumber('kv 4321'), equals('KV-4321'));
      expect(Vehicle.formatPlateNumber('kv4321'), equals('KV-4321'));
      expect(Vehicle.isValidPlateNumber('wp-1234'), isTrue);
    });

    test('Format vintage 3-digit numeric prefix (000-0000)', () {
      expect(Vehicle.formatPlateNumber('300-1234'), equals('300-1234'));
      expect(Vehicle.formatPlateNumber('300 1234'), equals('300-1234'));
      expect(Vehicle.formatPlateNumber('3001234'), equals('300-1234'));
      expect(Vehicle.isValidPlateNumber('300-1234'), isTrue);
    });

    test('Format vintage 2-digit numeric prefix (00-0000)', () {
      expect(Vehicle.formatPlateNumber('19-5678'), equals('19-5678'));
      expect(Vehicle.formatPlateNumber('19 5678'), equals('19-5678'));
      expect(Vehicle.formatPlateNumber('195678'), equals('19-5678'));
      expect(Vehicle.isValidPlateNumber('19-5678'), isTrue);
    });

    test('Reject invalid plate formats', () {
      expect(Vehicle.isValidPlateNumber('INVALID'), isFalse);
      expect(Vehicle.isValidPlateNumber('A-123'), isFalse);
      expect(Vehicle.isValidPlateNumber('AAAA-1234'), isFalse);
    });

    test('Vehicle displayName sentence case formatting', () {
      final v1 = Vehicle(
        id: '1',
        plateNumber: 'CAB-1234',
        make: 'toyota',
        model: 'aqua',
      );
      expect(v1.displayName, equals('Toyota Aqua'));

      final v2 = Vehicle(
        id: '2',
        plateNumber: 'WP-1234',
        make: 'HONDA',
        model: 'FIT',
      );
      expect(v2.displayName, equals('Honda Fit'));
    });
  });
}
