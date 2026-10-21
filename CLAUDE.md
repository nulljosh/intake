# Machaon
v2.4.0

Renamed from Dose 2026-07-01 to Healstack, then Intake (2026-10-04), then Machaon (2026-10-21, because the App Store name Intake belongs to another developer). GitHub repo is nulljosh/machaon, domain machaon.jaybulb.com. Bundle IDs, App Group, and URL scheme (dose://) intentionally left as `dose` to avoid re-provisioning/App Store relinking.

Machaon everywhere: app, store listing (iOS 2.4.0 in review), web, machaon.jaybulb.com, repo, font. Old names kept on purpose: Pages project `healstack`, bundle id and App Group `dose`, URL schemes, the `Healstack` Xcode project and scheme, all storage keys. intake.jaybulb.com keeps serving.

## Shipped (2026-06-28)
- [x] ToS checkbox required on register tab, `src/pages/Auth.jsx`, `/tos.html`
- [x] GitHub Sign In button via Supabase OAuth
- [x] GitHub provider enabled in Supabase (spark project) via management API

## Rules
- Machaon Sans (`scripts/gen_font.py`, Inter renamed), clrs.cc blue `#0074D9`, flat, no shadows or gradients. Brand kit: `brand/BRAND.md`
- Mobile-first, bottom nav, safe-area-inset support
- Supabase auth: login, register, password reset (PASSWORD_RECOVERY event flow)
- Interaction checker must warn when logging substance that interacts with active stack
- No emojis

## The loop

Current handoff: `docs/LOOP-HANDOFF.md`. QA the landing and app until spotless.

## Run
```bash
npm run dev       # Dev server
npm test          # Run tests
npm run build     # Production build
./deploy.sh       # Deploy to Cloudflare Pages (direct-upload)
```

## Deploy
Migrated from Vercel to Cloudflare Pages 2026-08-06. Direct-upload via `wrangler pages deploy` (not git-connected, to avoid staleness). Serverless functions ported to Cloudflare Pages Functions (`functions/api/stripe.js`, `functions/api/stripe-webhook.js`, `functions/api/sync.js`). KV namespace binding for sync data (`DOSE_KV`, id `933180aeff6b45e58e39b258b2fbe25b`). Secrets managed via `wrangler pages secret put`; run locally via `wrangler pages dev dist`. Custom domain must be explicitly attached via Pages API (`POST .../pages/projects/healstack/domains`), a DNS CNAME alone is not enough, causes 522 until the domain is registered on the Pages project itself. `DOSE_SYNC_TOKEN` secret set fresh 2026-08-06 (Cloudflare KV was empty pre-migration, Vercel used a separate `@vercel/kv` store, no data migration needed); real app users need this token in their browser's `dose:sync_token` localStorage key. Cloudflare secret updates take ~1-2 min to propagate across all edge PoPs, expect transient 401s on `/api/sync` right after a `wrangler pages secret put`, not a bug.

## Key Files
- src/App.jsx: App shell with routing, OS-aware theme (auto dark/light + manual toggle), nav.
- src/main.jsx: React entry point.
- src/pages/Dashboard.jsx: Active stack and recent dose entries.
- src/components/InteractionChecker.jsx: Interaction checker logic and UI.
- src/data/substances.js: Substance dataset with harm reduction notes and interactions.
- src/index.css: Full design system (portfolio vibe tokens).
- src/design-tokens.css: Token reference (vibed from heyitsmejosh.com).

## iOS
- ios/: SwiftUI iOS app. xcodegen (project.yml). iOS 17+.
- xcodegen generate && xcodebuild build -scheme Healstack -project Healstack.xcodeproj -destination "platform=iOS Simulator,name=iPhone 17 Pro"

## Pending
- .env.local recreated 2026-06-12 (VITE_SUPABASE_* + HEALSTACK_EMAIL/HEALSTACK_PASSWORD), file is gone again as of 2026-06-20, needs recreating.
- Account recovery: real account email is jatrommel@gmail.com (not trommatic@icloud.com). Reset password to that address rather than chasing the icloud reset email further.
- Supabase anon key no longer hardcoded in `ios/Services/AuthService.swift`, now read via `infoPlistValue("SUPABASE_ANON_KEY")` from Info.plist (fixed 2026-06-23).
- Web UI refresh, landing page, and iOS ship are tracked in README Roadmap (Declutter UI, Vibe clone portfolio aesthetic, iOS companion app), not new asks, no changes applied yet.
- Stripe secrets (STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET, real STRIPE_PRICE_ID) not set on Cloudflare, deliberately deferred 2026-08-06 (app is free/personal, $1 CSV-export gate isn't load-bearing). `functions/api/stripe.js`/`stripe-webhook.js` are deployed and respond correctly (400s on missing config, no crashes) but the Pro-unlock flow won't work until these are set.

## project.yml generates files, never edit the generated file

Where a `project.yml` declares an `entitlements:` or `info:` block with `properties:`,
xcodegen **regenerates** that file on every `xcodegen generate`. Editing
`Info.plist` or `*.entitlements` directly there is silently reverted on the next
generate, the build still succeeds, so nothing tells you. This is the mechanism
behind Sign in with Apple repeatedly "disappearing". Put the key in `project.yml`,
then verify against the built artifact, not the source:
`codesign -d --entitlements - <app>` and the app's `Contents/Info.plist`.

Lexly is the exception: it uses explicit `INFOPLIST_FILE` paths with
`GENERATE_INFOPLIST_FILE: NO`, so editing those plists directly is correct there.

Also: a duplicate `entitlements:` key in one target silently drops the first block's
keys (last wins in YAML). That is how litigate briefly lost `app-sandbox` and
`network.client` on macOS.
