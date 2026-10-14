# Transfer fee

## User story
As the business, we charge a transfer fee so the service covers its costs.

## Acceptance criteria
1. Fee = 1% of the amount, rounded UP to the nearest piaster.
2. Minimum fee is 1.00; maximum fee is 25.00 (same currency as the amount).
3. Zero or negative amounts throw `ArgumentError`.
4. Integer minor units only; no floating point anywhere.
5. Tests cover: below minimum, rounding up, above maximum, zero, negative.

## Security impact
None.

## Regulatory impact
Fee values must match the published tariff (Compliance owns the numbers).
