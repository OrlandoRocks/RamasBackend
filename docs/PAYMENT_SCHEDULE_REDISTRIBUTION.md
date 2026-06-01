# Payment schedule redistribution

## When it runs

Any time a **payment `amount` changes** on update:

- `PATCH /payments/:id`
- `PATCH /contracts/:id` with `payments_attributes`
- **`rails c`**: `payment.update(amount: 1100)` or `payment.update!(...)`

Status-only updates do **not** redistribute.

## Rules

1. Only **`Pendiente`** installments (other than the edited row) are adjusted.
2. **`Pagado`** amounts are never changed.
3. **`Fallo`**, **`Regrezado`**, **`Cancelado`** are not used to absorb changes.
4. Adjustable installments may be reduced to **$0.00** (fully absorbed).
5. **Contract schedule total** (`sum` of all payment amounts) must stay the same after a change; otherwise the update rolls back with an error.

## Behavior (unchanged intent)

- **Increase** on installment A → subtract from other pending rows, **latest due date first**, then earlier.
- **Decrease** on installment A → add to other pending rows, **same order** (latest first).

## Errors

| Error | Meaning |
|-------|---------|
| `UnabsorbedDeltaError` | Not enough pending balance to absorb the change (e.g. all others already at $0.00) |
| `ScheduleTotalMismatchError` | Internal guard: totals did not balance |

API returns **422** with `{ "errors": ["..."] }`.

## Console

```ruby
p = Payment.find(123)
p.update!(amount: p.amount + 100)
#=> other Pendiente rows on the same contract adjust automatically

contract.payments.pluck(:id, :amount, :status)
```

Use `update_without_redistribution!(amount: x)` only for seeds/maintenance.

## Response header

`PATCH /payments/:id` with `amount` may include:

`X-Adjusted-Payments-Count: N`

## Frontend

Copy-paste Vue 2 integration task: **`docs/VUE2_PAYMENT_SCHEDULE_REDISTRIBUTION.md`**
