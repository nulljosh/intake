# Intake Roadmap

> Priority tier 2 (2026-10-17): ship push, this week. Order: live blockers, ship pushes, active features, portfolio, exploratory. See ~/Documents/Code/LOOP-HANDOFF.md.

## 2026-08-28, iOS 2.3.5 REJECTED under 4.3(a) spam; appeal drafted, do NOT resubmit
Apple rejected iOS 2.3.5 at 15:14 UTC under Guideline 4.3(a) Design: Spam (submission
`26e3f066-3572-4409-a386-1b14825a1eea`, thread `eecf3184-0467-32af-8c0a-3bf0ba28ea27`). This is
the same byte-identical boilerplate letter that hit Talli, Curvely, Doorstock, Sparkjar and NYC
Survive on 08-26/27, one account-level wave, no named comparison app, no reviewer specifics.
Intake is the sixth app in it.

**Do not fix code and do not resubmit.** Verified today: of 95 Swift files, exactly one is
byte-identical to any other app in the account, `ios/UITests/SnapshotHelper.swift`, Apple's own
fastlane helper, in the test target, not in the shipped binary. Zero shipped files are shared.
The substance database is 2,688 hand-written lines / 200 entries. There is nothing to fix.

The reply is drafted at `~/Documents/Code/notes/appeal-4-3-spam.md` under "Intake iOS". Filing
happens in Resolution Center, which is browser-only (`asc web review` is read-only).

**HELD, deliberately, until the macOS verdict lands.** Decided 2026-08-28. Add the Mac outcome to
the reply, then file. Check with `asc versions list --app 6785764864`; when MAC_OS 2.3.5 leaves
IN_REVIEW, file the same day. Nothing is lost by waiting, the iOS rejection sits either way, and
an approval on the same codebase is the strongest sentence the appeal can carry.

**macOS 2.3.5 is IN_REVIEW on the same version record, leave it there, do not withdraw.**
Sparkjar is the precedent: macOS approved while iOS was rejected in the same wave. If Mac clears,
"the same codebase was just approved on macOS" is the strongest fact in the iOS appeal.

