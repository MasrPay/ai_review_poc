import 'package:ai_review_poc/ai_review_poc.dart';
import 'package:test/test.dart';

void main() {
  test('isPositive', () {
    expect(const Money(1, 'EGP').isPositive, isTrue);
    expect(const Money.zero('EGP').isPositive, isFalse);
  });
}
