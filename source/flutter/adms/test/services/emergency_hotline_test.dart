import 'package:adms/core/services/municipality_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Call Rescue (citizen Home) dials the number saved by the municipal admin
/// under Settings > Emergency Hotline. These tests pin down how that raw,
/// admin-entered value is turned into a `tel:` URI.
void main() {
  group('emergencyHotlineUri', () {
    test('dials a plain number as-is', () {
      expect(
        emergencyHotlineUri('911').toString(),
        'tel:911',
      );
    });

    test('strips dashes and spaces from admin-entered numbers', () {
      expect(
        emergencyHotlineUri('0916-123 4567').toString(),
        'tel:09161234567',
      );
    });

    test('keeps the + country prefix', () {
      expect(
        emergencyHotlineUri('+63 916 123 4567').toString(),
        'tel:+639161234567',
      );
    });

    test('returns null when nothing dialable remains', () {
      expect(emergencyHotlineUri(''), isNull);
      expect(emergencyHotlineUri('   '), isNull);
      expect(emergencyHotlineUri('n/a'), isNull);
    });
  });
}