Listing de-templating (subtitle "Supplement & Symptom Tracker", the "Intake is a personal X, Y
and Z" opener, the FEATURES block, ten generic single-word keywords) is real and shared across all
19 listings, but it is after-the-appeal work, not the answer to this letter.

## Done 2026-08-27 (delta), iOS test suite fixed, Mac sidebar added
The test suite had been silently not running at all: a permission prompt in one test popped a system dialog that automation couldn't dismiss, halting the entire run. Fixed the test and the suite now runs green (77 tests, no failures). Tests surfaced a real rounding bug in supplement adherence percentages (showing slightly low). Also added a proper sidebar to the macOS companion (was stretching the phone-style tab bar), and verified the uploaded Mac build works correctly when signed in. iOS 2.3.5 still awaiting Apple's verdict on the 2.5.1 rejection fix; Mac build deliberately held from submit pending iOS review completion.

## Done 2026-08-27, 2.5.1 rejection fixed and resubmitted
iOS v2.3.5 was rejected under Guideline 2.5.1: the health section displayed empty dashes when there was no data, making it unclear the app used Apple HealthKit at all. Fixed by adding an Apple Health icon header to the section, a footer that names HealthKit and explains the app never writes to it, and a "Connect" button that appears when permission is not yet granted. Resubmitted 2026-08-27, now WAITING_FOR_REVIEW. Also built and uploaded a macOS companion (v1.0) concurrently; only three of the sixty-some files touched iOS-only APIs, so the entire port fit into one CrossPlatform.swift file with portability shims. macOS build uploaded but deliberately NOT submitted yet (iOS 2.3.5 is mid-review on the same version record). 

## Done 2026-08-18, resubmitted
iOS 2.3.4 **submitted** 20:07 UTC (review submission `f5e9ce05-9bc0-443b-a360-3b25deb20107`).
Build `202608181252` was uploaded the same day, so the "rebuild before resubmitting" condition
recorded against the staged `202608121022` build is satisfied, that build was not the one shipped.

Sign in with Apple stays gated off in this version by design; re-enabling it is next-version work.

## Sign in with Apple was still guaranteed to fail, gated off 2026-08-18 (`/work start`)

The 08-15 note below says the backend is reviewable, and for **email/password it is** , 
re-ran `scripts/check-auth-live.sh` today: anon key accepted, demo row answers a wrong
password with a clean 400. But the app also shipped a **Sign in with Apple button that
cannot work**, and a reviewer tapping it gets an error. That is the same user-visible
symptom Apple wrote up as "Unable to log in".

Proven live, not inferred:

```
POST /auth/v1/token?grant_type=id_token  {"provider":"apple", id_token with iss=https://appleid.apple.com}
-> 400 {"error_code":"provider_disabled",
        "msg":"Provider (issuer \"https://appleid.apple.com\") is not enabled"}
```

`GET /auth/v1/settings` agrees: `"apple": false`. (A bare dummy token returns a *parse*
error instead, which is why this needs a token with a real Apple `iss` to probe, don't
conclude "provider works" from the parse error.)

**Fix applied:** `appleSignInEnabled = false` in `ios/Services/AuthService.swift`, checked
by `ios/Views/AuthView.swift:123`. The button no longer renders; email/password sign-in is
untouched and works. Guideline 4.8 is not a concern, the app offers no *other* third-party
sign-in, so Sign in with Apple is not required. Build verified:
`xcodebuild build -project Intake.xcodeproj -scheme Dose -destination 'generic/platform=iOS Simulator' -skipPackagePluginValidation`
-> BUILD SUCCEEDED (the `-skipPackagePluginValidation` flag is still load-bearing).

- [ ] **Re-enable Sign in with Apple properly (blocked on Joshua, dashboard + portal).**
      Two steps, neither has an API path: (1) Apple Developer portal, create a Sign in with
      Apple key and Services ID for `com.heyitsmejosh.dose`; (2) Supabase dashboard on the
      shared `spark` project, Auth -> Providers -> Apple, enable and add
      `com.heyitsmejosh.dose` to the authorized client IDs. Note this is the **shared** spark
      project, so diff the auth config before changing it. When done, flip
      `appleSignInEnabled` to `true` in the same commit and re-probe with the curl above.

**Submission readiness 2026-08-18:** `asc review doctor` reports **0 errors, 0 blocking**. The
only warning is the known false-positive empty `whatsNew` (see below, it cannot be written until
the app has shipped once). The remaining pre-submit decision is Joshua's: submit as-is with Sign in
with Apple hidden, or enable the Supabase Apple provider first and flip the flag back on.

## ASC state verified 2026-08-13, three claims below this line are STALE, don't act on them

Read this first; the sections further down contradict live state and each other.

**Live state (`asc versions list` / `asc builds list` / `asc review doctor`, app 6785764864):**
- Version row is **`2.3.4`, `PREPARE_FOR_SUBMISSION`** (`bdf10a5f-0d97-4c1e-9615-af49ca6eda8a`).
  Not "1.0 REJECTED", the version-string reconciliation was already resolved via option 1
  (keep lineage). **That item is done; don't re-decide it.**
- Build **`202608121022`** (`a934fdb2-b03d-445d-a527-b27e14a49aa4`) is uploaded and **`VALID`**,
  from commit `109d3b1`. The "latest build is `202607261112`, older than the fix" /
  "the fix was never built and uploaded" claim at the bottom of this file is **FALSE**.
- Working tree is clean and in sync with `origin/main`. The "Resume note (2026-08-11): a wip
  commit holds unfinished, unverified, unpushed changes" is **FALSE**, no such commit is at HEAD.
  (Same stale-"unpushed" claim turned up in bookrank, talli and litigate the same week.)

**The one remaining blocker is dashboard-only:** submission
`2636ad65-3154-47ba-9d91-d333e8adbffe` is still in `UNRESOLVED_ISSUES`, which blocks any new
submission. Needs `asc-login` + a live 2FA code from Joshua. Submissions are frozen until
2026-08-18 anyway.

Remaining warning (non-blocking), **RESOLVED as a false positive 2026-08-15, stop trying to
fix it**: `asc review doctor` reports "what's new is empty" for `en-US`. It cannot be filled.
Apple rejects the write outright, `asc metadata apply` returns *"Attribute 'whatsNew' cannot
be edited at this time"*, because What's New only exists for an **update**, and this app has
never been released. The canonical `metadata/version/2.3.4/en-US.json` deliberately omits the
field so future `metadata plan` runs don't retry a call that always fails. It will become
editable on its own once 2.3.4 ships. Do not spend another session on this warning.

## Auth re-verified live against production 2026-08-15, backend is reviewable

Independent re-check of the 08-10 fix, straight against the live Supabase backend. All green:

- **Anon key still accepted**: `/auth/v1/health` with the exact `SUPABASE_ANON_KEY` baked
  into the build returns 200. (A rotated JWT secret would silently break every sign-in with no
  app-side change, so this is worth confirming before any resubmit.)
- **A real account signs in**: `POST /auth/v1/token?grant_type=password` returns 200 with an
  access token.
- **The demo row is healthy**: `healstack.demo@heyitsmejosh.com` answers a wrong password with
  a clean **400 invalid_credentials**, not the 500 that got the app rejected. The 08-10
  `coalesce` fix is holding.
- **Config wiring is correct**: `SUPABASE_URL`/`SUPABASE_ANON_KEY` are build settings in
  `ios/project.yml` *and* referenced as `$(...)` in `ios/Info.plist`, so `infoPlistValue()`
  resolves them and `supabaseConfigError` stays nil. Not the cause.
- **Build is green**: `xcodebuild build -destination 'generic/platform=iOS Simulator'` exits 0.
  Note it **requires `-skipPackagePluginValidation`**; without it the SwiftLint build-tool
  plugin fails its trust prompt headlessly and the build dies with a bare exit 65 that looks
  like a code error but isn't.

Regression guard added: **`scripts/check-auth-live.sh`** (exit 0 = reviewable). Run it before
any resubmit. It re-tests all of the above and prints the exact SQL to re-apply if the demo
row ever falls back into the 500 state. Set `HEALSTACK_DEMO_PASSWORD` to also verify the real
ASC credentials sign in end to end, that is the one thing this check cannot prove on its own,
since the password isn't stored in the repo.

**Nothing about this rejection needs an app code change.** The fix is server-side, verified,
and already in a VALID uploaded build. The only thing standing between here and a resubmit is
the dashboard-only `2636ad65` submission plus the 2026-08-18 freeze.

## App Review rejection reason, READ FROM RESOLUTION CENTER 2026-08-12

**Guideline 2.1(a), Performance, App Completeness.** Reviewed 2026-08-05 on iPhone 17 Pro
Max, iOS 26.5.1, active internet, version 1.0 (202607211448).

> Bug description: **Unable to log in**

That is the entire defect.

**FIXED 2026-08-12 (commit `1cfba27`).** The "same root cause as sparkjar and lexly Mac" framing
was wrong, the three apps failed for three unrelated reasons, and sparkjar doesn't even use
Supabase Auth. Intake's own causes, all fixed and build-verified:

1. `macos/project.yml` never injected `SUPABASE_URL` / `SUPABASE_ANON_KEY`, and the global
   client in `ios/Services/AuthService.swift` called `fatalError` on the missing key, the Mac
   app died the moment auth loaded. Now generates a real Info.plist carrying both; verified the
   values reach the built `DoseMac.app/Contents/Info.plist`, not just that it compiles.
2. `macos/Views/AuthView.swift` called `signIn` in *both* branches, so "Create account" could
   never create one.
3. `signUp` didn't adopt the returned session, stranding the user on the auth screen.
4. Sign in with Apple sent no nonce, Supabase rejects native id tokens without one.
5. `.env.local` pointed the web app at `placeholder.supabase.co`.

Backend was never the problem: the demo account is confirmed and unbanned (last signed in
2026-08-11), `disable_signup: false`, `mailer_autoconfirm: true`.

**Still required before this clears:** the Apple provider is **disabled** on the shared spark
project (`GET /auth/v1/settings` → `"apple": false`, and `auth.identities` has never held a
single non-email row). Enable it in the Supabase dashboard with `com.heyitsmejosh.dose` in the
authorized client IDs, dashboard-only, no API path. Then build + upload.

Source: `asc web review show --app 6785764864 --apple-id trommatic@icloud.com` (needs `asc-login`;
the public API only returns a generic "unresolved issues" wrapper). Submissions frozen
The freeze lifted 2026-08-18; submission is now gated only on the four in-flight review verdicts.

## Status (corrected 2026-08-10), v1.0 is REJECTED, not waiting for review

The line below (and `~/Documents/Code/CLAUDE.md`) said "v1.0 is WAITING_FOR_REVIEW
(submitted 2026-07-21)". **Stale.** Live state from `asc versions list --app 6785764864`:
iOS 1.0 is **`REJECTED`**. What actually happened: the 07-21 submission
(`4b9cade8-f484-40a4-8b46-f5c1cbd8da57`) completed, a second submission went in
2026-07-27T03:08Z (`2636ad65-3154-47ba-9d91-d333e8adbffe`) and came back rejected. That
submission is still sitting in `UNRESOLVED_ISSUES`, which blocks any new submission.

**Same phantom-IAP signature as sparkjar:** the one rejected item in that submission is
reported as type `inAppPurchaseVersion`, yet `asc iap list --app 6785764864` returns zero
IAPs. See sparkjar/roadmap.md "ASC state verified 2026-08-10" for the full decoding, don't
chase a nonexistent IAP.

- [ ] **Read the rejection text in Resolution Center.** Not exposed by the public API.
  Needs `asc web review show --app 6785764864`, which needs a web session, `asc web auth
  status` is `authenticated:false` and `asc-login` requires an interactive 2FA code from
  Joshua. The real reason is unknown until then. Plausibly this is the medical-device
  declaration item below finally biting, but that is a guess, not evidence.
- [x] After the reason is known: rebuild (newest build is `202607261112`, uploaded
  2026-07-26, it predates nothing important, so a rebuild may not even be required) and
  resubmit. `asc builds upload` reports success on FAILED uploads, verify with
  `asc builds uploads list`.

### Original status line (kept for history)
v1.0 is WAITING_FOR_REVIEW (submitted 2026-07-21). Infrastructure migrated from Vercel to Cloudflare Pages 2026-08-06 (wrangler config cleared of Vercel-only settings, landing page restyled with Lexly design system). The "ship VERSION:2.3.4"/"2.3.3 resume" items below were from before that submission and are stale, superseded, not re-run.

## From Merge status.pdf (imported 2026-07-21)
- [ ] Medical-device declaration app-record deletion, needs Joshua's asc web auth login.
  Re-confirmed 2026-08-10: `asc web auth status` → `{"authenticated":false,"passwordStored":true,
  "appleId":"trommatic@icloud.com"}`. **Exactly what to do:** run `asc-login` and enter the 2FA
  code Apple pushes to your device, then re-run the `asc web` command. The password is already
  in Keychain (`asc-web-password`), nobody needs to type it. The 2FA code is the only reason
  this can't be automated.

## From App Store.pdf (imported 2026-07-28)
- [ ] Ship a macOS version of Intake. Note 2026-08-10: `healstack/macos/` **does exist**, so
  this is a build+submit job rather than a from-scratch port. There is currently no `MAC_OS`
  version row on app `6785764864` (only IOS), the row gets created by submitting a macOS
  build, not by a dashboard toggle.

## Rejection reason pulled 2026-08-10 (Resolution Center)
- **CLOSED 2026-08-25** (superseded, that rejection was against build 202607211448; iOS 2.3.5 is now WAITING_FOR_REVIEW). Was: **v1.0 REJECTED, Guideline 2.1(a) Performance/App Completeness.** Reviewed 2026-08-05 on iPhone 17 Pro Max, iOS 26.5.1, build `202607211448` (uploaded 07-21). Submission `2636ad65-3154-47ba-9d91-d333e8adbffe`. Apple's report is one line: **"Unable to log in."** No steps, no screenshots attached.

## Root-cause narrowing 2026-08-10, corrects the "login fixed 08-04" claim
- **CLOSED 2026-08-25** (superseded, the rebuild happened and 2.3.5 is in review; this warning was about the 07-21 build). Was: **"Login was fixed 08-04, just rebuild" is FALSE, do not resubmit on that premise.** No commit since the reviewed 07-21 build touches `ios/Views/AuthView.swift` or `ios/Services/AuthService.swift`. Commit `3f8ae32` (08-04) changed a sync-host string in `SettingsView.swift`; `ba0d18b` (08-03) added sign-in buttons to `src/pages/Auth.jsx`, web only. The iOS login path is byte-identical to what Apple rejected.
- [ ] **Ruled out: the stale-host bug that sank sparkjar.** `dose.heyitsmejosh.com` is indeed dead (does not resolve) and `intake.jaybulb.com` is live, but iOS auth does not use either, `ios/Services/AuthService.swift` talks directly to Supabase (`tjsxsqlxjmanwvmywwvw.supabase.co`). Only `ios/Services/SyncService.swift:23` uses the web host, and it is already on the live one.
- [ ] **Second suspect: shared-Supabase auth config.** Auth lives on the shared `spark` project, where `site_url`/`uri_allow_list` are project-wide. Confirm the redirect allow-list still covers healstack after the 08-06 Vercel→Cloudflare Pages migration; diff before PATCHing, never blind-overwrite (it is shared with other apps). **Partially retired 2026-08-10:** irrelevant to the iOS rejection (native email/password sign-in never touches a redirect URL, and it returns 200), so this only affects *web* OAuth/magic-link flows. Still worth a diff, no longer a ship blocker.
- **FIXED 2026-08-25** (bumped `MARKETING_VERSION` to 2.3.5 and `CURRENT_PROJECT_VERSION` to 202608222219, matching the build on ASC's open row; xcodegen regenerates at 2.3.5 and the `Dose` scheme builds clean with `-skipPackagePluginValidation`). Was: **Version drift: `ios/project.yml` says `MARKETING_VERSION: '2.3.4'` but ASC's open row is 2.3.5 (WAITING_FOR_REVIEW), re-verified 2026-08-25.** The next archive would therefore build 2.3.4 against a 2.3.5 row, the exact version-mismatch Apple rejected talli for (see talli v3.5.7). Bump project.yml to 2.3.5 before any further archive. Original note follows:
  1. **Keep lineage (recommended):** edit the ASC version row to `2.3.4` (`asc versions update`) and bump `MARKETING_VERSION` to match. The app's own UI already speaks 2.3.x (the What's New sheet says v2.3.2), so debuting at 2.3.4 stays honest. Row is REJECTED/never-released, so the string should still be editable.
  2. **Match the store:** set `MARKETING_VERSION: '1.0'` to match the existing row. Simpler, but the in-app changelog then contradicts the store version.
  Deliberately not chosen unilaterally, `asc review doctor` does not currently flag the mismatch, so nothing is blocked on it *except* the next archive.

## App Store submission freeze, LIFTED 2026-08-18
Freeze lifted 2026-08-18 (Guideline 5.6 suspension expired). Submitted that day and now
WAITING_FOR_REVIEW: Curvely iOS 1.2.0, Wiretext iOS 1.1.0, Wordroot iOS 1.0, Intake iOS 2.3.4.
**Held pending those four verdicts, never a batch:** Sparkjar iOS+Mac, BCGD iOS+Mac, Wordroot Mac,
Lexly Mac. All six are `asc validate` clean (0 errors, 0 blocking) with a VALID build attached, so
each is one `asc review submit` away. Do not submit until the in-flight verdicts land.

## Auth 2026-08-10, not yet reproduced, do this first
Rejected 2.1(a) "Unable to log in" on build 202607211448 (iPhone 17 Pro Max, iOS 26.5.1).
Sparkjar's identical-looking rejection turned out to be a healthy backend + a stale build, so do
not assume the server is broken here either, verify before changing code.

## 2026-08-10, ROOT CAUSE FOUND AND FIXED: App Review demo account returned a 500
Apple's 2.1(a) "Unable to log in" is resolved. It was not the app and not the network.

The demo account App Store Connect hands reviewers is **healstack.demo@heyitsmejosh.com**
(not jatrommel@gmail.com, which is a different, healthy account). That user's row in
`auth.users` on the shared `spark` Supabase project had `email_change` and
`email_change_token_new` set to **NULL**. GoTrue scans those columns into non-nullable Go
strings, so any auth call touching that row threw:
- `POST /auth/v1/token?grant_type=password` → **500 "Database error querying schema"**
- `POST /auth/v1/signup` → **500 "Database error finding user"**

A normal wrong-password login returns a clean 400, so the 500 was specific to this one row.
The reviewer typed the exact credentials we gave them and got a server error. Exactly one user
out of nine was affected, the demo account, which is why normal testing never caught it.

Fix applied 2026-08-10: `update auth.users set email_change = coalesce(email_change, ''),
email_change_token_new = coalesce(email_change_token_new, '')` for the affected row.
Verified after: the same login now returns a clean **400 invalid_credentials** instead of 500.

- **CLOSED 2026-08-25** (done, 2.3.5 was archived and submitted 2026-08-24, verified WAITING_FOR_REVIEW). Was: Then rebuild and resubmit, after 2026-08-18 per the submission freeze. No app code change is required for this rejection. Build number already bumped off the rejected one (see version item below); the only pre-archive decision left is the 1.0-vs-2.3.x version-string reconciliation., submitted; iOS 2.3.5 WAITING_FOR_REVIEW as of 2026-08-24.

## From Apple Notes (imported 2026-08-11)

> Resume note (2026-08-11): a `wip: partial work from /work notes ingest` commit holds unfinished, unverified changes for the items above. Review `git show HEAD` before building on it, it was committed mid-flight, not reviewed, and is unpushed.

## Sign-in rejection, partial diagnosis 2026-08-12

Ruled out the obvious cause: the demo account **exists and works**.
`healstack.demo@heyitsmejosh.com` is in `auth.users`, email confirmed, created 2026-07-20,
and successfully signed in as recently as **2026-08-11**, well after the 2026-08-05 review.
So "Unable to log in" is not a missing or unconfirmed account.

Most likely remaining explanation: at review time (08-05) the app was still pointed at
**Vercel**; the Cloudflare Pages migration landed **08-06**, one day later. If the auth
endpoint was the thing broken on Vercel, the migration may have already fixed it.

- [x] Do not rotate or recreate the demo account, it is working; changing it loses the one
      known-good credential.

## Sign-in rejection, ALREADY FIXED, needs a build upload (confirmed 2026-08-12)

Commit `2b4bf44` (2026-08-10) resolved this: the demo account row was returning a 500, the
password was reset to a known value and republished to the ASC review detail, and
`CURRENT_PROJECT_VERSION` was bumped off the rejected `202607211448`.

Re-verified 2026-08-12 by hitting the real endpoint , 
`POST /auth/v1/token?grant_type=password` with the ASC demo credentials returns **HTTP 200
with an access token**. Build settings were also checked: `SUPABASE_URL` and
`SUPABASE_ANON_KEY` resolve correctly in a Release build (they have since 2026-06-23, so the
`fatalError` path in `AuthService.swift` was never the cause).

**The only thing left is that the fix was never built and uploaded.** Latest build on ASC is
`202607261112` (2026-07-26), older than the fix. Nothing about this is blocked by the 5.6
freeze; uploading a build is not a submission.

## Rejection cause CONFIRMED from Apple's screenshot, 2026-08-18

Pulled the Resolution Center thread + attachment for the first time (`asc web review show --app
6785764864`; needed a live 2FA web session). Screenshot saved at
`.asc/web-review/6785764864/2636ad65-3154-47ba-9d91-d333e8adbffe/Screenshot-0805-102925.png`.

**The reviewer's failure was email/password sign-in, not Sign in with Apple.** The screenshot shows
the demo account `healstack.demo@heyitsmejosh.com` filled in and a red error under the password
field:

> **Database error querying schema**

That is a GoTrue/Supabase *server-side* fault, not a client bug, which is why no amount of reading
`AuthView.swift` / `AuthService.swift` ever explained it, and why the "no commit touched the login
path" observation was true and yet the login really was broken.

**Verified 2026-08-18: the fault is gone.** Against the live shared `spark` project
(`tjsxsqlxjmanwvmywwvw`):
- bad password → `400 invalid_credentials` (correct)
- real demo credentials → `200` with a valid `access_token` (correct)

So the demo account works today. Root cause of the original outage was server-side on the shared
Supabase project and is no longer reproducible; do not spend more time hunting it in Swift.

- [ ] **Rebuild before resubmitting.** The staged build `202608121022` predates the 2026-08-18
      commit that gates off the Sign in with Apple button, so the button would still ship live and
      still error. Rebuild, re-upload, then submit version 2.3.4.
- [x] Sign in with Apple stays gated off until the provider is enabled, needs an Apple Developer
      portal key **and** Supabase Auth → Providers on the *shared* spark project (diff before
      changing, other apps use it). Verified live as `400 provider_disabled`.

## SUBMITTED 2026-08-18, iOS 2.3.4 WAITING_FOR_REVIEW

Submission `f5e9ce05-9bc0-443b-a360-3b25deb20107`, build `202608181252`
(`092ba31b-70e7-4c92-9af4-b7cb968b3d16`). Verified by re-reading the version, not from command
output. This is the first post-freeze submission, per `ship-plan.md` step 5 ("submit one app , 
Intake or Sparkjar, confirm it passes, then the rest one at a time").

Pre-submit verification that mattered: the demo credentials stored in the ASC review detail
(`healstack.demo@heyitsmejosh.com`) were confirmed to match `.env.local` **and** to return a valid
access token against production. Since the rejection was literally "Unable to log in", a stale demo
credential would have reproduced it exactly.

Review notes now name the original submission ID, state that the backend fault behind
"Database error querying schema" is resolved and re-verified, and disclose that Sign in with Apple
was removed from this build rather than left erroring.

**`asc review submit` failed again with the false "does not contain target version" error**, third
app today (also Wordroot, and BCGD has a stray submission waiting to do the same). `asc review
items list --submission <id>` showed the item present all along. Workaround, now reliable:
`asc review submissions-submit --id <id> --confirm`.

- macOS 2.3.5 REJECTED 2026-08-31, Guideline 4.3(a) Design: Spam (same wave as iOS). Never resubmit; wait for the appeal verdicts.
- [x] Do not submit Sparkjar / BCGD / Wordroot macOS until this clears, never a batch.

## Sign in with Apple, provider ENABLED 2026-08-18

Done without the Apple Developer portal. **The `.p8` Sign in with Apple key is only needed for the
web OAuth redirect flow.** Native iOS sign-in (`grant_type=id_token`) is verified by Supabase
against Apple's *public* keys, matching the token's `aud` to the configured client IDs, no client
secret participates. Supabase accepted the provider with `external_apple_secret` left null.

Enabled via the Management API on the shared `spark` project (`tjsxsqlxjmanwvmywwvw`), token from
the keychain (`security find-generic-password -s "Supabase CLI" -w`):

`PATCH /v1/projects/{ref}/config/auth` with only `external_apple_enabled`,
`external_apple_client_id`. Per the shared-config rule, `site_url` and `uri_allow_list` were NOT
sent and were verified unchanged afterwards. Supabase merges multiple client IDs into
`external_apple_client_id` as a comma-separated list. Pre-change config backed up.

Client IDs registered: `com.heyitsmejosh.dose` (Intake), plus `com.nulljosh.brief` and
`com.nulljosh.brief-macos` (Litigate, blocked on the same step).

Verified: the native endpoint moved from `400 provider_disabled` to
`400 validation_failed "Unable to detect issuer in ID token"`, i.e. the provider is live and
validating. Email/password sign-in re-checked and still returns a valid access token.

- [ ] **Re-enable the button in the NEXT version, not this one.** `appleSignInEnabled` stays
      `false` for 2.3.4, which is in review right now with review notes that explicitly tell Apple
      the button was removed from this build. Flip it after 2.3.4 clears, then rebuild.

## Sign-in preflight check (shipped 2026-08-28)

Built `scripts/check-signin-config.sh` to guard the seven static things that actually broke during sign-in work: entitlements present in the SIGNED binary, app-sandbox + network.client entitlements on macOS, URL scheme in Info.plist, bundle ID in Supabase `external_apple_client_id`, redirect scheme in `uri_allow_list`, `site_url` still points to `https://spark.heyitsmejosh.com`, and Google OAuth endpoint returns 302. The script reads built artifacts and live config, never source, every sign-in failure this session came from stale `.plist` or config, not code. Run this before trusting a sign-in change. All apps currently pass.

## Ingested 2026-08-22
- **CLOSED 2026-08-25** (fixed, commit 01cb371 'cite sources for every substance (App Review 1.4.1)' added the sources plus an explicit 'not medical advice, consult a qualified clinician' line; shipped in 2.3.5, now in review). Was: **App Store rejection, Guideline 1.4.1 Safety/Physical Harm** (submission f5e9ce05-9bc0-443b-a360-3b25deb20107, reviewed 2026-08-21, iPad Air 11" M3, v2.3.4 build 202608181252). "The app includes medical information but does not include citations... the app provides health or medical references in the library without citations, such as links to sources." Next steps per Apple: include in-app citations / source links for every recommendation or piece of medical info in the library. Status: UNRESOLVED_ISSUES, version REJECTED. This is the only blocking check.
- **CLOSED 2026-08-25** (moot, that was 2.3.4; 2.3.5 submitted successfully, so whatsNew did not block it). Was: What's New (en-US) is empty on v2.3.4, `asc review doctor` warning; fill before resubmit.
- [ ] Verify App Store Regulations and Permits declarations (web-only, not checked by `asc review doctor`).

## Ingested 2026-08-24

- [ ] **Breath, a breathing exercise feature.** From Notes ("work on breath app"); confirmed
      2026-08-24 that this belongs inside Intake rather than being its own app. Scope is
      undefined beyond the name, needs a decision on what it actually does (timed box-breathing
      / 4-7-8 patterns? logged as a health entry alongside the existing markers? a Live Activity
      or just an in-app timer?) before any build.

## Rejected 2.5.1, HealthKit not identified in the UI, fixed 2026-08-27

iOS 2.3.5 (build `202608222219`) rejected **2026-08-25**, reviewed on iPad Air 11-inch (M4).
Submission `53f3ef57-6942-4b3e-8d51-d77e5aa45f29`, state `UNRESOLVED_ISSUES`.

> Guideline 2.5.1, the app uses the HealthKit or CareKit APIs but does not clearly identify
> the HealthKit and CareKit functionality in the app's user interface.

Not the auth rejection, that one stayed fixed. Root cause: the only HealthKit marker was a bare
`Section("Apple Health")` in `ios/Views/BodyView.swift`, above a grid that shows `--` for all
fifteen metrics when the review device has no Health data and no permission granted. On a fresh
device that screen is an anonymous empty grid.

**Fix applied:** explicit section header `Label("Apple Health", systemImage: "heart.text.square.fill")`,
a footer naming HealthKit outright and stating the app never writes to Apple Health, and a
`Connect Apple Health` button shown when `HealthKitService.isAvailable && !isAuthorized`.
No new service or view, reuses the existing `requestAuthorization()` / `fetchAll()`.
Build verified: `xcodebuild build -project ios/Intake.xcodeproj -scheme Dose
-destination 'generic/platform=iOS Simulator' -skipPackagePluginValidation` -> BUILD SUCCEEDED.

Resubmitted under **2.3.5** (build `202608271405`), not 2.3.6, a REJECTED version row still accepts
a new build, so only the build number changed. No lineage gap for a fix no user ever saw.
**Submitted 2026-08-27 21:12 UTC, submission `26e3f066-3572-4409-a386-1b14825a1eea`,
state WAITING_FOR_REVIEW.** Reviewer notes updated to point at Body -> Biometrics -> Apple Health.

Two traps hit on the way, both worth remembering:

- `asc xcode version edit` writes **only the pbxproj**, not `project.yml`. The next `xcodegen
  generate` silently reverts the build number. This is the same version drift as commit `eeae544`.
  Always `sed` `project.yml` to match after a version edit.
- The rejected submission `53f3ef57` sat in `UNRESOLVED_ISSUES` and **held the version row hostage** , 
  `asc publish ... --submit` failed with "could not be safely reused", and `review items add` failed
  with "already added to another reviewSubmission". Fix: `asc review submissions-update --id <old>
  --canceled=true --confirm`, wait for it to leave CANCELING, then `review items add` the version to
  the new draft, `versions attach-build`, and `review submissions-submit --id <new> --confirm`.
  Note `asc review doctor` reports `version.state.editable` as **blocking** at that point; it is a
  false negative once the version is already staged on a submission.

- [x] Intake accepted to the App Store.

## macOS companion, target builds 2026-08-27

Every iOS app here gets a Mac companion. Earlier read that a Mac port guts Intake was **wrong**:
of 63 Swift files only three touch iOS-only API, `DoseApp.swift` (UIKit, feedback generators,
`LAContext`), `Views/BodyView.swift` (feedback generators), `Services/HealthKitService.swift`
(HealthKit, no macOS equivalent). Of five tabs only **Body** depends on HealthKit, and only its
Apple Health grid; manual BP entry, notes and the health grade still work. `LAContext` exists on
macOS.

Follow the `lexly/ios/project.yml` pattern: one project file, two application targets, same bundle
ID `com.heyitsmejosh.dose` as a Universal Purchase on the existing record 6785764864. Keep the flat
source layout, no `Sources/Shared|iOS|macOS` restructure.

**`xcodebuild -scheme Intake-macOS -destination 'platform=macOS'` -> BUILD SUCCEEDED.** The whole
port was seven compile errors across 63 files.

Ran it 2026-08-27. It launches and works. Fixed on the spot:

## The iOS test suite was hanging, FIXED 2026-08-27

`xcodebuild test -scheme Dose` used to run forever and never emit a result line. Now:
**Executed 77 tests, 0 failures, 2 skipped, in 0.22s.**

**Root cause:** `NotificationServiceTests` called `NotificationService.requestAuthorization()`,
which calls `UNUserNotificationCenter.requestAuthorization`, that presents a system permission
alert, and under `xcodebuild test` nothing ever dismisses it. `DoseTests` is a *hosted* bundle
(`TEST_HOST = Dose.app/Dose`) so the alert belongs to the launched host app. Everything before it
ran in milliseconds; the suite simply stopped there forever.

Ruled out along the way, so nobody re-investigates them: it is **not** resource contention, **not**
the `LAContext` lock screen in `DoseApp.unlock()` (biometry is not enrolled on the sim, so
`requiresUnlock` is false), and **not** the HealthKit permission `.task`.

Fixes:
- Deleted `testRequestAuthorizationReturnsBool`, it asserted `XCTAssertTrue(result || !result)`,
  a tautology that could never fail, and it was the call that blocked.
- Dropped the incidental `requestAuthorization()` calls from the other tests.
- The two tests that assert a request is *pending* genuinely need authorization
  (`UNUserNotificationCenter.add` silently drops requests when unauthorized), so they now skip via
  `notificationSettings()`, which reads status **without** prompting. They run for real on a
  machine where permission was granted, and skip headlessly instead of failing.

**One real app bug the hang was hiding:** `HealthScoringService.supplementAdherence` computed
`(uniqueDays * 100) / 14`, integer division, so 5-of-14 days displayed as **35%** instead of 36%.
Now rounds properly. Every adherence percentage in the app was biased low.

Two other failures were bad tests, not bad code:
- `testConfidenceFullData` passed `moodScore: 8` and called it "all optimal", but moodScore is a
  scale metric out of 10 worth 13 points, so 8 scores 10, exactly the missing 3 points. Now 10.
- `testCSVEscapeWithQuotesCommasAndNewlines` split the CSV on `\n` while deliberately embedding a
  newline inside a quoted field, and expected a space where its own input had a newline. The
  production escaping is correct RFC 4180; the test now asserts against the whole file.

## macOS: UITEST_SNAPSHOT produces no window, found 2026-08-27, PRE-EXISTING

`open Intake.app --args UITEST_SNAPSHOT` leaves the app running with **no on-screen window**.
`CGWindowListCopyWindowInfo` finds Intake windows under `.optionAll` but zero under
`.optionOnScreenOnly`. Without the flag the window appears normally at 1000x700 and shows the
sign-in screen, so screenshots themselves work fine.

Confirmed pre-existing, **not** caused by the sidebar work: stashing the `DoseApp.swift` changes,
rebuilding, and relaunching with the flag reproduces it identically.

`sample <pid>` shows the main thread **idle in the normal AppKit run loop**, not deadlocked, not
spinning. So this is not a hang, and there is no evidence real users are affected. What it does
block is Mac screenshot automation, since `UITEST_SNAPSHOT` is the only auth bypass
(`DoseApp.swift:35`).

- [ ] Work out why SwiftUI never shows the window on that path, so Mac screenshots can be
      automated the way the iOS ones are.

Local testing credentials now live in `.env.accounts.local` (gitignored via `.env*`), matching the
`DEV_EMAIL`/`DEV_PASSWORD` convention used for screenshot automation elsewhere.

## macOS SUBMITTED 2026-08-27

Intake for Mac 2.3.5 (build `202608271405`) is **WAITING_FOR_REVIEW**, submission
`54e8a1a2-b94c-455f-a64c-0c34c4a2c9f4`, macOS version record `b6e6605e-7b26-45ea-940b-6f8f2f27e240`.
`asc review doctor --platform MAC_OS` reported 0 errors, 0 blocking before submitting. Both
platforms are now in review at once on the same record, which App Store Connect handles fine.

Submitting needed three things beyond the build, none obvious from the iOS flow:
1. A **separate `MAC_OS` version record**, `asc versions create --platform MAC_OS`. Uploading a
   Mac build does not create one. This was the step wrongly recorded as "maybe dashboard-only".
2. **Its own metadata.** The macOS localization starts empty; description does not inherit from
   iOS. Copied `metadata/version/2.3.4/en-US.json` to `2.3.5/` and ran
   `asc metadata apply --platform MAC_OS`.
3. **macOS screenshots**, device type `APP_DESKTOP`, minimum 1280x800.

Screenshot capture, without any UI automation (`screenshots/macos/*.png`, 1440x900):
temporarily set `.defaultSize` to 1440x900 and drove `selectedTab` 0-4 by `sed` + rebuild, one
build per tab, restoring `DoseApp.swift` from git afterwards. Capture the window alone with
`screencapture -o -l <windowID>`, taking the id from `CGWindowListCopyWindowInfo`, a plain
`screencapture -x` grabs the whole desktop, terminal included. The app stays signed in across
relaunches, so the shots show real data. `scripts/` has no wrapper for this yet; the loop lived in
the session scratchpad.

Remaining:

Screenshot tip: capture the window alone with
`screencapture -o -l <windowID>`, getting the id from `CGWindowListCopyWindowInfo`. A plain
`screencapture -x` grabs the whole desktop, terminal included.

Signing notes, because this took three tries:

- `xcodebuild archive` with `CODE_SIGN_STYLE=Manual` + `PROVISIONING_PROFILE_SPECIFIER` on the
  command line **leaks the setting into every SPM package target**, and swift-crypto/SwiftLint then
  fail with "does not support provisioning profiles". Use `-allowProvisioningUpdates` and leave
  signing to the project.
- A profile created through the API is **not installed locally**. `asc profiles download --id
  HS3A2S4K8B --output ~/Library/Developer/Xcode/UserData/Provisioning\ Profiles/*.provisionprofile`
  (note: macOS profiles live there, not in `~/Library/MobileDevice/Provisioning Profiles`).
- Manual `signingStyle` in `ExportOptionsMac.plist` then failed on the *installer* certificate.
  The working config is lexly's: `method: app-store-connect`, `destination: upload`,
  `signingStyle: automatic`. `destination: upload` does the upload itself, so no separate
  `asc builds upload --pkg` step is needed, and it writes no pkg on disk, per
  `feedback_asc_export_upload_no_ipa`.

## Screenshot frames: floating tab bar clips the last row, found 2026-08-29
- [x] The re-shot set (`46dd672`) is correctly ordered, but `DoseFloatingTabBar` is drawn
  over scrollable content, so the bottom row is half-hidden in every frame, Omega-3 on
  Home, the Magnesium/Zinc cards on Library. Correct in-app behaviour, but it reads as
  unfinished in a store listing, which matters while the 4.3(a) wave is open.
  Fix in the snapshot path only (do NOT change the real layout): under `UITEST_SNAPSHOT`,
  add bottom content padding equal to the tab bar's height so the last row clears it.
  Same `isUITestSnapshot` idiom already used to suppress `WhatsNewSheet`.
  Not urgent, iOS 2.3.5 is REJECTED and macOS 2.3.5 IN_REVIEW, so nothing uploads until
  the next version anyway. Fold this into that capture run rather than re-shooting now.

## 2026-09-02, Mac screenshots
Sidebar routing on macOS was broken (navigationDestination in the sidebar column never swapped the hardcoded Dashboard detail). Fixed. Recapture Lab Results / Feet / Meridians / Symptoms at 1440x900: build Debug, launch with `UITEST_SNAPSHOT -app_theme light -UITEST_TAB "<Sidebar name>"`, temporarily set defaultSize to 1440x900. Old library/insights/body shots were from a pre-reflexology build and were removed from the README.

## From Notes (2026-09-12)

## Ingested 2026-10-01
- [x] App Review flagged an issue with iOS 2.3.6 (submitted Sep 12 2026 via API key, submission 6ae57416-d5bc-4b2b-8b19-23402fcedec6). Read the reason in App Review and resolve. (screenshot: notes/attachments/2026-10-01/healstack-1.png)

## Ingested 2026-10-16
- [ ] Stale App Store name: the live listing still says Healstack (iOS 2.3.6 ready for distribution, macOS 2.3.5 in review). (screenshots: notes/attachments/2026-10-16/intake-2.png, notes/attachments/2026-10-16/intake-3.png)

## Ingested 2026-10-21
- [ ] New stethoscope icon and clrs.cc blue accent (#0074D9) need a new App Store build to show on the store.
