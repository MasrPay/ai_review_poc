import 'money.dart';

/// Why a transfer was rejected, or [TransferDecision.allowed].
enum TransferDecision {
  allowed,
  invalidAmount,
  currencyMismatch,
  insufficientBalance,
  dailyLimitExceeded,
}

/// Result of [TransferValidator.remainingAllowance].
///
/// Spec: specs/002-remaining-allowance/spec.md
sealed class AllowanceResult {
  const AllowanceResult();
}

/// The amount still sendable today. Never negative.
final class AllowanceAvailable extends AllowanceResult {
  const AllowanceAvailable(this.remaining);

  final Money remaining;

  @override
  bool operator ==(Object other) =>
      other is AllowanceAvailable && other.remaining == remaining;

  @override
  int get hashCode => Object.hash(AllowanceAvailable, remaining);

  @override
  String toString() => 'AllowanceAvailable($remaining)';
}

/// The allowance could not be computed; [reason] says why.
final class AllowanceRejected extends AllowanceResult {
  const AllowanceRejected(this.reason);

  final TransferDecision reason;

  @override
  bool operator ==(Object other) =>
      other is AllowanceRejected && other.reason == reason;

  @override
  int get hashCode => Object.hash(AllowanceRejected, reason);

  @override
  String toString() => 'AllowanceRejected($reason)';
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

  /// How much more can be sent today, given the total already [sentToday].
  ///
  /// Returns zero (never negative) once the limit is reached or exceeded.
  /// Rejects a currency mismatch or a negative [sentToday] instead of
  /// throwing. Checks run in the same order as [validate].
  ///
  /// Spec: specs/002-remaining-allowance/spec.md
  AllowanceResult remainingAllowance({required Money sentToday}) {
    if (sentToday.currency != dailyLimit.currency) {
      return const AllowanceRejected(TransferDecision.currencyMismatch);
    }
    if (sentToday.isNegative) {
      return const AllowanceRejected(TransferDecision.invalidAmount);
    }
    if (sentToday >= dailyLimit) {
      return AllowanceAvailable(Money.zero(dailyLimit.currency));
    }
    return AllowanceAvailable(dailyLimit - sentToday);
  }
}
