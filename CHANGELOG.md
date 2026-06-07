# Changelog

All notable changes to SmartStylist are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [v0.2.3] — 2026-06-07 · Developer Tooling

### Added

- **`.claude/figma-design-system.md`** — Comprehensive Figma ↔ SwiftUI reference covering all design tokens (colors, typography, spacing, shapes, animations), component catalog with code snippets, screen patterns, icon conventions, localization rules, and a Figma→Code translation checklist
- **`.claude/skills/run-smartstylist/`** — Claude Code skill (`smoke.sh` + `SKILL.md`) for building, launching, and screenshotting the app on the iOS Simulator from the command line; invocable as `/run-smartstylist`

### Changed

- `CLAUDE.md` — added pointer to `figma-design-system.md`

---

## [v0.2.2] — 2026-06-07 · CD Pipeline — TestFlight

### Fixed

#### CD Pipeline (manual signing + iOS 26 SDK)
- Switched from automatic to **manual code signing** in `ios-cd.yml` — CI environments have no registered devices, so automatic signing always fails with `No profiles for 'com.rubenaparicio.SmartStylist' were found`
- Runner upgraded from `macos-15` (Xcode 16.4, iOS 18.5 SDK) to **`macos-26`** (Xcode 26, iOS 26 SDK) — Apple rejects uploads built with older SDKs since 2026
- Fixed App Store upload error 1190: created app record in **App Store Connect** (separate from Apple Developer Portal where the App ID lives)
- Fixed validation errors 90474/90475 (missing orientations + iPad launch screen): moved `UIRequiresFullScreen`, `UISupportedInterfaceOrientations`, `CFBundleIconName`, and `UILaunchScreen` from `Info.plist` into `project.yml`'s `info.properties` — XcodeGen regenerates `Info.plist` on every `xcodegen generate`, so keys edited directly in the file are silently discarded
- Added placeholder 1024×1024 universal `AppIcon.png` to `Assets.xcassets/AppIcon.appiconset/` — resolves missing icon validation errors; replace with real icon before public App Store release

### Changed
- `ios-cd.yml` — full rewrite: temporary keychain for `.p12`, provisioning profile installed by UUID, `ExportOptions.plist` with `signingStyle: manual`, `xcodebuild archive` with `CODE_SIGN_STYLE=Manual`
- `project.yml` — added `CFBundleIconName`, `UILaunchScreen`, `UIRequiresFullScreen`, `UISupportedInterfaceOrientations` to `info.properties`; added `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon` to target build settings

### Added
- `SmartStylist/Assets.xcassets/AppIcon.appiconset/` — universal icon asset catalog entry
- `.gitignore` — added `*.p12`, `*.cer`, `*.pem`, `*.mobileprovision`, `private.key`, `*.certSigningRequest`

> **Required new GitHub Secrets:** `DISTRIBUTION_CERTIFICATE_P12`, `DISTRIBUTION_CERTIFICATE_PASSWORD`, `APP_STORE_PROVISIONING_PROFILE`

---

## [v0.2.1] — 2026-06-06 · Legal Docs Live

### Changed
- Repository visibility set to **public** — enables GitHub Pages on the free GitHub plan; API keys remain gitignored and are never committed
- GitHub Pages activated from `docs/` on `main`; legal docs now live:
  - **Privacy Policy**: https://rubenaparicio-byte.github.io/smartstylist/privacy.html
  - **Terms of Use**: https://rubenaparicio-byte.github.io/smartstylist/terms.html
- `README.md` updated with canonical GitHub Pages URLs (replaces placeholder note)

---

## [v0.2.0] — 2026-06-06 · App Store Feature Complete

### Added

#### Navigation
- **MainTabView** — 4-tab navigation hub with luxury `UITabBarAppearance` (`dsCardSlate` background, `dsAccentGold` tint, `dsTextTertiary` unselected icons): Today · Wardrobe · Insights · Profile
- `RootView` cleaned up; inline `MainTabView` stub removed

#### UX Quality — Luxury Components
- **LuxuryLoadingView** — multi-ring gold spinner with cycling localized messages (`Task.sleep` async message loop); replaces all plain `ProgressView` usages
- **LuxuryErrorView** — typed error display for `StyleEngineError` cases (insufficientWardrobe / locationDenied / aiUnavailable); gold retry button + ghost Settings CTA; `UIApplication.shared.open` for Settings deep-link

