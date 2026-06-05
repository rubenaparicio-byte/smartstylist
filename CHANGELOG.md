# Changelog

## [v0.1.0] — 2026-06-05 · Initial Release

First complete baseline of the SmartStylist iOS app.

---

### Modules implemented

#### Git & Project Scaffold
- Private GitHub repository under `rubenaparicio-byte/smartstylist`
- Strict `.gitignore` covering Xcode artefacts, DerivedData, SPM cache, CocoaPods, Fastlane, secrets, and OS files
- `project.yml` XcodeGen manifest targeting iOS 17+, Swift 5.10, with app + unit-test targets and all required privacy usage descriptions
- `APIKeys.template.swift` committed as a safe placeholder; `APIKeys.swift` is gitignored

#### Design System (`SmartStylist/DesignSystem/`)
- **DS+Colors.swift** — 9 colour tokens: `dsDeepSlate` (#1C1C1E), `dsCardSlate` (#2C2C2E), `dsSurface` (#3A3A3C), `dsAccentGold` (#D4AF37), `dsSoftGold` (#E9C46A), `dsErrorRed` (#E63946), plus three text-opacity variants; hex `Color.init(hex:)` initialiser
- **DS+Typography.swift** — 7 font styles across serif editorial (large title, title, title2) and default-design readable (body, bodyMedium, caption, label) weights; `EditorialStyle` ViewModifier with 2.5pt tracking; `View.editorialStyle()` extension
- **DS+Shapes.swift** — `ContinuousCard` Shape; `LuxuryCardStyle` ViewModifier applying `dsCardSlate` background, continuous-corner clip, and 0.5pt AccentGold border at 0.15 opacity; `View.luxuryCard(cornerRadius:)` extension
- **DS+Animations.swift** — `Animation.dsDefault` (easeInOut 0.3s), `dsFast` (0.18s), `dsSpring` (response 0.4, damping 0.75)

#### Data Models (`SmartStylist/Models/`)
- **UserProfile** — `@Model` with `@Attribute(.unique)` UUID, bodyType, skinTone, eyeColor, hairColor, seasonalColorimetry, styleGuidelines, onboardingCompleted
- **ClothingItem** — `@Model`; `ItemStatus` enum (`.active`, `.archived`, `.disposed`) and `ClothingCategory` enum (`.top`/"superior", `.bottom`/"inferior", `.footwear`/"calzado", `.outerwear`/"abrigo", `.accessory`/"accesorio"); imagePath, primaryColor, pattern, style, tags, status, createdAt fields
- **OutfitHistory** — `@Model` with UUID, date, clothingItemIds ([UUID]), context, weatherContext
- **StyleResponse** — `Codable` struct with snake_case CodingKeys; nested `OutfitSuggestion` with four optional UUID fields; `allItemIds: [UUID]` computed property

#### Services (`SmartStylist/Services/`)
- **LocationService** — `@MainActor` CoreLocation async wrapper; `requestCoordinate() async throws` using `CheckedContinuation`; cached-coordinate fast-path; `nonisolated` delegate methods dispatching back to `@MainActor` via `Task`; `LocationError.denied`
- **WeatherService** — OpenWeather One Call 3.0 REST client; `fetchWeather(for: CLLocationCoordinate2D) async throws -> WeatherData`; parses `current.temp`, `current.feels_like`, `current.weather[0].main`; rain heuristic from condition string; `WeatherData.displayString` convenience property
- **GeminiService** — Gemini 1.5 Flash REST client; `generate(prompt:) async throws -> String`; `analyseProfile(bodyType:skinTone:eyeColor:hairColor:)` returning `(season, guidelines)`; `suggestOutfit(...)` returning a decoded `StyleResponse`; prompt enforces 4 rules: inventory UUIDs only, no-repeat last 14 days, colorimetry harmony, weather/occasion match

#### Reusable UI Components (`SmartStylist/Views/Components/`)
- **LuxuryCard** — generic `@ViewBuilder` container applying `.luxuryCard()`
- **SelectionChip** — toggle button with AccentGold/dsSurface states and `dsDefault` animation
- **GoldDivider** — 0.5pt AccentGold hairline at 0.25 opacity
- **LoadingPulse** — pulsing AccentGold circle with `repeatForever(autoreverses:)` animation
- **FlowLayout** — custom `Layout` conformance wrapping chips into rows respecting available width

#### Clothing Silhouette (`SmartStylist/Views/Closet/SilhouetteView.swift`)
- `Canvas`-based golden wire outlines for all five `ClothingCategory` cases (T-shirt, trousers, shoe, coat, diamond accessory); proportional scaling to `size` parameter; gold stroke at 0.35 opacity

#### Onboarding Module
- **OnboardingViewModel** — `@Observable` step machine (`bodyType → skinTone → hairEye → result`); `canAdvance` guard per step; async Gemini profile analysis on `.hairEye` advance; `save(to:)` persisting completed `UserProfile` to SwiftData; preset option arrays for body types, skin tones, eye and hair colours
- **OnboardingContainerView** — paged `TabView` with gold progress-capsule bar, loading overlay with `LoadingPulse`, advance/CTA button that switches label on final input step, error alert; uses `@Bindable` shadow to bind into `@Observable` VM
- **BodyTypeStepView / SkinToneStepView / HairEyeStepView** — `@Bindable` VM input; editorial heading, `GoldDivider`, `FlowLayout` of `SelectionChip` items
- **ColorimetryResultView** — displays analysed season in AccentGold with SF Symbol icon, style guidelines in `LuxuryCard`, "Enter My Wardrobe" CTA

#### Virtual Closet Module
- **ClosetViewModel** — `@Observable`; `activeItems(from:)` filters to `.active` only (`.disposed` and `.archived` are permanently excluded from suggestions); `filteredItems(from:)` chains category and text search; `disposeItem / archiveItem / restoreItem` mutations; `itemsByCategory` grouping in `ClothingCategory.allCases` order
- **ClothingItemCard** — ZStack with real image or golden silhouette fallback, category badge with `ultraThinMaterial`, context-menu "Retire this piece" destructive action
- **VirtualClosetView** — `@Query` allItems, horizontal `SelectionChip` category filter, `LazyVGrid` 2-column layout, `NavigationLink` to detail, AccentGold FAB, `searchable` modifier, `ultraThinMaterial` toolbar
- **AddItemView** — Form with `Picker` (category), TextFields (style, colour, tags), creates and inserts `ClothingItem` on save
- **ItemDetailView** — large silhouette, `LuxuryCard` detail rows, "Retire this piece" destructive button shown only when `status == .active`

#### Style Engine Module
- **StyleEngineViewModel** — `@MainActor @Observable`; `generateOutfit(profile:activeItems:history:) async` orchestrates GPS → weather → Gemini pipeline; history filtered to last 14 days; JSON payload encoders for profile, weather, inventory, and history
- **WeatherBadgeView** — gold weather SF Symbol icon, `displayString`, feels-like temperature, `luxuryCard` wrapper
- **OutfitSuggestionCard** — `LuxuryCard` showing context analysis, 2×2 silhouette grid for non-nil outfit slots, style tip with sparkles icon
- **StyleEngineView** — `@Query` all items (in-memory `.active` filter), occasion picker (6 options), conditional content states (suggestion / loading / empty), refresh toolbar button, auto-generate `.task` on first appear, error alert

#### App Shell
- **SmartStylistApp** — `@main` entry, `WindowGroup { RootView() }`, shared `modelContainer` for all three model types
- **RootView** — `@Query` profiles gate: shows `OnboardingContainerView` until `onboardingCompleted == true`, then `MainTabView`
- **MainTabView** — two-tab `TabView` (Today → `StyleEngineView`, Wardrobe → `VirtualClosetView`) tinted with `dsAccentGold`

---

### Test Coverage

| File | Tests |
|---|---|
| `ClothingItemTests.swift` | ItemStatus raw values, allCases count, StyleResponse full decode, nil-UUID exclusion |
| `GeminiServiceTests.swift` | Full outfit decode (4 UUIDs), missing abrigo decode (3 UUIDs) |
| `ClosetViewModelTests.swift` | activeItems excludes disposed, excludes archived, category filter, nil-category returns all, itemsByCategory grouping |

---

### Setup Instructions

1. Clone: `git clone https://github.com/rubenaparicio-byte/smartstylist.git`
2. Install XcodeGen: `brew install xcodegen`
3. Generate project: `cd smartstylist && xcodegen generate`
4. Copy API keys template: `cp SmartStylist/Config/APIKeys.template.swift SmartStylist/Config/APIKeys.swift`
5. Fill in your Gemini and OpenWeather API keys in `APIKeys.swift`
6. Open `SmartStylist.xcodeproj` in Xcode 16+
7. Select a simulator (iPhone 16 recommended) and run
8. Grant location permission when prompted — required for weather-based outfit suggestions
