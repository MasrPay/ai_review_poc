import 'dart:math' as math;

import 'money.dart';

/// Transfer fee: 1% of the amount rounded up to the nearest piaster,
/// at least 1.00 and at most 25.00 in the amount's currency.
///
/// Spec: specs/101-transfer-fee/spec.md
class FeeCalculator {
  const FeeCalculator();

  static const int _minFeeMinor = 100;
  static const int _maxFeeMinor = 2500;

  Money feeFor(Money amount) {
    if (amount.isNegative || amount.isZero) {
      throw ArgumentError.value(amount, 'amount', 'must be positive');
    }
    final onePercentRoundedUp = (amount.minorUnits + 99) ~/ 100;
    final fee =
        math.min(math.max(onePercentRoundedUp, _minFeeMinor), _maxFeeMinor);
    return Money(fee, amount.currency);
  }
}
