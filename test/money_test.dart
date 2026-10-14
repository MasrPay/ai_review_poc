import 'package:ai_review_poc/ai_review_poc.dart';
import 'package:test/test.dart';

void main() {
  group('Money', () {
    test('major constructor converts to minor units', () {
      expect(const Money.major(10, 'EGP').minorUnits, 1000);
    });

    test('adds and subtracts in minor units', () {
      const a = Money(1050, 'EGP');
      const b = Money(25, 'EGP');
      expect(a + b, const Money(1075, 'EGP'));
      expect(a - b, const Money(1025, 'EGP'));
    });

    test('rejects mixed currencies', () {
      expect(
        () => const Money(1, 'EGP') + const Money(1, 'USD'),
        throwsArgumentError,
      );
    });

    test('formats with two decimals and sign', () {
      expect(const Money(1205, 'EGP').toString(), '12.05 EGP');
      expect(const Money(-5, 'EGP').toString(), '-0.05 EGP');
    });
  });
}
