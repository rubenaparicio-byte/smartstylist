# SmartStylist

> AI-powered luxury virtual wardrobe for iOS — built with SwiftUI, SwiftData, and OpenRouter.

![CI](https://github.com/rubenaparicio-byte/smartstylist/actions/workflows/ios-ci.yml/badge.svg)
![Platform](https://img.shields.io/badge/platform-iOS%2017%2B-black)
![Swift](https://img.shields.io/badge/swift-5.10-orange)
![Xcode](https://img.shields.io/badge/xcode-16%2B-blue)

---

## Features

| Module | Description |
|--------|-------------|
| **Authentication** | Sign In with Apple (primary) + Sign In with Google — both sessions stored in Keychain |
| **Onboarding** | 6-step colorimetry funnel — language, gender, body type, skin tone, hair/eye colours → AI analyses your seasonal palette and accessory style |
| **Virtual Closet** | Camera/gallery ingestion with on-device Vision segmentation (white background), AI vision tagging, 39-type subcategory taxonomy, thermal layer system, lifecycle management (active / archived / disposed) |
| **Style Engine** | Daily outfit generation via OpenRouter — respects colorimetry, weather, occasion, thermal coherence, and 14-day wear history; offline colorimetry fallback |
| **Insights** | Style distribution donut chart (Swift Charts), top-3 most worn items, closet health snapshot |
| **Profile** | Colorimetry palette, physical traits, preferred stores, age, accessory style, language selector, Retake Analysis, Delete All Data |

---

## Architecture

```
SmartStylist/
├── App/
│   ├── SmartStylistApp.swift   — @main, modelContainer, locale injection, Google URL callback
│   └── RootView.swift          — auth gate: Login → Onboarding → MainTabView
├── DesignSystem/               — Colors, Typography, Shapes, Animations tokens
├── Models/                     — SwiftData @Model: UserProfile, ClothingItem, OutfitHistory
│                                 Enums: ThermalLayer, ClothingSubcategory (39 types)
│                                 Codable: StyleResponse
├── Services/                   — Pure async: AuthService, GeminiService, GarmentSegmentationService
│                                 WeatherService, LocationService, LocationWeatherService
├── ViewModels/                 — @Observable: ClosetViewModel, StyleEngineViewModel,
│                                 InsightsViewModel, OnboardingViewModel, ProfileViewModel
└── Views/
    ├── Auth/                   — LoginView (Apple + Google)
    ├── Main/                   — MainTabView (4 tabs)
    ├── Onboarding/             — 6-step funnel (Language, Gender, BodyType, SkinTone, HairEye, Result)
    ├── Closet/                 — VirtualClosetView, AddItemView, ValidationWorkspaceSheet,
    │                             ClothingItemCard, ItemDetailView, DisposeItemSheet
    ├── StyleEngine/            — StyleEngineView, OutfitSuggestionCard, WeatherBadgeView
    ├── Insights/               — WardrobeInsightsView (Swift Charts)
    ├── Profile/                — ProfileSettingsView, StoreSelectionView
    └── Components/             — CameraPicker, SelectionChip, LuxuryCard, FlowLayout, …
```

**Layer rules:**
- ViewModels import `Foundation`, `SwiftData`, `Observation` only — never SwiftUI
- Views own all animation calls (`withAnimation`, `.animation(value:)`, `.transition`)
- Services are pure async functions; `GarmentSegmentationService` is a Swift `actor`

---

## Design System — Luxury Slate

| Token | Hex | Use |
|-------|-----|-----|
| `dsBackground` | `#1C1C1E` | Page background |
| `dsCardBackground` | `#2C2C2E` | Card background |
| `dsSurface` | `#3A3A3C` | Chip / pill background |
| `dsAccentPrimary` | `#D4AF37` | Primary accent, tint |
| `dsAccentSecondary` | `#E9C46A` | Secondary accent |
| `dsErrorRed` | `#E63946` | Error / danger |

Typography: serif editorial titles (`dsLargeTitle` → `dsTitle2`), lightweight body (`dsBody`, `dsCaption`, `dsLabel`).

---

## External APIs

| Service | Key constant | Purpose |
|---------|-------------|---------|
| OpenRouter (free tier) | `APIKeys.openRouter` | Colorimetry analysis, outfit suggestions, vision tagging — with model fallback |
| OpenWeather 3.0 | `APIKeys.openWeather` | Real-time weather for outfit context |

Both keys are injected at build time from `APIKeys.swift` (gitignored). See [API Keys](#api-keys) below.

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
# Edit APIKeys.swift and fill in your OpenRouter and OpenWeather keys

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
    static let openRouter  = "YOUR_OPENROUTER_KEY"
    static let openWeather = "YOUR_OPENWEATHER_KEY"
}
```

For CI, keys are injected from GitHub Secrets: `OPENROUTER_API_KEY` and `WEATHER_API_KEY`.

---

## CI / CD

| Workflow | Trigger | Runner | Action |
|----------|---------|--------|--------|
| `ios-ci.yml` | Push / PR to `main` | `macos-15` | XcodeGen → build for iPhone simulator (Debug) |
| `ios-cd.yml` | `workflow_dispatch` or `v*` tag | `macos-26` | Archive → export IPA → upload to TestFlight |

The CD workflow uses **manual code signing** (certificate + provisioning profile as GitHub Secrets) and the `macos-26` runner (Xcode 26, iOS 26 SDK — required by Apple for all TestFlight uploads).

**CD secrets required:**

| Secret | Description |
|--------|-------------|
| `OPENROUTER_API_KEY` / `WEATHER_API_KEY` | App API keys |
| `DISTRIBUTION_CERTIFICATE_P12` | base64-encoded Apple Distribution `.p12` |
| `DISTRIBUTION_CERTIFICATE_PASSWORD` | `.p12` password |
| `APP_STORE_PROVISIONING_PROFILE` | base64-encoded App Store `.mobileprovision` |
| `APP_STORE_CONNECT_KEY_CONTENT` | `.p8` ASC API key file contents |
| `APP_STORE_CONNECT_KEY_ID` | ASC key ID |
| `APP_STORE_CONNECT_ISSUER_ID` | ASC issuer ID |
| `DEVELOPMENT_TEAM` | Apple Team ID |

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

EN and ES fully supported (305 keys). Keys are centralised in `Strings.swift` using `String(localized:locale:Strings.activeLocale)` for runtime locale switching without app restart.

```swift
Text(Strings.profileRetakeButton)   // → "Retake Analysis" / "Repetir Análisis"
```

To add a locale: create `xx.lproj/Localizable.strings`, mirror all 305 keys, add the language to `project.yml`.

---

## Developer Tooling (Claude Code)

The `.claude/` directory contains skills and reference docs for working with this repo inside [Claude Code](https://claude.ai/code).

| Skill / File | Invocation | Purpose |
|---|---|---|
| `run-smartstylist` | `/run-smartstylist` | Build, launch, and screenshot the app on iOS Simulator |
| `new-test` | `/new-test <Subject>` | Generate an XCTest file following project conventions |
| `figma-design-system.md` | — | Token reference and Figma↔SwiftUI translation guide |

---

## Legal

Hosted via GitHub Pages from `docs/` on `main`:

- **Privacy Policy**: https://rubenaparicio-byte.github.io/smartstylist/privacy.html
- **Terms of Use**: https://rubenaparicio-byte.github.io/smartstylist/terms.html
