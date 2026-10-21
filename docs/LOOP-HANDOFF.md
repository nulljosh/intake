# Machaon loop handoff (2026-10-21, afternoon)

## What the loop is

QA the Machaon landing page and app until A+ quality. Each pass: run tests and build, record the live landing and app (headless), fix real bugs, redeploy, re-verify. No subagent fan-out. Portfolio vibe design rules apply: no em dashes, no emojis, flat design with the blue accent. The accent is clrs.cc blue (#0074D9) and the font is Machaon Sans.

## Where things stand (2026-10-21)

- The app says Machaon in sign-in, splash, watch and permission prompts. Targets, bundle ID and the App Store name are unchanged, and the store listing still says Healstack.
- iOS uses the native SwiftUI tab bar. The custom floating bar that covered the Save Note button is gone.
- Insights shows two stat tiles, with the heatmap full width.
- Brand: a stethoscope mark on clrs.cc blue. The brand kit is regenerated and the iOS app icon and accent are wired to it. A new App Store build is needed before the store shows it.
- Font: Machaon Sans, Inter renamed through scripts/gen_font.py (OFL, weights 100 to 700). Used across the web app and the landing. Geist and Plus Jakarta are removed.
- Landing at machaon.jaybulb.com is rebuilt: navy page, blue frame, large thin caps, a blue band, and halftone art of Asclepius, the Greek god of medicine, from five public domain or CC0 Wikimedia Commons works. It shows real iOS screens in the new blue. Deployed to the Cloudflare Pages project healstack and checked live.
- Store, last noted 2026-10-16: iOS 2.3.6 ready for distribution, macOS 2.3.5 in review. Nothing was submitted today.
- Docs: the README still says Healstack in places.

## Next, in order

1. Build and submit a new iOS build so the stethoscope icon and blue accent reach the store.
2. Read the App Review reason on the iOS 2.3.6 flag (open since 2026-10-01) and resolve it, or confirm it cleared.
3. Rename the store listing from Healstack to Machaon once Apple accepts the name, in the same submission.
4. Re-enable Sign in with Apple properly. Blocked on Joshua: Apple Developer portal and Supabase dashboard.
5. Bring the docs to 100 percent. The README and CLAUDE.md still describe the Healstack name in places.

## Restart prompt

```
/loop QA the Machaon landing page and app (~/Documents/Code/machaon) until A+ quality: spotless visuals and every line sound. Each pass: run tests+build, record the live landing and app (record-web / headless, no Chrome), fix real bugs, redeploy, re-verify. No subagent fan-out, no em dashes, no emojis, portfolio vibe design rules from CLAUDE.md (Machaon Sans, clrs.cc blue #0074D9 accent).
```
