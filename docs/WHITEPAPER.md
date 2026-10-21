# Machaon Technical Whitepaper

**v2.3.5** | August 2026

Know what you took, and what it does with everything else you're on.

People on more than one supplement or medication rarely track how they
overlap in time, and the interactions that matter are exactly the ones that
depend on timing: two things active in the body at once, not two things
taken on the same calendar day. Machaon exists to hold that timeline so
nobody has to keep it in their head. It logs doses, shows what's still
active, and warns before you combine two things that interact. Web at
[machaon.jaybulb.com](https://machaon.jaybulb.com), companion
iOS app (bundle ID and `dose://` URL scheme intentionally kept from the app's
former name, Dose, to avoid re-provisioning, since a new scheme would mean
relinking the App Store record for no user-facing gain).

## Interaction Checking

The core mechanic, and the reason the app exists at all. `src/data/substances.js`
holds a curated dataset of substances with known interactions and
harm-reduction notes. When a dose is logged, `InteractionChecker`
cross-references it against every substance currently "active" (dosed within
its known duration window) and surfaces a warning if any pair is flagged,
before the entry is saved rather than after, because a warning shown after
the dose is already taken cannot change anything.

## Data Model

- **Dose entry**: substance, amount, timestamp, notes
- **Active stack**: derived, not stored, any dose whose substance duration
  window still covers "now" counts as active, so the stack is always
  correct for the current moment without a background job to expire entries
- **Dashboard** (`src/pages/Dashboard.jsx`): renders the active stack and
  recent entries from that derived state

## Auth and Backend

Supabase: email/password login, registration, and password reset (listens for
the `PASSWORD_RECOVERY` event to route into the reset flow). No custom
backend, Supabase is the only server dependency, because dose history is
sensitive enough that the fewer systems that touch it, the better.

## Design

Machaon Sans (Inter, renamed by `scripts/gen_font.py`) on a flat page with one
accent, clrs.cc blue `#0074D9`. No shadows, gradients or emojis in the app. Mobile-first with bottom nav and safe-area-inset
support. OS-aware theme (auto dark/light + manual override).

## Companion App

| Platform | Framework | Notes |
|----------|-----------|-------|
| iOS | SwiftUI, xcodegen | iOS 17+, v2.3.4 in review |

## Security / Privacy

Auth and data storage delegated entirely to Supabase (RLS-scoped per user).
No substance data leaves the user's own Supabase rows; no analytics or
third-party trackers.

## License

Apache 2.0, 2026, Joshua Trommel