#### Style Engine
- **Offline colorimetry fallback** — when Gemini is unreachable, `StyleEngineViewModel.buildOfflineSuggestion` scores items by `recommendedColorHexes` (2 pts) and neutral hex match (1 pt), returning a local `StyleResponse` without any network call; `isOfflineSuggestion` flag drives an offline banner in the view
- **`StyleEngineError` typed enum** (`.insufficientWardrobe`, `.locationDenied`, `.aiUnavailable(String)`) replaces generic `errorMessage: String?`
- **`DisplayState` computed enum** on `StyleEngineView` drives `animation(value:)` transitions between loading / error / suggestion / empty states

#### Closet — Advanced Filters & Search (Module 2)
- `ClosetViewModel`: `selectedStyles: Set<String>`, `selectedPattern: String?`, `showOnlyStatus: ItemStatus?`; `hasActiveFilters: Bool`; `clearFilters()`; static `knownStyles` / `knownPatterns` lookup tables; `filteredItems` refactored into five private predicates (`statusMatches` / `categoryMatches` / `styleMatches` / `patternMatches` / `textMatches`)
- `VirtualClosetView`: replaced `.searchable` with a luxury custom search bar (gold border 0.5 pt, `dsCardSlate` background, animated magnifying-glass icon); expandable filter panel (`Material.ultraThinMaterial`, STATUS / STYLES / PATTERNS chip sections, `GoldDivider` separators, in-panel clear-filters link); badge dot on filter toggle when `hasActiveFilters`; `filterKey`-driven `.easeInOut(0.22 s)` grid animation
- **NoResultsView** — luxury empty state with `magnifyingglass` icon and gold "Clear Filters" button

#### Insights — WardrobeInsightsView & ViewModel (Module 3)
- `InsightsViewModel` — pure computation, no SwiftUI/SwiftData mutations; `referenceDate`-injectable for deterministic tests
  - `styleDistribution(from:)` — counts visible items by style, sorted desc, assigns gold/slate palette hex
  - `topWornItems(from:history:referenceDate:)` — cross-references `OutfitHistory` for the last 30 days, returns top 3 active items by wear count
  - `closetHealth(from:)` — counts active/archived/disposed, computes percentages, finds top disposal reason
- `WardrobeInsightsView` — Swift Charts `SectorMark` donut (innerRadius 0.56, gold/slate palette, custom 2-col legend); ranked top-worn cards with `GoldDivider`; closet health stat pills + segmented proportion bar; luxury empty state

#### Profile — ProfileSettingsView & ViewModel (Module 4)
- `ProfileViewModel` (`@MainActor @Observable`) — `retakeAnalysis(profile:context:)` deletes only `UserProfile` preserving the wardrobe; `deleteAllData(context:)` purges all SwiftData entities (`UserProfile`, `ClothingItem`, `OutfitHistory`) — satisfies Apple's data-deletion App Store requirement
- `ProfileSettingsView` — profile header (seasonal colorimetry name, metal indicator); recommended colour palette swatches (scrollable circles from `recommendedColorHexes`, colour-matched shadow); avoid-colour swatches with `xmark` overlay; physical traits card with `GoldDivider` rows; Retake Analysis button (gold outline); Danger Zone section with destructive Delete All button (red, with 0.08-opacity red fill)
- Both actions are guarded by `.alert` confirmation dialogs with localized titles and messages

#### CD Pipeline
- `ios-cd.yml` — TestFlight deployment on `workflow_dispatch` or `v*` tag; macos-15 runner; xcodebuild archive + export with `-allowProvisioningUpdates`; `xcrun altool --upload-app` via App Store Connect API key (`.p8`); GitHub artifact upload (30-day retention)
- `project.yml` — signing settings: `PRODUCT_BUNDLE_IDENTIFIER`, `CODE_SIGN_STYLE: Automatic`

#### Localization
- Full EN + ES coverage — 78 keys across 8 namespaces: common, loading, onboarding, style engine, events, wardrobe, wardrobe filters, insights, profile & settings
- Centralised in `Strings.swift` using `String(localized:)` for per-call bundle lookup

#### Legal Docs (GitHub Pages)
- `docs/privacy.html` — local-only SwiftData storage, transient Gemini vision use, no analytics SDKs, in-app data-deletion instructions
- `docs/terms.html` — EULA, AI disclaimer, weather disclaimer, third-party service links, limitation of liability, governing law (Spain)

### Changed
- `RootView` — `MainTabView` extracted to `SmartStylist/Views/Main/MainTabView.swift`
- `StyleEngineView` — switched from `.alert` for errors to inline `LuxuryErrorView`; `@Bindable` state drives `DisplayState` transitions
- `OnboardingContainerView` — `LuxuryLoadingView` overlay replaces plain `ProgressView`; localized button labels and alert copy
- `VirtualClosetView` — category chips now use `cat.localizedName` (localized); `withAnimation(.dsDefault)` on chip tap
- `project.yml` — added `options.developmentLanguage: en`
- CI (`ios-ci.yml`) + CD (`ios-cd.yml`) — `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: true` opts into Node.js 24 ahead of the June 2026 GitHub Actions deadline

