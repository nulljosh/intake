<img src="icon.svg" width="80" style="border-radius:18px">

# Intake
![version](https://img.shields.io/badge/version-v2.3.5-blue) ![license](https://img.shields.io/badge/license-Apache--2.0-blue) [![GitHub](https://img.shields.io/badge/GitHub-nulljosh%2Fhealstack-black?logo=github)](https://github.com/nulljosh/intake)

**Live:** https://intake.jaybulb.com

Know what you took, when, and what it does with everything else you're on.

A dose log, a harm reduction library, and a health dashboard. Web, iOS and macOS. Your data stays on your device.

<img src="progress.svg" width="460">

## Screenshots

<img src="screenshots/macos/home.png" width="800">

<p>
<img src="screenshots/ios/library.png" width="240">
<img src="screenshots/ios/insights.png" width="240">
<img src="screenshots/ios/body.png" width="240">
</p>

## Features
- Log a dose in two taps. Journal, filter, search.
- 200 substances with harm reduction notes, written by hand.
- Interaction warnings against your active stack, before you log.
- Tolerance tracking with washout alerts.
- Daily check-ins and biometrics.
- Heatmap, frequency, insights.
- Lab results, in and out of range.
- CSV export. Works offline.

## Run
```bash
npm install && npm run dev   # localhost:5173
npm test
npm run build
./deploy.sh                  # Cloudflare Pages
```

Native apps live in `ios/` and `macos/`. Each has an xcodegen `project.yml`.

## Docs
- [Technical whitepaper](WHITEPAPER.md)
- [API and agent tools](docs/API.md). HTTP surface plus the WebMCP tools on `document.modelContext`.
- [Roadmap](roadmap.md)

## Architecture

<img src="architecture.svg" width="600">

## License
Apache 2.0, 2026 Joshua Trommel. See [LICENSE](LICENSE) and [NOTICE](NOTICE).
