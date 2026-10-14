import 'money.dart';

extension MoneySign on Money {
  bool get isPositive => minorUnits > 0;
}