### Fixed
- **`withAnimation` in ViewModel** — removed all `withAnimation(.dsDefault) { … }` calls from `StyleEngineViewModel.generateOutfit`; `withAnimation` is a SwiftUI function and caused `cannot find 'withAnimation' in scope` on CI. Animations now live exclusively in the View layer via `.animation(value:)` modifiers.

### Tests
- `ClosetViewModelTests` — 28 tests: extended `makeItem` helper with `style/pattern/color/tags` params; 17 new tests covering `hasActiveFilters`, `clearFilters`, single/multi style, pattern, status, text search by color/tag/style/category rawValue, combined filters
- `InsightsViewModelTests` — 13 new tests: `styleDistribution` (count, disposed exclusion, sort order, archived inclusion, color assignment); `topWornItems` (empty history, ≤3 cap, 30-day boundary, sort, disposed exclusion); `closetHealth` (count, top reason, percentages, nil reason)
- `ProfileViewModelTests` — 7 new tests (`@MainActor`, in-memory `ModelContainer`): default flags, retake deletes profile and preserves wardrobe, deleteAllData clears all entities, works on empty store, handles multiple profiles

---

## [v0.1.1] — 2026-06-05 · CI & Build Fixes

### Fixed
- CI runner upgraded from `macos-14` (Xcode 15.4) to `macos-15` (Xcode 16.4)
- `APIKeys.swift.template` renamed to remove `.swift` extension — prevents duplicate-symbol build error
- `StyleEngineViewModel` marked `@MainActor` for Swift 6 strict concurrency

### Added
- Claude Code project configuration (`.claude/`, `.mcp.json`, `CLAUDE.md`)

---

## [v0.1.0] — 2026-06-05 · Initial Release

First complete baseline of the SmartStylist iOS app.

### Modules

#### Design System
- `DS+Colors.swift` — 9 colour tokens (dsDeepSlate, dsCardSlate, dsSurface, dsAccentGold, dsSoftGold, dsErrorRed + text variants); `Color.init(hex:)`
- `DS+Typography.swift` — 7 font styles; `EditorialStyle` ViewModifier; `View.editorialStyle()`
- `DS+Shapes.swift` — `ContinuousCard`; `LuxuryCardStyle`; `View.luxuryCard(cornerRadius:)`
- `DS+Animations.swift` — `dsDefault` (easeInOut 0.3 s), `dsFast` (0.18 s), `dsSpring`

#### Data Models
- `UserProfile` — seasonal colorimetry fields, `onboardingCompleted`, recommended/avoid colour arrays
- `ClothingItem` — `ItemStatus` enum, `ClothingCategory` enum (Spanish raw values for Gemini), image path, style, pattern, tags
- `OutfitHistory` — clothingItemIds `[UUID]`, date, context, weatherContext
- `StyleResponse` — Codable with snake_case keys; `allItemIds` computed property

#### Services
- `LocationService` — `@MainActor` CoreLocation async wrapper with `CheckedContinuation`
- `WeatherService` — OpenWeather One Call 3.0; rain heuristic from condition string
- `GeminiService` — Gemini 1.5 Flash REST; `analyseProfile` + `suggestOutfit` with 4-rule prompt

#### Onboarding Module
- 4-step `TabView` wizard; `OnboardingViewModel` step machine; async Gemini profile analysis; `ColorimetryResultView` with AccentGold season display

#### Virtual Closet Module (baseline)
- `ClosetViewModel` with `activeItems`, `filteredItems`, `disposeItem / archiveItem / restoreItem`
- `VirtualClosetView` — 2-column `LazyVGrid`, category chips, FAB, `searchable`
- `AddItemView`, `ItemDetailView`, `ClothingItemCard` with silhouette fallback

#### Style Engine Module
- `StyleEngineViewModel` — GPS → weather → Gemini pipeline; 14-day history dedup
- `StyleEngineView` — occasion picker (6 contexts), loading / suggestion / empty states, save-outfit action

#### App Shell
- `SmartStylistApp` — shared `modelContainer` for all three model types
- `RootView` — `@Query` onboarding gate
- `MainTabView` — 2-tab baseline (Today + Wardrobe)

#### Test Coverage (baseline)
- `ClothingItemTests` — `ItemStatus` raw values, `ClothingCategory.allCases`, `StyleResponse` Codable
- `GeminiServiceTests` — full/partial outfit JSON decode
- `ClosetViewModelTests` — activeItems, filteredItems, itemsByCategory (11 tests)
