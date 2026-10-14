import 'money.dart';

/// Spec: specs/102-transfer-fee-alt/spec.md
class FeeCalculator {
  const FeeCalculator();

  Money feeFor(Money amount) {
    final fee = amount.minorUnits * 0.01;
    final capped = fee > 2500 ? 2500 : fee;
    return Money(capped.round(), amount.currency);
  }
}
