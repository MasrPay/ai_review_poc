import 'money.dart';

/// Why a transfer was rejected, or [TransferDecision.allowed].
enum TransferDecision {
  allowed,
  invalidAmount,
  currencyMismatch,
  insufficientBalance,
  dailyLimitExceeded,
}

/// Validates a transfer against balance and the daily limit.
///
/// Spec: specs/001-transfer-validation/spec.md
class TransferValidator {
  const TransferValidator({required this.dailyLimit});

  /// Maximum total that can be sent per day (inclusive).
  final Money dailyLimit;

  TransferDecision validate({
    required Money amount,
    required Money balance,
    required Money sentToday,
  }) {
    if (amount.currency != balance.currency ||
        amount.currency != dailyLimit.currency ||
        amount.currency != sentToday.currency) {
      return TransferDecision.currencyMismatch;
    }
    if (amount.isNegative || amount.isZero) {
      return TransferDecision.invalidAmount;
    }
    if (amount > balance) {
      return TransferDecision.insufficientBalance;
    }
    if (sentToday + amount > dailyLimit) {
      return TransferDecision.dailyLimitExceeded;
    }
    return TransferDecision.allowed;
  }
}
