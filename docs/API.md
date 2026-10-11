# Intake API

Base URL: `https://intake.jaybulb.com`

Intake is local-first: dose logs, biometrics, lab panels and routines live in
the browser's `localStorage`, not on a server. That means there is deliberately
no CRUD REST API over your health data — the HTTP surface is only sync and
billing. **The agent-facing interface is WebMCP** (below), which runs inside the
page and reaches the same data the UI uses.

## HTTP endpoints

### `GET /api/sync` · `PUT /api/sync`

Whole-blob backup and restore of a device's local data, stored in Cloudflare KV.

Auth: `Authorization: Bearer <DOSE_SYNC_TOKEN>`. Requests from browsers are
restricted to the `intake.jaybulb.com` origin.

```bash
curl -H "Authorization: Bearer $DOSE_SYNC_TOKEN" \
  https://intake.jaybulb.com/api/sync

curl -X PUT -H "Authorization: Bearer $DOSE_SYNC_TOKEN" \
  -H 'Content-Type: application/json' --data @backup.json \
  https://intake.jaybulb.com/api/sync
```

`GET` returns the stored blob (`{}` if nothing is stored). `PUT` replaces it
wholesale — it is not a merge, so read before you write.

### `POST /api/stripe`

Creates a Stripe Checkout session for the Pro unlock. Returns `{ url }` to
redirect to.

### `POST /api/stripe-webhook`

Signature-verified inbound endpoint for Stripe. Not for client use.

Auth for user accounts (sign-in, password reset) goes directly to Supabase from
the client; see `src/lib/supabase.js`.

## WebMCP

With the app open in a browser that supports WebMCP, healstack registers tools
on `document.modelContext`. Source: `src/lib/webmcp.jsx`.

### Read-only

| Tool | Does |
|---|---|
| `search_substances` | Search the substance library by name |
| `get_substance` | Full record for one substance, with dosing and interactions |
| `get_dose_log` | Logged doses, filterable by `substanceId`, `route`, `since`, `until` |
| `get_active_doses` | Doses from the last 24 hours |
| `get_biometrics` | Biometric entries and current targets |
| `get_lab_results` | Saved lab panels with out-of-range flags |
| `get_marker_history` | One lab marker over time (omit `marker` to list names) |
| `get_routine_status` | Today's completion count and streak |

### Reversible writes

| Tool | Does |
|---|---|
| `log_dose` | Log a dose (`substanceId`, `dose`, `route` required) |
| `update_dose` | Change fields on a logged dose |
| `delete_dose` | Delete one dose by id |
| `log_biometrics` | Save a day's metrics |
| `log_lab_result` | Save a lab panel; flags are computed from the reference ranges |
| `toggle_routine_item` | Check or uncheck a routine item for today |

### Requires human confirmation

| Tool | Does |
|---|---|
| `delete_lab_result` | Permanently deletes a saved panel |
| `clear_dose_log` | Wipes the entire dose history |

Writes persist immediately. Other open views in the app pick up a change on
their next mount rather than live.
