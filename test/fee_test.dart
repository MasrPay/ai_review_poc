import 'package:ai_review_poc/ai_review_poc.dart';
import 'package:test/test.dart';

void main() {
  test('charges 1%', () {
    expect(
      const FeeCalculator().feeFor(const Money.major(1000, 'EGP')),
      const Money(1000, 'EGP'),
    );
  });
}
