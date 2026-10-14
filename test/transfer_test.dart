import 'package:ai_review_poc/ai_review_poc.dart';
import 'package:test/test.dart';

void main() {
  const validator = TransferValidator(dailyLimit: Money.major(1000, 'EGP'));
  const balance = Money.major(5000, 'EGP');
  const none = Money.zero('EGP');

  TransferDecision check(Money amount, {Money sentToday = none}) => validator
      .validate(amount: amount, balance: balance, sentToday: sentToday);

  test('allows a normal transfer', () {
    expect(check(const Money.major(100, 'EGP')), TransferDecision.allowed);
  });

  test('rejects zero and negative amounts', () {
    expect(check(none), TransferDecision.invalidAmount);
    expect(check(const Money(-1, 'EGP')), TransferDecision.invalidAmount);
  });

  test('rejects amounts above balance', () {
    expect(
      check(const Money.major(6000, 'EGP')),
      TransferDecision.insufficientBalance,
    );
  });

  test('allows reaching the daily limit exactly', () {
    expect(
      check(
        const Money.major(100, 'EGP'),
        sentToday: const Money.major(900, 'EGP'),
      ),
      TransferDecision.allowed,
    );
  });

  test('rejects exceeding the daily limit by one piaster', () {
    expect(
      check(const Money(1, 'EGP'), sentToday: const Money.major(1000, 'EGP')),
      TransferDecision.dailyLimitExceeded,
    );
  });

  test('rejects currency mismatch', () {
    expect(
      check(const Money.major(1, 'USD')),
      TransferDecision.currencyMismatch,
    );
  });
}
