# Architecture

Intake helps someone track what they take and how their body is doing. Users log doses and substances, biometrics, and lab results, and get a warning if two things they take are known to interact badly, plus track bodywork routines like acupuncture or reflexology. It runs as a web app and an iOS app, both built from the same code where possible. Sign-in is through Supabase (email/password or OAuth). Paying users get cross-device sync and other extras, handled by small Cloudflare-hosted functions and a key-value store.

## How it runs

**Web**: User opens the site, signs in with Supabase credentials. Dashboard lists active dose entries from localStorage, checks interactions, renders health metrics. Logging a dose checks the interaction database. Pro features (CSV export, cross-device sync) call Cloudflare Functions endpoints (stripe.js for checkout, sync.js for data push/pull).

**iOS**: Launch `IntakeApp.swift`, which initializes Supabase client from Info.plist, prompts auth if needed. Same UI surfaces the five core tabs: Home (Dashboard), Substances, Journal, Insights, Profile. Dose logging, interaction checking, and biometric tracking work identically to web, using the same hooks/models, backed by device localStorage.

Data syncs via `functions/api/sync.js` only for Pro users; free users stay local. Lab PDFs are parsed client-side by `src/utils/parseLifeLabs.js` using PDF.js from CDN.

## Components and structure

| File or Directory | What it owns |
|---|---|
| `src/App.jsx` (116L) | React router, theme toggle (light/dark, persisted), tab/nav shell, auth gate, SessionProvider + AuthProvider wrappers |
| `src/main.jsx` (12L) | React entry point, mounts App to root, StrictMode wrapper |
| `src/design-tokens.css` | Token reference comment block (extracted from heyitsmejosh.com portfolio vibe): dark/light palette (--bg, --text-primary, --text-secondary), accent color |
| `src/pages/Dashboard.jsx` | Home view: renders active pill ring (circular progress of today's dose stack), health metrics radar, recent log entries, and insight cards (trends + correlations from insightEngine) |
| `src/pages/Landing.jsx` (295L) | Marketing landing page: hero section with reveal-on-scroll animations, feature cards, install prompt, call-to-action buttons, dark mode compatible |
| `src/pages/Substances.jsx` | Substance database browser, categorized (psychedelics, stimulants, depressants, cannabinoids, etc), tap to view detail with personal log history and interaction warnings |
| `src/pages/SubstanceDetail.jsx` | Substance detail panel with effects, dosage range, harm-reduction notes, personal log entries filtered by substance, "add dose" button |
| `src/pages/Supplements.jsx` | Supplement stack builder: select from pre-defined supplement list, add custom items, manage daily taken-today toggle, adherence tracking |
| `src/pages/Journal.jsx` | Dose log chronological list with entry export, substance filtering, delete per-entry, time-period filter via date range picker |
| `src/pages/LabResults.jsx` | Lab panel browser, renders marker charts (line graphs over time), per-marker flag badges (normal/low/high/critical), reference-range bars, interpretation text |
| `src/pages/Biometrics.jsx` | Weight/BP/HR/sleep/steps tracking, radar chart visualization, upload biometric screenshots, entry history, bulk delete |
| `src/pages/Health.jsx` | Biometric metrics form and screenshot gallery, stores parsed JSON locally, tab-switched view of charts and raw metrics |
| `src/pages/Insights.jsx` | Heatmap of dose frequency (substance x time-of-day), sliding window (7/14/30 days), sub-tabs for trends + interactions + correlation analysis |
| `src/pages/Routine.jsx` | Daily checklist (medications, supplements, self-care tasks), progress bar per category, cumulative streak counter |
| `src/pages/Meridians.jsx` | Acupuncture meridian browser, selects meridian from list, displays 12+ points per meridian with indications and technique notes, logs session when point is tapped |
| `src/pages/Feet.jsx` + `Hands.jsx` + `Abdomen.jsx` | Reflexology zone maps (SVG or canvas), labeled zones highlight on hover, zone detail panel with organ/system/technique, logs session when zone is tapped |
| `src/pages/Bodywork.jsx` | Hub for reflexology (feet/hands/abdomen) and acupuncture, links to Meridians |
| `src/pages/Body.jsx` | Another hub page listing bodywork options (reflexology, acupuncture) with session counts |
| `src/pages/SymptomFinder.jsx` | Search symptoms (headache, nausea, etc), cross-references to reflex zones and acupuncture points, lists techniques for each |
| `src/pages/Facemaxxing.jsx` | Skincare routine tracker, shows today's completed protocols and remaining, expandable step-by-step guides per protocol, persist checked state |
| `src/pages/Profile.jsx` | User account view, shows current conditions/diagnoses (tracked state), routine summary, test status toggles, edit notes |
| `src/pages/Auth.jsx` + `ResetPassword.jsx` | Login/signup forms (email + password), ToS checkbox, GitHub OAuth button, password reset flow via email |
| `src/pages/Interactions.jsx` | Standalone interaction checker UI |
| `src/pages/Sessions.jsx` | History of bodywork sessions (reflexology/acupuncture), session type/date/notes, delete per-session |
| `src/components/InteractionChecker.jsx` | Search form for substance pairs, returns known interaction severity and notes from curated data/substances.js interaction matrix |
| `src/components/RadarChart.jsx` | Chart.js radar chart for biometric metrics (weight/BP/HR/sleep/steps), renders 5-axis polygon |
| `src/components/LabCharts/` | Chart.js line chart wrappers for rendering marker trends over time, legend, tooltip config |
| `src/components/ToleranceTracker.jsx` | Analyzes dose log frequency, computes tolerance build warnings (frequent dosing), renders timeline |
| `src/components/LogEntry.jsx` | Dose log entry card: substance name, dose, route, time, rating, delete button |
| `src/components/AddEntryModal.jsx` | Modal form to add new dose: substance picker with search, dose input, unit dropdown, route dropdown, optional notes, rating 1-10 |
| `src/components/ScreenshotGallery.jsx` | Image upload gallery for biometric screenshots, stores Base64 in localStorage, renders thumbnail grid, delete per-image |
| `src/components/BiometricEntryForm.jsx` | Form fields for weight, BP (systolic/diastolic), HR, sleep hours, steps, SpO2, HRV with input validation |
| `src/components/ZoneDetail.jsx` | Reflexology/acupuncture zone detail panel: shows zone name, organ/meridian, technique, benefits, referral info, log-session button |
| `src/components/FootMap.jsx` + `HandMap.jsx` + `AbdomenMap.jsx` | SVG interactive maps: on-hover zone highlight, click to select, zone list beside map, responsive scaling |
| `src/components/SubstanceCard.jsx` | Card view for substance: name, category badge, quick-add dose button, tap to detail |
| `src/components/InstallAnywhere.jsx` | PWA install prompt UI for web app add-to-home-screen |
| `src/components/Nav.jsx` | Navigation bar component, used on web pages for routing links |
| `src/components/WhatsNew.jsx` | Release notes display component, shows current version notes |
| `src/context/` | AuthContext (Supabase session, login/logout/signup callbacks), SessionContext (bodywork session history), context providers wrapped at App level |
| `src/hooks/useDoseLog.js` | Dose log state management: loads from localStorage key `dose:log`, provides add/filter/delete/export methods, timestamps entries, filters by substance/date range, computes frequency heatmaps |
| `src/hooks/useSubstances.js` | Substance database hook: loads SUBSTANCES constant, provides search/getById, manages custom substances (localStorage `dose:custom_substances`), persists additions |
| `src/hooks/useBiometrics.js` | Biometric metrics: weight/BP/HR/sleep/steps/SpO2/HRV tracking, latest value retrieval, localStorage key `dose:health_metrics` |
| `src/hooks/useLabResults.js` | Lab result parsing and storage: loads from localStorage key `dose:lab_results`, provides per-marker flag computation (normal/low/high/critical), chart data aggregation, PANELS constant (comprehensive panel definitions) |
| `src/hooks/useProfile.js` | User profile: custom substance list, diagnosed conditions, general notes, seeded with example data if new user |
| `src/hooks/useRoutine.js` | Daily checklist: tracks completed routine items per day, persists to localStorage key `dose:routine:checked`, computes streak, checked-today count |
| `src/hooks/useSupplements.js` | Supplement stack builder: add/remove/toggle taken-today state, compute adherence (% of stack taken today), SUPPLEMENT_CATEGORIES constant |
| `src/hooks/usePro.js` | Pro feature unlock: checks `pro:<userId>` KV flag via Stripe checkout or Cloudflare sync endpoint, returns isPro boolean |
| `src/data/substances.js` (1800+L) | Complete substance database: psychedelics, stimulants, depressants, entactogens, cannabinoids, opioids, etc, each with effects, dosage, harm reduction, routes, known interaction pairs, category classification |
| `src/data/reflexology.js` | Foot and hand zone maps: zone ID/name/organ/system/technique/benefits/referral info, 16 foot zones + 11 hand zones, used by Feet and Hands page components |
| `src/data/abdomen.js` | Abdominal reflexology zones export: 9+ zones with location, organ, system, technique, duration, benefits, conditions, referral, and zone number |
| `src/data/meridians.js` | 12 acupuncture meridians with ID/name/abbreviation/color, each containing 10-14 points with ID/name/English/location/indications/technique, getAllPoints() utility |
| `src/data/bodyworkSymptoms.js` | Symptom cross-reference array: symptom ID/name/icon, lists reflex zones and acupuncture points that address it, self-care recommendations |
| `src/data/facemaxxing.js` | Skincare/fitness protocols: 30+ protocols with title/category/difficulty/summary/steps/PSL advice, grouped by category (mewing/posture/skincare/etc), categories list |
| `src/data/routine.js` | Daily routine checklist items and categories, pre-populated habit recommendations |
| `src/lib/supabase.js` | Supabase client init with VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY from env |
| `src/constants/colors.js` | Substance category color palette: psychedelic/stimulant/depressant/entactogen/cannabinoid/vitamin/supplement/opioid/etc, used by substance cards and filters |
| `src/lib/webmcp.jsx` | WebMCP tool registration for Claude in Chrome agents, exposes hooks as callable tools (log dose, export CSV, etc), maintains tool registry via document.modelContext |
| `src/context/AuthContext.jsx` | React context: Supabase session state, provides signIn/signUp/signOut callbacks, loading state, password recovery mode tracking |
| `src/context/SessionContext.jsx` | React context: bodywork session CRUD, persisted to localStorage `dose:bodywork_sessions`, provides addSession/deleteSession/useSessions |
| `src/utils/date.js` | Date formatting (shortDate, longDate, shortTime) |
| `src/utils/exportCsv.js` | CSV export of dose log with headers: date, time, substance, dose, unit, route, rating, notes |
| `src/utils/insightEngine.js` | Pure statistical analysis: correlates dose log against biometrics and lab results, computes mean/stddev over windows, builds frequency heatmaps |
| `src/utils/parseLifeLabs.js` | Client-side PDF parser using PDF.js CDN, extracts LifeLabs result panels and individual marker values |
| `ios/Services/AuthService.swift` | iOS Supabase auth with email+password, Apple Sign-in, Google Sign-in (via OAuth). Reads SUPABASE_ANON_KEY from Info.plist. Password reset and recovery flow, error handling and session state |
| `ios/Services/DataSyncService.swift` | iOS background sync to Cloudflare KV (Pro feature), credential store integration |
| `ios/Services/NotificationService.swift` | iOS local notifications for dose reminders, scheduling and delivery |
| `ios/Models/DoseEntry.swift` | Dose log entry: substanceId (UUID or built-in string), timestamp, notes, dose amount, route (oral/intranasal/etc), unit (mg/ug/ml), personal rating (1-10) |
| `ios/Models/HealthEntry.swift` | Daily health snapshot: mood/energy (1-10), sleep hours, notes |
| `ios/Models/BiometricEntry.swift` | Biometric reading: weight, BP (systolic/diastolic), HR, sleep, steps, respiratory rate, SpO2, HRV, notes |
| `ios/Models/LabResult.swift` | Parsed lab panel with markers and flag levels (normal/low/high/critical), marker name/value/unit/reference range, computed flag logic per marker |
| `ios/Models/BodyworkSessionStore.swift` | Session storage: add/delete/save BodyworkSession, persisted to AppStorage |
| `ios/Models/MyMedication.swift` | Medication model: builtInSubstanceId or custom name, dosage, unit, Schedule enum (daily/twice daily/as-needed/etc), reminder hour/minute |
| `ios/Models/Substance.swift` | Substance model: category enum (medication/vitamin/supplement), name, dosage range, effects, interactions, harm reduction |
| `ios/Models/AbdomenData.swift` | Abdominal reflexology zones: 16 zones with location, organ, body system, technique, benefits, referral info |
| `ios/Models/AcupunctureData.swift` | Meridian definitions: 12 meridians with abbreviation, color, 10-12 points each with indications and technique |
| `ios/Models/ReflexologyData.swift` | Foot and hand reflexology zones: BodySystem enum (digestive/respiratory/nervous/etc), per-zone details with color mapping |
| `ios/Models/SymptomData.swift` | Symptom reference: symptom name/icon, cross-indexed to reflex zones and acupuncture points, self-care recommendations |
| `ios/Models/FacemaxxingData.swift` | Facemaxxing protocols: difficulty levels, category groups, step-by-step instructions, PSL advice notes |
| `ios/Data/` | SubstanceDatabase.swift (complete built-in substance list, 2600+ lines, read-only), OnboardingSlides (first-run flow) |
| `ios/DoseWidget/DoseWidget.swift` | iOS WidgetKit lock screen widget: displays active pills (count per substance), updates timeline hourly, shows most recent dose name |
| `ios/DoseWidget/DoseWidgetBundle.swift` | WidgetKit bundle wrapper for DoseWidget |
| `ios/Checks/main.swift` | Self-check for LabResult model, runs standalone: `swiftc -o /tmp/hscheck ios/Models/LabResult.swift ios/Checks/main.swift && /tmp/hscheck` |
| `ios/CrossPlatform.swift` | Haptics, keyboard type, navigation bar shims for iOS/macOS cross-platform code |
| `ios/OnboardingView.swift` + `WhatsNewSheet.swift` | Shared first-run UI and release notes, mounted on root app |
| `ios/IntakeApp.swift` | SwiftUI entry point, five-tab shell (Home, Substances, Journal, Insights, Profile), auth gate, app state, FloatingTabBar and LockView for biometric auth |
| `ios/IntakeFloatingTabBar.swift` + `AppShareOverlay.swift` | Custom tab bar UI (floats above content), app share sheet for iOS social sharing |
| `ios/OnboardingView.swift` | Shared first-run onboarding carousel (copy verbatim into any app that needs it), triggers signup flow on completion |
| `ios/WhatsNewSheet.swift` | Release notes sheet, appears only when shipping version matches bundled notes version (avoids stale prompts) |
| `ios/CrossPlatform.swift` | Haptics wrapper (iOS only, no-op on macOS), keyboard type and navigation bar style cross-platform shims |
| `macos/OnboardingSlides.swift` | First-run carousel slides shared by macOS and iOS, hardcoded slide titles/body/symbols for app intro |
| `macos/Views/AuthView.swift` | macOS login and signup form with email/password fields, tab toggle, GitHub OAuth button |
| `macos/Views/BodyMapView.swift` | Interactive SVG renderer for reflexology zone maps, scales to viewport, highlights selected zone, renders outlines and zone paths |
| `macos/Views/MacAbdomenView.swift` | Abdominal reflexology zones in 3x3 grid layout, tap to select and show zone details, log-session button |
| `macos/Views/MacDashboardView.swift` | macOS home view showing active pills from past 24 hours, recent dose log entries, top health insight, greeting header |
| `macos/Views/MacFacemaxxingView.swift` | Skincare and fitness protocol tracker with sidebar protocol list and detail pane showing steps and progress count |
| `macos/Views/MacLabResultsView.swift` | Lab result panel viewer with marker entry form, date picker, lab name input, flag badges for abnormal values |
| `macos/Views/MacMeridianListView.swift` | Expandable acupuncture meridian list showing 12 meridians, each with 10-14 points, point details on expand, log-session button |
| `macos/Views/MacReflexologyView.swift` | Foot and hand reflexology map selector, swaps between modes, renders BodyMapView with zone outline and selected zone detail |
| `macos/Views/MacSessionHistoryView.swift` | List of logged bodywork sessions with type (reflexology/acupuncture), area, date, swipe-to-delete support |
| `macos/Views/MacSettingsView.swift` | Account and appearance settings panel, theme picker (light/dark/system), sign-out button, displays current email |
| `macos/Views/MacSymptomFinderView.swift` | Symptom search with grid layout and filtering, selected symptom shows reflex zones and acupuncture points that address it |
| `macos/Views/SidebarView.swift` | NavigationSplitView sidebar with navigation links to all main views (dashboard, labs, bodywork, symptoms, settings), labeled with SF icons |
| `macos/Views/ZoneDetailView.swift` | Reflexology zone detail card showing organ, body system, location, technique, duration, benefits list, log-session button |
| `public/onboarding.js` | Shared first-run carousel UI component, vanilla JS with CSS animations, auto-detects signed-in state, customizable slides, fires onDone callback |
| `public/privacy.html` | Privacy policy page describing data collection (email, health logs), storage in Supabase with RLS, no advertising or selling |
| `public/tos.html` | Terms of Service page with health disclaimer, data ownership rights, account security responsibility, abuse policy |
| `scripts/check-auth-live.sh` | Validates Supabase anon key liveness by testing health endpoint and demo account auth, guards against review rejection via auth 500 errors |
| `scripts/check-signin-config.sh` | Verifies Sign in with Apple/Google configuration in built app binaries (bundle ID, URL scheme, entitlements match Supabase config) |
| `scripts/simplify.sh` | Ensures standard project folder structure (docs/, scripts/, src/, tests/, assets/) exists |
| `functions/api/stripe.js` (110L) | Cloudflare Worker: Stripe client init, getStripe() singleton, ALLOWED_ORIGIN check, create Stripe checkout session endpoint, verifies caller's Supabase access token (bearer auth), reads isPro flag from KV, responds with session ID for client redirect |
| `functions/api/stripe-webhook.js` (41L) | Cloudflare Worker: Stripe webhook receiver, verifies webhook signature using STRIPE_WEBHOOK_SECRET, extracts client_reference_id (Supabase userId), writes `pro:<userId>` flag to DOSE_KV on successful payment |
| `functions/api/sync.js` (125L) | Cloudflare Worker: authenticated data sync endpoint for Pro users, rate-limited (10 req/min per token), token verified via timing-safe SHA-256 hash comparison against stored hash, accepts POST with dose log JSON, stores/retrieves from DOSE_KV namespace |
| `supabase/migrations/20260527000000_dose_profiles.sql` | RLS-protected dose_profiles table, one row per user (references auth.users on delete cascade), stores custom profile data as jsonb (substances list, conditions, notes), auto-populated on user signup |
| `src/index.css` | Full design system: Intake Sans with a system fallback, flat, clrs.cc blue accent, CSS custom properties (--bg, --border, --accent, etc), light/dark mode variables |
| `src/test/auth.test.jsx` | Vitest: Auth and ResetPassword component rendering, form submission, error handling |
| `src/test/stripe-auth.test.js` | Vitest: Stripe checkout session creation endpoint, verifies caller's Supabase token before session creation |
| `src/test/stripe-webhook.test.js` | Vitest: Stripe webhook signature verification, client_reference_id extraction, pro flag KV write |
| `src/test/useDoseLog.test.js` | Vitest: useDoseLog hook CRUD (add/filter/delete), date filtering, timestamp validation |
| `src/test/useSubstances.test.js` | Vitest: useSubstances search, getById, custom substance persistence |
| `src/test/useSupplements.test.js` | Vitest: useSupplements daily adherence tracking, toggle taken-today, day-key computation |
| `src/test/webmcp.test.jsx` | Vitest: WebMCP agent tool registration and dispatch to hook callbacks |
| `src/test/setup.js` | Test harness setup, localStorage mock, @testing-library/jest-dom imports |
| `vite.config.js` | Vite build config: React, Brotli compression, PWA manifest, code splitting |
| `index.html` | Entry point for web app, mounts React into #root, includes PWA manifest link, dark theme color, mobile viewport, Apple web app capable |
| `_lp.html` + `_lp.jsx` | Landing page entry point, includes demo tour and features callout |
| `_lpframe.html` + `_lpshot.html` | Frame testing: renders landing at multiple widths (375px + 414px) and both themes side-by-side |
| `deploy.sh` | Bash script: runs build, then deploys dist/ to Cloudflare Pages via wrangler |
| `project.yml` | xcodegen config for iOS app (generates Intake.xcodeproj), defines schemes, build settings, entitlements, team ID, signing |

## Data flow

**New dose entry** (web): User taps "add" → AddEntryModal → picks substance via search (Substances hook filters the database), enters dose/route/notes, optionally adds rating → submit calls `useDoseLog.addEntry()` → writes to localStorage key `dose:log` as JSON → InteractionChecker searches `data/substances.js` for known interactions with any active substance in the log → warns if found → entry persists until deleted.

**Biometrics**: User uploads weight/BP/HR/sleep via Health page → parsed into BiometricEntry → stored in localStorage key `dose:health_metrics` → LabResults page runs `insightEngine` statistical correlations against dose log to surface patterns (e.g. "sleep drops 1.5 hours after caffeine after 2pm").

**Lab PDF upload**: User selects LifeLabs PDF → browser calls `parseLifeLabs` with file buffer → PDF.js decodes stream, OCR-like text extraction, regex matches lab panels and marker values, includes reference ranges → LabResult stored in localStorage key `dose:lab_results`, rendered with flag badges (normal/low/high/critical based on reference range).

**Sync** (Pro): User enables cross-device sync → Browser calls `functions/api/sync.js` with current dose log + auth token → Worker verifies token hash against DOSE_KV store, rate-limits to 10 reqs/min, writes/retrieves JSON from KV → next device pulls the same data.

**Stripe checkout** (Pro unlock): User taps Pro → calls `functions/api/stripe.js` → creates Stripe session with Supabase user id in client_reference_id → redirect to Stripe hosted checkout → user pays → Stripe POSTs webhook to `stripe-webhook.js` → Worker verifies signature, reads client_reference_id, writes `pro:<userId>` flag to KV → iOS/web both check this flag on app load to unlock Pro UI.

## Data storage

**Web/iOS local**: localStorage (DOM Storage on web, NSUserDefaults iOS analogue via localStorage wrapper). Keys: `dose:log` (main dose entry array), `dose:health_metrics`, `dose:health_screenshots`, `dose:supplements`, `dose:custom_substances`, `dose:routine:checked`, `dose:facemaxxing:checked`, `dose:lab_results`. Plain JSON, 4KB soft limit per key before silent truncation (web limitation). No schema versioning; app handles stale formats gracefully.

**Supabase auth**: email+password account in spark project, optional Apple/Google OAuth.

**Cloudflare KV**: DOSE_KV namespace, only Pro user data: rate-limit token hashes, sync payloads (JSON dose logs keyed by `sync:<userId>`), and `pro:<userId>` boolean flags. No encryption (HTTPS in transit, Cloudflare-managed).

## External services

**Supabase** (spark shared project): Auth users table, PASSWORD_RECOVERY email event hook (password reset emails via Resend).

**Cloudflare**: Pages for hosting, Functions for API, KV for data store, custom domain managed via Pages API (not DNS alone).

**Stripe**: Payment processing for Pro tier (CSV export + cross-device sync). Secrets not yet configured (app is free).

**PDF.js CDN** (jsDelivr): Client-side LifeLabs PDF parsing, loaded on demand.

**Resend**: Sends Supabase password-recovery emails via authmail Cloudflare Worker.

## Gotchas

- Interaction checker searches a static curated list (data/substances.js), not a real pharmacology DB. Misses many real interactions. Must warn user to consult a real pharmacist.
- Lab result reference ranges are baked in per marker (LabResult model). Different labs have different ranges (LifeLabs vs Quest vs local). PDF parser tries to extract ranges from the PDF itself, but falls back to defaults if parsing fails.
- localStorage truncates silently at 4KB per key. Dose log heatmaps compress poorly; very active users hit the ceiling. Pro sync is the workaround (pushes to KV). No on-device archiving.
- Stripe Pro unlock writes a `pro:<userId>` flag but does not revoke it after subscription ends. Deliberate: app is personal-use only, no recurring charge logic yet.
- iOS app bundle ID and URL scheme are still `dose` (not `healstack`) to avoid App Store re-linking on the 2026-07 rename from Dose.
- Biometric correlations are statistical only. A dose-sleep correlation doesn't prove causation. insightEngine computes mean and stddev over 7/14/30-day windows; user must reason about causality themselves.
