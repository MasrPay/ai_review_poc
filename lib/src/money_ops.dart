import 'money.dart';

/// Spec: specs/104-money-multiply/spec.md
extension MoneyOps on Money {
  Money times(int factor) => Money(minorUnits * factor, currency);
}
