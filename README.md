# SmartStylist

> AI-powered luxury virtual wardrobe for iOS — built with SwiftUI, SwiftData, and Gemini.

![CI](https://github.com/rubenaparicio-byte/smartstylist/actions/workflows/ios-ci.yml/badge.svg)
![Platform](https://img.shields.io/badge/platform-iOS%2017%2B-black)
![Swift](https://img.shields.io/badge/swift-5.10-orange)
![Xcode](https://img.shields.io/badge/xcode-16%2B-blue)

---

## Features

| Module | Description |
|--------|-------------|
| **Onboarding** | 4-step colorimetry wizard — body type, skin tone, hair/eye colour → Gemini analyses your seasonal palette |
| **Virtual Closet** | Camera/photo ingestion with AI vision tagging; lifecycle management (active / archived / disposed); advanced filters by style, pattern, status; luxury search bar |
| **Style Engine** | Daily outfit generation via Gemini — respects colorimetry, weather, occasion, and 14-day wear history; offline colorimetry fallback |
| **Insights** | Style distribution donut chart (Swift Charts), top-3 most worn items, closet health snapshot |
| **Profile** | Colorimetry palette display, physical traits, Retake Analysis, Delete All My Data (App Store compliance) |

---

## Architecture

```
SmartStylist/
├── App/
│   ├── SmartStylistApp.swift   — @main, modelContainer
│   └── RootView.swift          — @Query gate: Onboarding ↔ MainTabView
├── DesignSystem/               — Colors, Typography, Shapes, Animations tokens
├── Models/                     — SwiftData @Model: UserProfile, ClothingItem, OutfitHistory
│                                 Codable: StyleResponse
├── Services/                   — Pure async: GeminiService, WeatherService,
│                                 LocationService, LocationWeatherService
├── ViewModels/                 — @Observable (no SwiftUI): ClosetViewModel,
│                                 StyleEngineViewModel, InsightsViewModel,
│                                 OnboardingViewModel, ProfileViewModel (@MainActor)
└── Views/
    ├── Main/                   — MainTabView (4 tabs, luxury UITabBarAppearance)
    ├── Onboarding/             — 4-step paged wizard
    ├── Closet/                 — VirtualClosetView, AddItemView, ItemDetailView,
    │                             ClothingItemCard, DisposeItemSheet, ValidationWorkspaceSheet
    ├── StyleEngine/            — StyleEngineView, OutfitSuggestionCard, WeatherBadgeView
    ├── Insights/               — WardrobeInsightsView (Swift Charts)
    ├── Profile/                — ProfileSettingsView
    └── Components/             — LuxuryLoadingView, LuxuryErrorView, SelectionChip,
                                  GoldDivider, FlowLayout, LuxuryCard, LoadingPulse
```

**Layer rules** (enforced by CI):
- ViewModels import `Foundation`, `SwiftData`, `Observation` only — never SwiftUI
- Views own all animation calls (`withAnimation`, `.animation(value:)`, `.transition`)
- Services are pure async functions with no stored state

---

## Design System — Luxury Slate

| Token | Hex | Use |
|-------|-----|-----|
| `dsDeepSlate` | `#1C1C1E` | Page background |
| `dsCardSlate` | `#2C2C2E` | Card background |
| `dsSurface` | `#3A3A3C` | Chip / pill background |
| `dsAccentGold` | `#D4AF37` | Primary accent, tint |
| `dsSoftGold` | `#E9C46A` | Secondary accent |
| `dsErrorRed` | `#E63946` | Error / danger |

Typography: serif editorial titles (`dsLargeTitle` → `dsTitle2`), lightweight body (`dsBody`, `dsCaption`, `dsLabel`).

---

## External APIs

| Service | Key constant | Purpose |
|---------|-------------|---------|
| Gemini 1.5 Flash | `APIKeys.gemini` | Colorimetry analysis + outfit suggestions + vision tagging |
| OpenWeather 3.0 | `APIKeys.openWeather` | Real-time weather for outfit context |

Both keys are injected at build time. See [API Keys](#api-keys) below.

---

## Requirements

- Xcode 16+ (macOS Sequoia+)
- iOS 17+ deployment target
- `brew install xcodegen`

---

## Quick Start

```bash
# 1. Clone
git clone https://github.com/rubenaparicio-byte/smartstylist.git && cd smartstylist

# 2. Install XcodeGen
brew install xcodegen

# 3. Add API keys
cp SmartStylist/Config/APIKeys.swift.template SmartStylist/Config/APIKeys.swift
# Edit APIKeys.swift and fill in your Gemini and OpenWeather keys

# 4. Generate Xcode project
xcodegen generate

# 5. Open and run
open SmartStylist.xcodeproj
# Select iPhone 16 simulator → ⌘R
```

Grant location permission when prompted — required for weather-based outfit suggestions.

---

## API Keys

`SmartStylist/Config/APIKeys.swift` is gitignored. Never commit it.

```swift
// APIKeys.swift (create locally from template — do not commit)
import Foundation
enum APIKeys {
    static let gemini      = "YOUR_GEMINI_KEY"
    static let openWeather = "YOUR_OPENWEATHER_KEY"
}
```

For CI, keys are injected from GitHub Secrets: `GEMINI_API_KEY` and `WEATHER_API_KEY`.

---

## CI / CD

| Workflow | Trigger | Action |
|----------|---------|--------|
| `ios-ci.yml` | Push / PR to `main` | XcodeGen → build for iPhone simulator (Debug) |
| `ios-cd.yml` | `workflow_dispatch` or `v*` tag | Archive → export IPA → upload to TestFlight |

CD secrets required: `APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_KEY_CONTENT`, `DEVELOPMENT_TEAM`.

Both workflows opt into Node.js 24 via `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24=true`.

---

## Testing

```bash
xcodegen generate
xcodebuild test \
  -project SmartStylist.xcodeproj \
  -scheme SmartStylist \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

Rules:
- Always use in-memory `ModelContainer` — never write to disk
- Never hit real APIs — use local JSON fixtures or protocol stubs
- ViewModels tests are synchronous (pure functions); `@MainActor` tests use `async setUp`

| Test file | Coverage |
|-----------|----------|
| `ClothingItemTests` | Model raw values, `StyleResponse` Codable |
| `GeminiServiceTests` | Outfit JSON decode (full / partial) |
| `ClosetViewModelTests` | 28 tests — filter chain (style/pattern/status/text/combined), clearFilters, hasActiveFilters |
| `StyleEngineViewModelTests` | Offline fallback, colorimetry scoring |
| `InsightsViewModelTests` | 13 tests — styleDistribution, topWornItems (boundary, sort), closetHealth |
| `ProfileViewModelTests` | 7 tests (@MainActor, in-memory ModelContainer) — retake, deleteAllData |

---

## Localization

EN and ES fully supported (78 keys). Keys are centralised in `Strings.swift` using `String(localized:)` for bundle-based lookup at call time.

```swift
Text(Strings.profileRetakeButton)   // → "Retake Analysis" / "Repetir Análisis"
```

To add a locale: create `xx.lproj/Localizable.strings`, mirror all 78 keys, add the language to `project.yml`.

---

## Legal (GitHub Pages)

Hosted from `docs/` — enable GitHub Pages on `main / docs` to publish:

- **Privacy Policy**: `docs/privacy.html` — local-only SwiftData storage, transient Gemini/OpenWeather use, no analytics
- **Terms of Use**: `docs/terms.html` — EULA, AI disclaimer, weather disclaimer, limitation of liability
