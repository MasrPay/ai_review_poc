import 'package:ai_review_poc/ai_review_poc.dart';
import 'package:test/test.dart';

void main() {
  const validator = TransferValidator(dailyLimit: Money.major(1000, 'EGP'));

  AllowanceResult remaining(Money sent) =>
      validator.remainingAllowance(sentToday: sent);

  group('remainingAllowance', () {
    test('returns limit minus sent', () {
      expect(
        remaining(const Money.major(300, 'EGP')),
        const AllowanceAvailable(Money.major(700, 'EGP')),
      );
    });

    test('returns the full limit when nothing was sent', () {
      expect(
        remaining(const Money.zero('EGP')),
        const AllowanceAvailable(Money.major(1000, 'EGP')),
      );
    });

    test('returns zero when sent is exactly the limit', () {
      expect(
        remaining(const Money.major(1000, 'EGP')),
        const AllowanceAvailable(Money.zero('EGP')),
      );
    });

    test('returns one minor unit when sent is one below the limit', () {
      expect(
        remaining(const Money(99999, 'EGP')),
        const AllowanceAvailable(Money(1, 'EGP')),
      );
    });

    test('returns zero, never negative, when sent is one minor unit over', () {
      expect(
        remaining(const Money(100001, 'EGP')),
        const AllowanceAvailable(Money.zero('EGP')),
      );
    });

    test('returns zero when sent is far above a smaller limit', () {
      const small = TransferValidator(dailyLimit: Money.major(500, 'EGP'));
      expect(
        small.remainingAllowance(sentToday: const Money.major(2000, 'EGP')),
        const AllowanceAvailable(Money.zero('EGP')),
      );
    });

    test('returns zero for a zero limit and zero sent', () {
      const zeroLimit = TransferValidator(dailyLimit: Money.zero('EGP'));
      expect(
        zeroLimit.remainingAllowance(sentToday: const Money.zero('EGP')),
        const AllowanceAvailable(Money.zero('EGP')),
      );
    });

    test('returns zero for a very large sent amount', () {
      expect(
        remaining(const Money(9007199254740991, 'EGP')),
        const AllowanceAvailable(Money.zero('EGP')),
      );
    });

    test('rejects a currency mismatch without throwing', () {
      expect(
        remaining(const Money.major(10, 'USD')),
        const AllowanceRejected(TransferDecision.currencyMismatch),
      );
    });

    test('rejects a negative sent amount as invalidAmount', () {
      final result = remaining(const Money(-1, 'EGP'));
      expect(result, const AllowanceRejected(TransferDecision.invalidAmount));
      expect(
        result,
        isNot(const AllowanceRejected(TransferDecision.currencyMismatch)),
      );
    });

    test('reports currency mismatch before a negative amount', () {
      expect(
        remaining(const Money(-1, 'USD')),
        const AllowanceRejected(TransferDecision.currencyMismatch),
      );
    });

    test('agrees with validate() at the boundary', () {
      const balance = Money.major(1000000, 'EGP');
      final sentValues = [
        const Money.zero('EGP'),
        const Money.major(300, 'EGP'),
        const Money.major(1000, 'EGP'),
        const Money.major(1500, 'EGP'),
      ];
      for (final sent in sentValues) {
        final result = remaining(sent) as AllowanceAvailable;
        final left = result.remaining;
        if (!left.isZero) {
          expect(
            validator.validate(
              amount: left,
              balance: balance,
              sentToday: sent,
            ),
            isNot(TransferDecision.dailyLimitExceeded),
            reason: 'exact remaining for sent=$sent',
          );
        }
        expect(
          validator.validate(
            amount: left + const Money(1, 'EGP'),
            balance: balance,
            sentToday: sent,
          ),
          TransferDecision.dailyLimitExceeded,
          reason: 'one minor unit over for sent=$sent',
        );
      }
    });
  });
}
