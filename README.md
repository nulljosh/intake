<img src="icon.svg" width="80" height="80" alt="Intake icon">

![version](https://img.shields.io/badge/version-v2.4.0-0074D9) [![tests](https://github.com/nulljosh/intake/actions/workflows/test.yml/badge.svg)](https://github.com/nulljosh/intake/actions/workflows/test.yml) [![App Store](https://img.shields.io/badge/App%20Store-iPhone%20%26%20iPad-0074D9?logo=apple&logoColor=white)](https://apps.apple.com/app/id6785764864) ![license](https://img.shields.io/badge/license-Apache%202.0-0074D9)

Know what you took, when, and what it does with everything else you're on.

A dose log, a harm reduction library, and a health dashboard. Web, iPhone, iPad, Mac and Apple Watch. Your data stays on your device.

**[intake.jaybulb.com →](https://intake.jaybulb.com)**

<p>
<img src="screenshots/ios/home.png" width="200" alt="Home">
<img src="screenshots/ios/library.png" width="200" alt="Library">
<img src="screenshots/ios/insights.png" width="200" alt="Insights">
<img src="screenshots/ios/body.png" width="200" alt="Body">
</p>

## Features
- Log a dose in two taps. Journal, filter, search.
- 200 substances with harm reduction notes, written by hand.
- Interaction warnings against your active stack, before you log.
- Tolerance tracking with washout alerts.
- Daily check-ins and biometrics, read from Apple Health on iPhone.
- Heatmap, frequency, insights.
- Lab results, with anything out of range flagged on the home screen.
- CSV export. Works offline.

## Run
```bash
npm install && npm run dev   # localhost:5173
npm test
npm run build
./deploy.sh                  # Cloudflare Pages
```

Native apps live in `ios/` and `macos/`. Each has an xcodegen `project.yml`.

## Design
Intake Sans (Inter, renamed by `scripts/gen_font.py`), clrs.cc blue `#0074D9`, a stethoscope for the mark, and Asclepius in halftone on the landing. The brand kit is [brand/BRAND.md](brand/BRAND.md).

## Docs
- [Technical whitepaper](WHITEPAPER.md)
- [Architecture](docs/ARCHITECTURE.md)
- [API and agent tools](docs/API.md). HTTP surface plus the WebMCP tools on `document.modelContext`.
- [Roadmap](roadmap.md)

<img src="architecture.svg" width="600" alt="Architecture">

<img src="progress.svg" width="460" alt="Commits over time">

## License
Apache 2.0, 2026 Joshua Trommel. See [LICENSE](LICENSE) and [NOTICE](NOTICE).
