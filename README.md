<img src="icon.svg" width="80" height="80" alt="Intake icon">

![version](https://img.shields.io/badge/version-v2.4.0-0074D9) [![tests](https://github.com/nulljosh/intake/actions/workflows/test.yml/badge.svg)](https://github.com/nulljosh/intake/actions/workflows/test.yml) [![App Store](https://img.shields.io/badge/App%20Store-iPhone%20%26%20iPad-0074D9?logo=apple&logoColor=white)](https://apps.apple.com/app/id6785764864) ![license](https://img.shields.io/badge/license-Apache%202.0-0074D9)

Track what you take, and what it does. A dose log, a harm reduction library and a health dashboard. Your data stays on your device and syncs to your account.

<p>
<img src="screenshots/ios/home.png" width="200" alt="Home">
<img src="screenshots/ios/library.png" width="200" alt="Library">
<img src="screenshots/ios/insights.png" width="200" alt="Insights">
<img src="screenshots/ios/body.png" width="200" alt="Body">
</p>

## Features
- Log a dose in two taps, with an interaction check against what you're already on.
- 200 substances with harm reduction notes, written by hand.
- Tolerance, check-ins, biometrics and lab results, with anything out of range flagged.
- Web, iPhone, iPad, Mac and Apple Watch on one account. Works offline.

## Run
```bash
npm install && npm run dev && npm test
```

Native apps: `ios/` and `macos/`, each an xcodegen `project.yml`. Docs: [whitepaper](docs/WHITEPAPER.md), [architecture](docs/ARCHITECTURE.md), [API](docs/API.md), [roadmap](docs/roadmap.md), [brand](brand/BRAND.md).

<img src="architecture.svg" width="600" alt="Architecture">

Apache 2.0, 2026 Joshua Trommel.
