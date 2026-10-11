# Intake loop handoff (2026-10-04, evening)

## What the loop is

QA the Intake landing page and app until A+ quality. Each pass: run tests and build, record the live landing and app (headless), fix real bugs, redeploy, re-verify. No subagent fan-out. Portfolio vibe design rules apply (no em dashes, no emojis, Geist font, flat monochrome + blue accent).

## Where things stand (2026-10-04)

- Web 2.4.0 shipped with three-tab Apple Health layout (Summary, Browse, Sharing), new blue heart-stack icon, white light theme, blue accent on dark.
- Tests: 60/60 passing.
- Landing refreshed with real screenshots, iOS marked Live, macOS card says "in review".
- Privacy critical fix: new accounts now start empty instead of being seeded with a hardcoded personal profile.
- Native builds: iOS 2.3.6 approved and live on App Store (READY_FOR_SALE, since 2026-10-04). macOS 2.3.5 IN_REVIEW on same version record, waiting on screenshot feedback.

## Known blockers (open roadmap items)

1. Git history was scrubbed and force-pushed on 2026-10-04, tag included. A fresh clone is clean. GitHub may still serve the old commits by direct link until Support purges them. Delete ~/Documents/healstack-pre-scrub.bundle once satisfied.
2. No database cleanup needed: the only row in dose_profiles is Joshua's own account.
3. App Store name rename to "Intake" was Joshua's pick, but submission is in review so name field is locked until review clears.
4. Three-tab layout exists only on web; native Swift apps still have old layout (port not started).
5. macOS 2.3.5 text cut-off bug noted in Resolution Center (not yet reproduced locally).

## Restart prompt

```
/loop QA the Intake landing page and app (~/Documents/Code/intake) until A+ quality: spotless visuals and every line sound. Each pass: run tests+build, record the live landing and app (record-web / headless, no Chrome), fix real bugs, redeploy, re-verify. No subagent fan-out, no em dashes, no emojis, portfolio vibe design rules from CLAUDE.md.
```
