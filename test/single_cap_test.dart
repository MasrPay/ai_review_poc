import 'package:ai_review_poc/ai_review_poc.dart';
import 'package:test/test.dart';

void main() {
  const cap = SingleTransferCap(Money.major(500, 'EGP'));

  test('allows small transfers', () {
    expect(cap.isAllowed(const Money.major(100, 'EGP')), isTrue);
  });

  test('rejects large transfers', () {
    expect(cap.isAllowed(const Money.major(600, 'EGP')), isFalse);
  });
}
