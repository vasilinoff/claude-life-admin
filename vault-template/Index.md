---
type: index
updated: 2026-01-01
---
# Personal vault

Single source of truth for personal facts and ongoing matters. No secrets here, they live in Keychain.

## Who I am
- [[Person]] — name, date of birth, phone, email
- [[Home]] — address, lease
- [[Documents]] — passport, residence permit, tax and social numbers
- [[Bank]] — IBAN, BIC
- [[Work]] — employer, role, start date

## What we're tracking
| Track | Status |
|---|---|
| [[Example]] | 🔴 waiting for a reply, chase on 2026-01-15 |

## Rules
- A fact lives in one file. Everything else links to it.
- An ongoing matter (dispute, application, claim) is a file in `Tracks/` with `status:` and `updated:`.
- Done → `status: closed`, the file stays.
- No passwords, codes or card numbers. Keychain only.
- `updated:` and the table above are maintained by the `vault-sync.py` hook. Edit `status:` and `note:` in tracks instead.
