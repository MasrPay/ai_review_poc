/// An amount of money in integer minor units (for EGP, piasters).
///
/// Never use `double` for money: binary floating point cannot represent
/// most decimal fractions exactly.
class Money implements Comparable<Money> {
  const Money(this.minorUnits, this.currency);

  /// Creates [Money] from whole major units, e.g. `Money.major(10, 'EGP')`.
  const Money.major(int majorUnits, this.currency)
      : minorUnits = majorUnits * 100;

  /// Zero in the given [currency].
  const Money.zero(this.currency) : minorUnits = 0;

  final int minorUnits;
  final String currency;

  bool get isNegative => minorUnits < 0;
  bool get isZero => minorUnits == 0;

  Money operator +(Money other) {
    _assertSameCurrency(other);
    return Money(minorUnits + other.minorUnits, currency);
  }

  Money operator -(Money other) {
    _assertSameCurrency(other);
    return Money(minorUnits - other.minorUnits, currency);
  }

  bool operator >(Money other) => compareTo(other) > 0;
  bool operator >=(Money other) => compareTo(other) >= 0;
  bool operator <(Money other) => compareTo(other) < 0;
  bool operator <=(Money other) => compareTo(other) <= 0;

  @override
  int compareTo(Money other) {
    _assertSameCurrency(other);
    return minorUnits.compareTo(other.minorUnits);
  }

  @override
  bool operator ==(Object other) =>
      other is Money &&
      other.minorUnits == minorUnits &&
      other.currency == currency;

  @override
  int get hashCode => Object.hash(minorUnits, currency);

  @override
  String toString() {
    final sign = isNegative ? '-' : '';
    final abs = minorUnits.abs();
    final major = abs ~/ 100;
    final minor = (abs % 100).toString().padLeft(2, '0');
    return '$sign$major.$minor $currency';
  }

  void _assertSameCurrency(Money other) {
    if (other.currency != currency) {
      throw ArgumentError(
        'Currency mismatch: $currency vs ${other.currency}',
      );
    }
  }
}
