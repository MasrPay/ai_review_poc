import 'package:ai_review_poc/ai_review_poc.dart';
import 'package:test/test.dart';

void main() {
  const calc = FeeCalculator();

  test('applies the minimum fee for small amounts', () {
    expect(calc.feeFor(const Money.major(50, 'EGP')), const Money(100, 'EGP'));
  });

  test('1% exactly at the minimum boundary', () {
    expect(calc.feeFor(const Money.major(100, 'EGP')), const Money(100, 'EGP'));
  });

  test('rounds up to the nearest piaster', () {
    expect(calc.feeFor(const Money(100001, 'EGP')), const Money(1001, 'EGP'));
  });

  test('caps at the maximum fee', () {
    expect(
        calc.feeFor(const Money.major(5000, 'EGP')), const Money(2500, 'EGP'));
  });

  test('keeps the amount currency', () {
    expect(calc.feeFor(const Money.major(200, 'USD')).currency, 'USD');
  });

  test('rejects zero and negative amounts', () {
    expect(() => calc.feeFor(const Money.zero('EGP')), throwsArgumentError);
    expect(() => calc.feeFor(const Money(-1, 'EGP')), throwsArgumentError);
  });
}
