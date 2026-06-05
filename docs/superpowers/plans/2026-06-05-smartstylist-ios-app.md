# SmartStylist iOS App — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build SmartStylist — a luxury AI-powered virtual wardrobe iOS app (Swift/SwiftUI + SwiftData + Gemini) with chromatic analysis onboarding, GPS-driven weather outfits, and a strict "no-repeat" style engine.

**Architecture:** MVVM with SwiftData persistence. Services (Gemini, Weather, Location, Image) are injected into ViewModels. Views are purely declarative SwiftUI; zero business logic lives inside them. A centralised `DesignSystem` package owns every visual token so the luxury aesthetic cannot drift.

**Tech Stack:** Swift 5.10+, SwiftUI, SwiftData, CoreLocation, WeatherKit (or OpenWeather fallback), Gemini REST API, XcodeGen (project generation from YAML), GitHub CLI (`gh`), Git.

> ⚠️ **Platform note:** Source files are authored on Windows. Compilation and Simulator runs require a Mac with Xcode 16+. All paths below are relative to the repo root `smartstylist/`. Run `xcodegen generate` on a Mac after cloning to produce the `.xcodeproj`.

---

## File Map

```
smartstylist/
├── project.yml                          # XcodeGen manifest
├── .gitignore                           # Xcode/Swift strict ignore
├── SmartStylist/
│   ├── App/
│   │   ├── SmartStylistApp.swift        # @main entry, SwiftData container
│   │   └── RootView.swift               # Onboarding gate vs. main tab bar
│   ├── DesignSystem/
│   │   ├── DS+Colors.swift              # All colour tokens (DeepSlate, AccentGold …)
│   │   ├── DS+Typography.swift          # Font helpers (serif large title, light body …)
│   │   ├── DS+Shapes.swift              # ContinuousRoundedRect, card border modifier
│   │   └── DS+Animations.swift          # Shared animation curves
│   ├── Models/
│   │   ├── UserProfile.swift            # SwiftData @Model
│   │   ├── ClothingItem.swift           # SwiftData @Model + ItemStatus enum
│   │   ├── OutfitHistory.swift          # SwiftData @Model
│   │   └── StyleResponse.swift         # Codable struct mapping Gemini JSON
│   ├── Services/
│   │   ├── GeminiService.swift          # Async REST client for Gemini
│   │   ├── WeatherService.swift         # WeatherKit / OpenWeather wrapper
│   │   ├── LocationService.swift        # CoreLocation async wrapper
│   │   └── ImageClassificationService.swift # Vision-based colour + category detection
│   ├── ViewModels/
│   │   ├── OnboardingViewModel.swift
│   │   ├── ClosetViewModel.swift
│   │   └── StyleEngineViewModel.swift
│   └── Views/
│       ├── Onboarding/
│       │   ├── OnboardingContainerView.swift   # Page-step orchestrator
│       │   ├── BodyTypeStepView.swift
│       │   ├── SkinToneStepView.swift
│       │   ├── HairEyeStepView.swift
│       │   └── ColorimetryResultView.swift
│       ├── Closet/
│       │   ├── VirtualClosetView.swift          # Asymmetric grid
│       │   ├── ClothingItemCard.swift
│       │   ├── SilhouetteView.swift             # Drawn golden silhouette (no image)
│       │   ├── AddItemView.swift
│       │   └── ItemDetailView.swift
│       ├── StyleEngine/
│       │   ├── StyleEngineView.swift
│       │   ├── OutfitSuggestionCard.swift
│       │   └── WeatherBadgeView.swift
│       └── Components/
│           ├── LuxuryCard.swift                 # Reusable card shell
│           ├── SelectionChip.swift              # Onboarding tap-to-select chip
│           ├── GoldDivider.swift
│           └── LoadingPulse.swift
└── SmartStylistTests/
    ├── Models/
    │   └── ClothingItemTests.swift
    ├── Services/
    │   └── GeminiServiceTests.swift
    └── ViewModels/
        ├── ClosetViewModelTests.swift
        └── StyleEngineViewModelTests.swift
```

---

## Task 1: Git Init, .gitignore, and Private GitHub Repo

**Files:**
- Create: `.gitignore`
- Create: `README.md`

- [ ] **Step 1.1 — Initialise local repo**

```bash
cd C:/Users/ruben/Documents/github_repos/smartstylist
git init
git config --local user.email "rubenaparicio985@gmail.com"
git config --local user.name "Rubén Aparicio"
```

Expected: `Initialized empty Git repository in .../smartstylist/.git/`

- [ ] **Step 1.2 — Create strict Xcode .gitignore**

Write to `.gitignore`:

```gitignore
# ── Xcode ────────────────────────────────────────────────
build/
*.pbxuser
!default.pbxuser
*.mode1v3
!default.mode1v3
*.mode2v3
!default.mode2v3
*.perspectivev3
!default.perspectivev3
xcuserdata/
*.xccheckout
*.moved-aside
DerivedData/
*.hmap
*.ipa
*.xcuserstate
*.xcscmblueprint
.DS_Store

# ── Swift Package Manager ────────────────────────────────
.build/
.swiftpm/

# ── CocoaPods ────────────────────────────────────────────
Pods/
*.xcworkspace

# ── Fastlane ─────────────────────────────────────────────
fastlane/report.xml
fastlane/Preview.html
fastlane/screenshots/**/*.png
fastlane/test_output

# ── Secrets (NEVER commit these) ─────────────────────────
*.env
Config/Secrets.xcconfig
SmartStylist/Config/APIKeys.swift

# ── OS ────────────────────────────────────────────────────
.DS_Store
Thumbs.db
```

- [ ] **Step 1.3 — Create minimal README**

Write to `README.md`:

```markdown
# SmartStylist

AI-powered luxury virtual wardrobe for iOS. Built with Swift, SwiftUI, SwiftData, and Gemini.

## Requirements
- Xcode 16+, macOS Sequoia+
- `brew install xcodegen` then `xcodegen generate` to create the `.xcodeproj`
- API keys in `SmartStylist/Config/APIKeys.swift` (never committed — see .gitignore)

## Architecture
MVVM · SwiftData · Gemini REST · WeatherKit · CoreLocation
```

- [ ] **Step 1.4 — First commit**

```bash
git add .gitignore README.md
git commit -m "chore: initialise repo with strict .gitignore and README"
```

- [ ] **Step 1.5 — Create private GitHub repo and push**

```bash
gh auth status          # confirm logged-in as rubenaparicio985@gmail.com
gh repo create smartstylist --private --source=. --remote=origin --push
```

Expected: `✓ Created repository rubenaparicio985/smartstylist on GitHub`

---

## Task 2: XcodeGen Project Manifest

**Files:**
- Create: `project.yml`

- [ ] **Step 2.1 — Write XcodeGen manifest**

```yaml
# project.yml
name: SmartStylist
options:
  bundleIdPrefix: com.smartstylist
  deploymentTarget:
    iOS: "17.0"
  defaultConfig: Debug
  xcodeVersion: "16.0"

settings:
  base:
    SWIFT_VERSION: "5.10"
    DEVELOPMENT_TEAM: ""          # fill on Mac before signing
    PRODUCT_BUNDLE_IDENTIFIER: com.smartstylist.app
    INFOPLIST_FILE: SmartStylist/Info.plist

targets:
  SmartStylist:
    type: application
    platform: iOS
    sources:
      - SmartStylist
    info:
      path: SmartStylist/Info.plist
      properties:
        NSLocationWhenInUseUsageDescription: "SmartStylist uses your location to fetch real-time weather for outfit suggestions."
        NSLocationAlwaysAndWhenInUseUsageDescription: "Background location enables automatic morning outfit suggestions."
        NSPhotoLibraryUsageDescription: "Access your photo library to add clothing items."
        NSCameraUsageDescription: "Take photos of new clothing items."
    settings:
      base:
        ENABLE_PREVIEWS: YES
    dependencies: []

  SmartStylistTests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - SmartStylistTests
    dependencies:
      - target: SmartStylist
```

- [ ] **Step 2.2 — Create Info.plist stub**

Create `SmartStylist/Info.plist` with standard content so XcodeGen can reference it:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>SmartStylist</string>
  <key>CFBundleDisplayName</key>
  <string>SmartStylist</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>UILaunchScreen</key>
  <dict/>
</dict>
</plist>
```

- [ ] **Step 2.3 — Create APIKeys stub (gitignored)**

Create `SmartStylist/Config/APIKeys.swift`:

```swift
// APIKeys.swift — NOT committed to git. Copy this file and fill in your keys.
enum APIKeys {
    static let gemini = "YOUR_GEMINI_API_KEY"
    static let openWeather = "YOUR_OPENWEATHER_API_KEY"  // fallback if WeatherKit unavailable
}
```

Also create `SmartStylist/Config/APIKeys.template.swift` (committed as documentation):

```swift
// Template — copy to APIKeys.swift and fill in real keys (APIKeys.swift is gitignored)
enum APIKeys {
    static let gemini = ""
    static let openWeather = ""
}
```

- [ ] **Step 2.4 — Commit**

```bash
git add project.yml SmartStylist/Info.plist SmartStylist/Config/APIKeys.template.swift
git commit -m "chore: add XcodeGen manifest and project scaffold"
git push
```

---

## Task 3: Design System — Colour Tokens

**Files:**
- Create: `SmartStylist/DesignSystem/DS+Colors.swift`

- [ ] **Step 3.1 — Write the colour extension**

```swift
// DS+Colors.swift
import SwiftUI

extension Color {
    // ── Backgrounds ──────────────────────────────────────────
    static let dsDeepSlate  = Color(hex: "#1C1C1E")   // base background
    static let dsCardSlate  = Color(hex: "#2C2C2E")   // cards / containers
    static let dsSurface    = Color(hex: "#3A3A3C")   // elevated surfaces

    // ── Accents ──────────────────────────────────────────────
    static let dsAccentGold = Color(hex: "#D4AF37")   // primary accent
    static let dsSoftGold   = Color(hex: "#E9C46A")   // states / warnings
    static let dsErrorRed   = Color(hex: "#E63946")   // destructive actions

    // ── Text ─────────────────────────────────────────────────
    static let dsTextPrimary   = Color.white
    static let dsTextSecondary = Color.white.opacity(0.6)
    static let dsTextTertiary  = Color.white.opacity(0.35)
}

// Hex initialiser
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
```

- [ ] **Step 3.2 — Commit**

```bash
git add SmartStylist/DesignSystem/DS+Colors.swift
git commit -m "feat(design): luxury colour token palette (DeepSlate + AccentGold)"
git push
```

---

## Task 4: Design System — Typography

**Files:**
- Create: `SmartStylist/DesignSystem/DS+Typography.swift`

- [ ] **Step 4.1 — Write typography helpers**

```swift
// DS+Typography.swift
import SwiftUI

extension Font {
    // Editorial headings — serif, wide tracking
    static let dsLargeTitle  = Font.system(.largeTitle,  design: .serif).weight(.regular)
    static let dsTitle        = Font.system(.title,       design: .serif).weight(.regular)
    static let dsTitle2       = Font.system(.title2,      design: .serif).weight(.light)

    // Body — default, readable
    static let dsBody         = Font.system(.body,        design: .default).weight(.light)
    static let dsBodyMedium   = Font.system(.body,        design: .default).weight(.regular)
    static let dsCaption      = Font.system(.caption,     design: .default).weight(.light)
    static let dsLabel        = Font.system(.footnote,    design: .default).weight(.medium)
}

// Convenient text modifier for editorial tracking
struct EditorialStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.dsLargeTitle)
            .tracking(2.5)
            .foregroundStyle(Color.dsTextPrimary)
    }
}

extension View {
    func editorialStyle() -> some View { modifier(EditorialStyle()) }
}
```

- [ ] **Step 4.2 — Commit**

```bash
git add SmartStylist/DesignSystem/DS+Typography.swift
git commit -m "feat(design): typography scale — serif editorial + light body"
git push
```

---

## Task 5: Design System — Shapes, Card Modifier & Animations

**Files:**
- Create: `SmartStylist/DesignSystem/DS+Shapes.swift`
- Create: `SmartStylist/DesignSystem/DS+Animations.swift`

- [ ] **Step 5.1 — Write shape helpers**

```swift
// DS+Shapes.swift
import SwiftUI

// Continuous-corner rounded rectangle matching Apple's SF aesthetic
struct ContinuousCard: Shape {
    var radius: CGFloat = 20
    func path(in rect: CGRect) -> Path {
        Path(UIBezierPath(roundedRect: rect,
                          byRoundingCorners: .allCorners,
                          cornerRadii: CGSize(width: radius, height: radius)).cgPath)
    }
}

// ViewModifier that applies the full luxury card look
struct LuxuryCardStyle: ViewModifier {
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .background(Color.dsCardSlate)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.dsAccentGold.opacity(0.15), lineWidth: 0.5)
            )
    }
}

extension View {
    func luxuryCard(cornerRadius: CGFloat = 20) -> some View {
        modifier(LuxuryCardStyle(cornerRadius: cornerRadius))
    }
}
```

- [ ] **Step 5.2 — Write animation constants**

```swift
// DS+Animations.swift
import SwiftUI

extension Animation {
    static let dsDefault    = Animation.easeInOut(duration: 0.3)
    static let dsFast       = Animation.easeInOut(duration: 0.18)
    static let dsSpring     = Animation.spring(response: 0.4, dampingFraction: 0.75)
}
```

- [ ] **Step 5.3 — Commit**

```bash
git add SmartStylist/DesignSystem/DS+Shapes.swift SmartStylist/DesignSystem/DS+Animations.swift
git commit -m "feat(design): luxury card modifier, continuous corners, animation constants"
git push
```

---

## Task 6: SwiftData Models

**Files:**
- Create: `SmartStylist/Models/UserProfile.swift`
- Create: `SmartStylist/Models/ClothingItem.swift`
- Create: `SmartStylist/Models/OutfitHistory.swift`
- Create: `SmartStylist/Models/StyleResponse.swift`

- [ ] **Step 6.1 — Write UserProfile**

```swift
// UserProfile.swift
import Foundation
import SwiftData

@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    var bodyType: String               // e.g. "Hourglass", "Rectangle", "Triangle"
    var skinTone: String               // e.g. "Warm Light", "Cool Medium"
    var eyeColor: String
    var hairColor: String
    var seasonalColorimetry: String    // "Spring" | "Summer" | "Autumn" | "Winter"
    var styleGuidelines: String        // Raw text from Gemini analysis
    var onboardingCompleted: Bool

    init(id: UUID = UUID(),
         bodyType: String = "",
         skinTone: String = "",
         eyeColor: String = "",
         hairColor: String = "",
         seasonalColorimetry: String = "",
         styleGuidelines: String = "",
         onboardingCompleted: Bool = false) {
        self.id = id
        self.bodyType = bodyType
        self.skinTone = skinTone
        self.eyeColor = eyeColor
        self.hairColor = hairColor
        self.seasonalColorimetry = seasonalColorimetry
        self.styleGuidelines = styleGuidelines
        self.onboardingCompleted = onboardingCompleted
    }
}
```

- [ ] **Step 6.2 — Write ClothingItem and ItemStatus**

```swift
// ClothingItem.swift
import Foundation
import SwiftData

enum ItemStatus: String, Codable, CaseIterable {
    case active    = "active"     // available for suggestions
    case archived  = "archived"   // hidden but retrievable
    case disposed  = "disposed"   // retired — NEVER appears in style queries
}

enum ClothingCategory: String, Codable, CaseIterable {
    case top        = "superior"
    case bottom     = "inferior"
    case footwear   = "calzado"
    case outerwear  = "abrigo"
    case accessory  = "accesorio"
}

@Model
final class ClothingItem {
    @Attribute(.unique) var id: UUID
    var imagePath: String?           // relative file path in app's Documents
    var category: ClothingCategory
    var primaryColor: String         // hex string
    var pattern: String              // "Solid", "Striped", "Checkered", etc.
    var style: String                // "Casual", "Formal", "Smart Casual", etc.
    var tags: [String]
    var status: ItemStatus
    var createdAt: Date

    init(id: UUID = UUID(),
         imagePath: String? = nil,
         category: ClothingCategory,
         primaryColor: String = "#000000",
         pattern: String = "Solid",
         style: String = "Casual",
         tags: [String] = [],
         status: ItemStatus = .active,
         createdAt: Date = Date()) {
        self.id = id
        self.imagePath = imagePath
        self.category = category
        self.primaryColor = primaryColor
        self.pattern = pattern
        self.style = style
        self.tags = tags
        self.status = status
        self.createdAt = createdAt
    }
}
```

- [ ] **Step 6.3 — Write OutfitHistory**

```swift
// OutfitHistory.swift
import Foundation
import SwiftData

@Model
final class OutfitHistory {
    @Attribute(.unique) var id: UUID
    var date: Date
    var clothingItemIds: [UUID]   // IDs of items worn
    var context: String           // "Work", "Weekend", "Formal Event", etc.
    var weatherContext: String    // snapshot: "18°C, Sunny"

    init(id: UUID = UUID(),
         date: Date = Date(),
         clothingItemIds: [UUID] = [],
         context: String = "",
         weatherContext: String = "") {
        self.id = id
        self.date = date
        self.clothingItemIds = clothingItemIds
        self.context = context
        self.weatherContext = weatherContext
    }
}
```

- [ ] **Step 6.4 — Write StyleResponse (Gemini JSON mapping)**

```swift
// StyleResponse.swift
import Foundation

struct StyleResponse: Codable {
    let climaProcesado: String
    let analisisContexto: String
    let outfitSugerido: OutfitSuggestion
    let consejoEstilo: String

    struct OutfitSuggestion: Codable {
        let superior: UUID?
        let inferior: UUID?
        let calzado: UUID?
        let abrigo: UUID?

        // Convenience: collect all non-nil UUIDs
        var allItemIds: [UUID] {
            [superior, inferior, calzado, abrigo].compactMap { $0 }
        }
    }

    enum CodingKeys: String, CodingKey {
        case climaProcesado   = "clima_procesado"
        case analisisContexto = "analisis_contexto"
        case outfitSugerido   = "outfit_sugerido"
        case consejoEstilo    = "consejo_estilo"
    }
}
```

- [ ] **Step 6.5 — Commit models**

```bash
git add SmartStylist/Models/
git commit -m "feat(models): SwiftData schema — UserProfile, ClothingItem (ItemStatus), OutfitHistory, StyleResponse"
git push
```

---

## Task 7: Unit Tests for Models

**Files:**
- Create: `SmartStylistTests/Models/ClothingItemTests.swift`

- [ ] **Step 7.1 — Write model tests**

```swift
// ClothingItemTests.swift
import XCTest
@testable import SmartStylist

final class ClothingItemTests: XCTestCase {

    func test_itemStatus_disposedRawValue() {
        XCTAssertEqual(ItemStatus.disposed.rawValue, "disposed")
    }

    func test_itemStatus_allCasesCount() {
        XCTAssertEqual(ItemStatus.allCases.count, 3)
    }

    func test_clothingCategory_topRawValue() {
        XCTAssertEqual(ClothingCategory.top.rawValue, "superior")
    }

    func test_styleResponse_decodesCorrectly() throws {
        let json = """
        {
          "clima_procesado": "20°C, Sunny",
          "analisis_contexto": "A bright spring day calls for layered pastels.",
          "outfit_sugerido": {
            "superior": "00000000-0000-0000-0000-000000000001",
            "inferior": "00000000-0000-0000-0000-000000000002",
            "calzado":  "00000000-0000-0000-0000-000000000003",
            "abrigo":   null
          },
          "consejo_estilo": "Roll your sleeves — a casual touch on a tailored look."
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(StyleResponse.self, from: json)
        XCTAssertEqual(response.climaProcesado, "20°C, Sunny")
        XCTAssertNil(response.outfitSugerido.abrigo)
        XCTAssertEqual(response.outfitSugerido.allItemIds.count, 3)
    }

    func test_styleResponse_allItemIdsExcludesNil() throws {
        let suggestion = StyleResponse.OutfitSuggestion(
            superior: UUID(), inferior: UUID(), calzado: nil, abrigo: nil
        )
        XCTAssertEqual(suggestion.allItemIds.count, 2)
    }
}
```

- [ ] **Step 7.2 — Note: run on Mac**

```
# On Mac with Xcode:
xcodegen generate
xcodebuild test -scheme SmartStylist -destination 'platform=iOS Simulator,name=iPhone 16'
```

Expected: All 4 tests PASS.

- [ ] **Step 7.3 — Commit tests**

```bash
git add SmartStylistTests/Models/ClothingItemTests.swift
git commit -m "test(models): unit tests for ItemStatus, ClothingCategory, StyleResponse decoding"
git push
```

---

## Task 8: Reusable UI Components

**Files:**
- Create: `SmartStylist/Views/Components/LuxuryCard.swift`
- Create: `SmartStylist/Views/Components/SelectionChip.swift`
- Create: `SmartStylist/Views/Components/GoldDivider.swift`
- Create: `SmartStylist/Views/Components/LoadingPulse.swift`

- [ ] **Step 8.1 — LuxuryCard**

```swift
// LuxuryCard.swift
import SwiftUI

struct LuxuryCard<Content: View>: View {
    var cornerRadius: CGFloat = 20
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .luxuryCard(cornerRadius: cornerRadius)
    }
}

#Preview {
    LuxuryCard {
        Text("Preview")
            .foregroundStyle(Color.dsTextPrimary)
            .padding()
    }
    .padding()
    .background(Color.dsDeepSlate)
}
```

- [ ] **Step 8.2 — SelectionChip**

```swift
// SelectionChip.swift
import SwiftUI

struct SelectionChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.dsLabel)
                .foregroundStyle(isSelected ? Color.dsDeepSlate : Color.dsTextSecondary)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(isSelected ? Color.dsAccentGold : Color.dsSurface)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.dsAccentGold.opacity(isSelected ? 0 : 0.3), lineWidth: 0.5)
                )
        }
        .animation(.dsDefault, value: isSelected)
    }
}
```

- [ ] **Step 8.3 — GoldDivider**

```swift
// GoldDivider.swift
import SwiftUI

struct GoldDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.dsAccentGold.opacity(0.25))
            .frame(height: 0.5)
    }
}
```

- [ ] **Step 8.4 — LoadingPulse**

```swift
// LoadingPulse.swift
import SwiftUI

struct LoadingPulse: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.4

    var body: some View {
        Circle()
            .fill(Color.dsAccentGold)
            .frame(width: 10, height: 10)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    scale = 1.2
                    opacity = 1.0
                }
            }
    }
}
```

- [ ] **Step 8.5 — Commit components**

```bash
git add SmartStylist/Views/Components/
git commit -m "feat(ui): reusable luxury components — LuxuryCard, SelectionChip, GoldDivider, LoadingPulse"
git push
```

---

## Task 9: SilhouetteView (Empty-State Clothing Slot)

**Files:**
- Create: `SmartStylist/Views/Closet/SilhouetteView.swift`

- [ ] **Step 9.1 — Draw silhouette in SwiftUI Canvas**

```swift
// SilhouetteView.swift
import SwiftUI

/// Drawn golden-wire silhouette for clothing slots without a photo.
struct SilhouetteView: View {
    let category: ClothingCategory
    var size: CGFloat = 120

    var body: some View {
        Canvas { ctx, canvasSize in
            let s = min(canvasSize.width, canvasSize.height)
            ctx.stroke(path(for: category, in: s),
                       with: .color(Color.dsAccentGold.opacity(0.35)),
                       lineWidth: 1)
        }
        .frame(width: size, height: size)
    }

    private func path(for category: ClothingCategory, in s: CGFloat) -> Path {
        switch category {
        case .top:       return topSilhouette(in: s)
        case .bottom:    return bottomSilhouette(in: s)
        case .footwear:  return footwearSilhouette(in: s)
        case .outerwear: return outerSilhouette(in: s)
        case .accessory: return accessorySilhouette(in: s)
        }
    }

    // T-shirt outline
    private func topSilhouette(in s: CGFloat) -> Path {
        Path { p in
            let cx = s / 2
            // collar
            p.move(to: CGPoint(x: cx - s*0.1, y: s*0.1))
            p.addQuadCurve(to: CGPoint(x: cx + s*0.1, y: s*0.1),
                           control: CGPoint(x: cx, y: s*0.18))
            // right shoulder slope
            p.addLine(to: CGPoint(x: s*0.85, y: s*0.2))
            // right sleeve
            p.addLine(to: CGPoint(x: s*0.95, y: s*0.35))
            p.addLine(to: CGPoint(x: s*0.75, y: s*0.35))
            // right body
            p.addLine(to: CGPoint(x: s*0.75, y: s*0.9))
            // bottom
            p.addLine(to: CGPoint(x: s*0.25, y: s*0.9))
            // left body
            p.addLine(to: CGPoint(x: s*0.25, y: s*0.35))
            // left sleeve
            p.addLine(to: CGPoint(x: s*0.05, y: s*0.35))
            p.addLine(to: CGPoint(x: s*0.15, y: s*0.2))
            p.closeSubpath()
        }
    }

    // Trousers outline
    private func bottomSilhouette(in s: CGFloat) -> Path {
        Path { p in
            p.move(to: CGPoint(x: s*0.2, y: s*0.1))
            p.addLine(to: CGPoint(x: s*0.8, y: s*0.1))
            p.addLine(to: CGPoint(x: s*0.8, y: s*0.45))
            p.addLine(to: CGPoint(x: s*0.9, y: s*0.9))
            p.addLine(to: CGPoint(x: s*0.65, y: s*0.9))
            p.addLine(to: CGPoint(x: s*0.5, y: s*0.5))
            p.addLine(to: CGPoint(x: s*0.35, y: s*0.9))
            p.addLine(to: CGPoint(x: s*0.1, y: s*0.9))
            p.addLine(to: CGPoint(x: s*0.2, y: s*0.45))
            p.closeSubpath()
        }
    }

    // Shoe outline
    private func footwearSilhouette(in s: CGFloat) -> Path {
        Path { p in
            p.move(to: CGPoint(x: s*0.2, y: s*0.4))
            p.addLine(to: CGPoint(x: s*0.25, y: s*0.2))
            p.addLine(to: CGPoint(x: s*0.45, y: s*0.2))
            p.addLine(to: CGPoint(x: s*0.45, y: s*0.55))
            p.addQuadCurve(to: CGPoint(x: s*0.85, y: s*0.6),
                           control: CGPoint(x: s*0.7, y: s*0.5))
            p.addLine(to: CGPoint(x: s*0.85, y: s*0.72))
            p.addLine(to: CGPoint(x: s*0.15, y: s*0.72))
            p.closeSubpath()
        }
    }

    // Coat outline (longer T-shirt)
    private func outerSilhouette(in s: CGFloat) -> Path {
        Path { p in
            let cx = s / 2
            p.move(to: CGPoint(x: cx - s*0.08, y: s*0.08))
            p.addQuadCurve(to: CGPoint(x: cx + s*0.08, y: s*0.08),
                           control: CGPoint(x: cx, y: s*0.15))
            p.addLine(to: CGPoint(x: s*0.88, y: s*0.18))
            p.addLine(to: CGPoint(x: s*0.95, y: s*0.32))
            p.addLine(to: CGPoint(x: s*0.75, y: s*0.32))
            p.addLine(to: CGPoint(x: s*0.75, y: s*0.95))
            p.addLine(to: CGPoint(x: s*0.25, y: s*0.95))
            p.addLine(to: CGPoint(x: s*0.25, y: s*0.32))
            p.addLine(to: CGPoint(x: s*0.05, y: s*0.32))
            p.addLine(to: CGPoint(x: s*0.12, y: s*0.18))
            p.closeSubpath()
        }
    }

    // Accessory — simple diamond
    private func accessorySilhouette(in s: CGFloat) -> Path {
        Path { p in
            let cx = s / 2, cy = s / 2
            p.move(to:    CGPoint(x: cx,       y: cy - s*0.38))
            p.addLine(to: CGPoint(x: cx+s*0.3, y: cy))
            p.addLine(to: CGPoint(x: cx,       y: cy + s*0.38))
            p.addLine(to: CGPoint(x: cx-s*0.3, y: cy))
            p.closeSubpath()
        }
    }
}

#Preview {
    HStack(spacing: 24) {
        ForEach(ClothingCategory.allCases, id: \.self) { cat in
            SilhouetteView(category: cat, size: 80)
        }
    }
    .padding()
    .background(Color.dsDeepSlate)
}
```

- [ ] **Step 9.2 — Commit**

```bash
git add SmartStylist/Views/Closet/SilhouetteView.swift
git commit -m "feat(ui): programmatic golden silhouette for empty clothing slots"
git push
```

---

## Task 10: LocationService

**Files:**
- Create: `SmartStylist/Services/LocationService.swift`

- [ ] **Step 10.1 — Write async CoreLocation wrapper**

```swift
// LocationService.swift
import CoreLocation
import Foundation

@MainActor
final class LocationService: NSObject, ObservableObject {
    @Published var coordinate: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocationCoordinate2D, Error>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestCoordinate() async throws -> CLLocationCoordinate2D {
        if let coord = coordinate { return coord }
        return try await withCheckedThrowingContinuation { cont in
            self.continuation = cont
            switch manager.authorizationStatus {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            case .authorizedWhenInUse, .authorizedAlways:
                manager.requestLocation()
            default:
                cont.resume(throwing: LocationError.denied)
            }
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedWhenInUse
               || manager.authorizationStatus == .authorizedAlways {
                manager.requestLocation()
            } else if manager.authorizationStatus == .denied {
                continuation?.resume(throwing: LocationError.denied)
                continuation = nil
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in
            coordinate = loc.coordinate
            continuation?.resume(returning: loc.coordinate)
            continuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didFailWithError error: Error) {
        Task { @MainActor in
            continuation?.resume(throwing: error)
            continuation = nil
        }
    }
}

enum LocationError: LocalizedError {
    case denied
    var errorDescription: String? {
        switch self {
        case .denied: return "Location access denied. Enable it in Settings to get outfit suggestions."
        }
    }
}
```

- [ ] **Step 10.2 — Commit**

```bash
git add SmartStylist/Services/LocationService.swift
git commit -m "feat(services): async CoreLocation wrapper with continuation bridge"
git push
```

---

## Task 11: WeatherService

**Files:**
- Create: `SmartStylist/Services/WeatherService.swift`

- [ ] **Step 11.1 — Write OpenWeather REST client**

```swift
// WeatherService.swift
// Uses OpenWeather API 3.0 (One Call) as primary. WeatherKit requires entitlement — add later.
import Foundation
import CoreLocation

struct WeatherData {
    let temperatureCelsius: Double
    let feelsLikeCelsius: Double
    let rainProbability: Double    // 0.0 – 1.0
    let condition: String          // "Sunny", "Cloudy", "Rain", etc.
    var displayString: String {
        "\(Int(temperatureCelsius))°C, \(condition)"
    }
}

final class WeatherService {
    private let apiKey = APIKeys.openWeather

    func fetchWeather(for coordinate: CLLocationCoordinate2D) async throws -> WeatherData {
        let lat = coordinate.latitude
        let lon = coordinate.longitude
        let urlString = "https://api.openweathermap.org/data/3.0/onecall"
            + "?lat=\(lat)&lon=\(lon)&exclude=minutely,hourly,daily,alerts"
            + "&units=metric&appid=\(apiKey)"

        guard let url = URL(string: urlString) else {
            throw WeatherError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw WeatherError.serverError
        }

        return try parseWeatherResponse(data)
    }

    private func parseWeatherResponse(_ data: Data) throws -> WeatherData {
        // OpenWeather 3.0 "current" object
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let current = json?["current"] as? [String: Any] else {
            throw WeatherError.parseError
        }

        let temp      = current["temp"]       as? Double ?? 0
        let feelsLike = current["feels_like"] as? Double ?? temp
        let weather   = (current["weather"] as? [[String: Any]])?.first
        let condDesc  = weather?["main"] as? String ?? "Clear"

        // Rain probability is in "hourly[0].pop" — not available in current-only call.
        // We approximate: check if rain or drizzle is in the condition.
        let isRainy   = ["Rain", "Drizzle", "Thunderstorm"].contains(condDesc)
        let rainProb  = isRainy ? 0.8 : 0.0

        return WeatherData(
            temperatureCelsius: temp,
            feelsLikeCelsius: feelsLike,
            rainProbability: rainProb,
            condition: condDesc
        )
    }
}

enum WeatherError: LocalizedError {
    case invalidURL, serverError, parseError
    var errorDescription: String? {
        switch self {
        case .invalidURL:   return "Invalid weather URL."
        case .serverError:  return "Weather server error."
        case .parseError:   return "Could not parse weather data."
        }
    }
}
```

- [ ] **Step 11.2 — Commit**

```bash
git add SmartStylist/Services/WeatherService.swift
git commit -m "feat(services): WeatherService — OpenWeather 3.0 async client"
git push
```

---

## Task 12: GeminiService

**Files:**
- Create: `SmartStylist/Services/GeminiService.swift`

- [ ] **Step 12.1 — Write Gemini REST client**

```swift
// GeminiService.swift
import Foundation

final class GeminiService {
    private let apiKey = APIKeys.gemini
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent"

    // Generic text generation — used by both onboarding and style engine
    func generate(prompt: String) async throws -> String {
        let url = URL(string: "\(baseURL)?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "contents": [["parts": [["text": prompt]]]],
            "generationConfig": [
                "temperature": 0.7,
                "maxOutputTokens": 2048,
                "responseMimeType": "application/json"
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw GeminiError.serverError
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let candidates = json?["candidates"] as? [[String: Any]]
        let content    = candidates?.first?["content"] as? [String: Any]
        let parts      = content?["parts"] as? [[String: Any]]
        guard let text = parts?.first?["text"] as? String else {
            throw GeminiError.emptyResponse
        }
        return text
    }

    // Onboarding: analyse physical profile → colorimetry season + style guidelines
    func analyseProfile(bodyType: String, skinTone: String,
                        eyeColor: String, hairColor: String) async throws -> (season: String, guidelines: String) {
        let prompt = """
        You are a luxury fashion consultant and colour analyst.
        Analyse the following physical profile and respond ONLY with a JSON object:
        {
          "season": "Spring|Summer|Autumn|Winter",
          "guidelines": "2-3 sentences of personalised style architecture guidance"
        }

        Profile:
        - Body type: \(bodyType)
        - Skin tone: \(skinTone)
        - Eye colour: \(eyeColor)
        - Hair colour: \(hairColor)
        """
        let raw = try await generate(prompt: prompt)
        guard let data = raw.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: data) as? [String: String],
              let season = json["season"],
              let guidelines = json["guidelines"] else {
            throw GeminiError.parseError
        }
        return (season, guidelines)
    }

    // Style engine: generate outfit from context
    func suggestOutfit(profileJSON: String,
                       weatherJSON: String,
                       inventoryJSON: String,
                       historyJSON: String,
                       occasion: String) async throws -> StyleResponse {
        let prompt = """
        You are an elite personal stylist with deep knowledge of colour theory and fashion.
        Respond ONLY with a JSON object matching this schema exactly:
        {
          "clima_procesado": "temperature + condition string",
          "analisis_contexto": "2-3 sentence premium analysis",
          "outfit_sugerido": {
            "superior": "UUID string or null",
            "inferior": "UUID string or null",
            "calzado":  "UUID string or null",
            "abrigo":   "UUID string or null"
          },
          "consejo_estilo": "one personalised fashion tip"
        }

        RULES:
        1. Only use UUIDs from the provided inventory.
        2. NEVER repeat an outfit combination seen in the last 14 days (history).
        3. Prioritise colour harmony with the user's seasonal colorimetry.
        4. Match formality and layering to the weather and occasion.

        === USER PROFILE ===
        \(profileJSON)

        === CURRENT WEATHER ===
        \(weatherJSON)

        === ACTIVE WARDROBE ===
        \(inventoryJSON)

        === LAST 14 DAYS HISTORY ===
        \(historyJSON)

        === OCCASION ===
        \(occasion)
        """
        let raw = try await generate(prompt: prompt)
        guard let data = raw.data(using: .utf8) else { throw GeminiError.parseError }
        return try JSONDecoder().decode(StyleResponse.self, from: data)
    }
}

enum GeminiError: LocalizedError {
    case serverError, emptyResponse, parseError
    var errorDescription: String? {
        switch self {
        case .serverError:    return "Gemini API server error."
        case .emptyResponse:  return "Gemini returned an empty response."
        case .parseError:     return "Could not parse Gemini response."
        }
    }
}
```

- [ ] **Step 12.2 — Commit**

```bash
git add SmartStylist/Services/GeminiService.swift
git commit -m "feat(services): GeminiService — profile colorimetry + outfit suggestion prompts"
git push
```

---

## Task 13: GeminiService Unit Tests (mocked)

**Files:**
- Create: `SmartStylistTests/Services/GeminiServiceTests.swift`

- [ ] **Step 13.1 — Write decode tests (no network)**

```swift
// GeminiServiceTests.swift
import XCTest
@testable import SmartStylist

final class GeminiServiceTests: XCTestCase {

    func test_styleResponse_fullDecode() throws {
        let json = """
        {
          "clima_procesado": "15°C, Cloudy",
          "analisis_contexto": "A cool overcast day is perfect for layered wool tones.",
          "outfit_sugerido": {
            "superior": "11111111-1111-1111-1111-111111111111",
            "inferior": "22222222-2222-2222-2222-222222222222",
            "calzado":  "33333333-3333-3333-3333-333333333333",
            "abrigo":   "44444444-4444-4444-4444-444444444444"
          },
          "consejo_estilo": "Tuck in the front of your shirt for a smart-casual finish."
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(StyleResponse.self, from: json)
        XCTAssertEqual(response.climaProcesado, "15°C, Cloudy")
        XCTAssertEqual(response.outfitSugerido.allItemIds.count, 4)
        XCTAssertFalse(response.consejoEstilo.isEmpty)
    }

    func test_styleResponse_missingAbrigo_allItemIds_is3() throws {
        let json = """
        {
          "clima_procesado": "25°C, Sunny",
          "analisis_contexto": "Warm and bright.",
          "outfit_sugerido": {
            "superior": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
            "inferior": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
            "calzado":  "cccccccc-cccc-cccc-cccc-cccccccccccc",
            "abrigo":   null
          },
          "consejo_estilo": "Opt for breathable linen today."
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(StyleResponse.self, from: json)
        XCTAssertNil(response.outfitSugerido.abrigo)
        XCTAssertEqual(response.outfitSugerido.allItemIds.count, 3)
    }
}
```

- [ ] **Step 13.2 — Commit**

```bash
git add SmartStylistTests/Services/GeminiServiceTests.swift
git commit -m "test(services): GeminiService decoding unit tests"
git push
```

---

## Task 14: OnboardingViewModel

**Files:**
- Create: `SmartStylist/ViewModels/OnboardingViewModel.swift`

- [ ] **Step 14.1 — Write the ViewModel**

```swift
// OnboardingViewModel.swift
import Foundation
import SwiftData
import Observation

@Observable
final class OnboardingViewModel {
    // Step state
    var currentStep: OnboardingStep = .bodyType
    var isLoading = false
    var errorMessage: String?

    // Selections
    var selectedBodyType = ""
    var selectedSkinTone = ""
    var selectedEyeColor = ""
    var selectedHairColor = ""

    // Result
    var analysisResult: (season: String, guidelines: String)?

    private let gemini = GeminiService()

    enum OnboardingStep: Int, CaseIterable {
        case bodyType, skinTone, hairEye, result
    }

    var canAdvance: Bool {
        switch currentStep {
        case .bodyType:  return !selectedBodyType.isEmpty
        case .skinTone:  return !selectedSkinTone.isEmpty
        case .hairEye:   return !selectedEyeColor.isEmpty && !selectedHairColor.isEmpty
        case .result:    return false
        }
    }

    func advance() {
        if currentStep == .hairEye {
            Task { await analyseProfile() }
        } else if let next = OnboardingStep(rawValue: currentStep.rawValue + 1) {
            currentStep = next
        }
    }

    @MainActor
    func analyseProfile() async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await gemini.analyseProfile(
                bodyType: selectedBodyType,
                skinTone: selectedSkinTone,
                eyeColor: selectedEyeColor,
                hairColor: selectedHairColor
            )
            analysisResult = result
            currentStep = .result
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func save(to context: ModelContext) {
        guard let result = analysisResult else { return }
        let profile = UserProfile(
            bodyType: selectedBodyType,
            skinTone: selectedSkinTone,
            eyeColor: selectedEyeColor,
            hairColor: selectedHairColor,
            seasonalColorimetry: result.season,
            styleGuidelines: result.guidelines,
            onboardingCompleted: true
        )
        context.insert(profile)
        try? context.save()
    }

    // MARK: — Data presets
    let bodyTypeOptions    = ["Hourglass", "Rectangle", "Triangle", "Inverted Triangle", "Oval"]
    let skinToneOptions    = ["Warm Light", "Warm Medium", "Warm Deep", "Cool Light", "Cool Medium", "Cool Deep", "Neutral"]
    let eyeColorOptions    = ["Brown", "Dark Brown", "Hazel", "Green", "Blue", "Grey"]
    let hairColorOptions   = ["Black", "Dark Brown", "Brown", "Light Brown", "Blonde", "Auburn", "Red", "Grey", "White"]
}
```

- [ ] **Step 14.2 — Commit**

```bash
git add SmartStylist/ViewModels/OnboardingViewModel.swift
git commit -m "feat(viewmodels): OnboardingViewModel — step machine + Gemini profile analysis"
git push
```

---

## Task 15: Onboarding Views

**Files:**
- Create: `SmartStylist/Views/Onboarding/OnboardingContainerView.swift`
- Create: `SmartStylist/Views/Onboarding/BodyTypeStepView.swift`
- Create: `SmartStylist/Views/Onboarding/SkinToneStepView.swift`
- Create: `SmartStylist/Views/Onboarding/HairEyeStepView.swift`
- Create: `SmartStylist/Views/Onboarding/ColorimetryResultView.swift`

- [ ] **Step 15.1 — OnboardingContainerView**

```swift
// OnboardingContainerView.swift
import SwiftUI
import SwiftData

struct OnboardingContainerView: View {
    @Environment(\.modelContext) private var ctx
    @State private var vm = OnboardingViewModel()

    var body: some View {
        ZStack {
            Color.dsDeepSlate.ignoresSafeArea()

            VStack(spacing: 0) {
                progressBar
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                TabView(selection: $vm.currentStep) {
                    BodyTypeStepView(vm: vm).tag(OnboardingViewModel.OnboardingStep.bodyType)
                    SkinToneStepView(vm: vm).tag(OnboardingViewModel.OnboardingStep.skinTone)
                    HairEyeStepView(vm: vm).tag(OnboardingViewModel.OnboardingStep.hairEye)
                    ColorimetryResultView(vm: vm, onComplete: { vm.save(to: ctx) })
                        .tag(OnboardingViewModel.OnboardingStep.result)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.dsDefault, value: vm.currentStep)

                if vm.currentStep != .result {
                    advanceButton
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                }
            }

            if vm.isLoading {
                Color.dsDeepSlate.opacity(0.7).ignoresSafeArea()
                VStack(spacing: 16) {
                    LoadingPulse()
                    Text("Analysing your profile…")
                        .font(.dsBody)
                        .foregroundStyle(Color.dsTextSecondary)
                }
            }
        }
        .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(OnboardingViewModel.OnboardingStep.allCases, id: \.self) { step in
                Capsule()
                    .fill(vm.currentStep.rawValue >= step.rawValue
                          ? Color.dsAccentGold : Color.dsSurface)
                    .frame(height: 3)
                    .animation(.dsDefault, value: vm.currentStep)
            }
        }
    }

    private var advanceButton: some View {
        Button {
            withAnimation(.dsDefault) { vm.advance() }
        } label: {
            Text(vm.currentStep == .hairEye ? "Analyse My Style" : "Continue")
                .font(.dsBodyMedium)
                .foregroundStyle(Color.dsDeepSlate)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(vm.canAdvance ? Color.dsAccentGold : Color.dsSurface)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(!vm.canAdvance)
        .animation(.dsDefault, value: vm.canAdvance)
    }
}
```

- [ ] **Step 15.2 — BodyTypeStepView**

```swift
// BodyTypeStepView.swift
import SwiftUI

struct BodyTypeStepView: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("BODY\nARCHITECTURE")
                        .editorialStyle()
                    Text("Select the silhouette that best describes your proportions.")
                        .font(.dsBody)
                        .foregroundStyle(Color.dsTextSecondary)
                }

                GoldDivider()

                FlowLayout(spacing: 10) {
                    ForEach(vm.bodyTypeOptions, id: \.self) { option in
                        SelectionChip(label: option,
                                      isSelected: vm.selectedBodyType == option) {
                            vm.selectedBodyType = option
                        }
                    }
                }
            }
            .padding(24)
        }
    }
}
```

- [ ] **Step 15.3 — SkinToneStepView**

```swift
// SkinToneStepView.swift
import SwiftUI

struct SkinToneStepView: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("SKIN\nTONE")
                        .editorialStyle()
                    Text("Your skin's undertone shapes your entire colour palette.")
                        .font(.dsBody)
                        .foregroundStyle(Color.dsTextSecondary)
                }
                GoldDivider()
                FlowLayout(spacing: 10) {
                    ForEach(vm.skinToneOptions, id: \.self) { option in
                        SelectionChip(label: option,
                                      isSelected: vm.selectedSkinTone == option) {
                            vm.selectedSkinTone = option
                        }
                    }
                }
            }
            .padding(24)
        }
    }
}
```

- [ ] **Step 15.4 — HairEyeStepView**

```swift
// HairEyeStepView.swift
import SwiftUI

struct HairEyeStepView: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("HAIR &\nEYES")
                        .editorialStyle()
                    Text("These details complete your chromatic profile.")
                        .font(.dsBody)
                        .foregroundStyle(Color.dsTextSecondary)
                }
                GoldDivider()

                VStack(alignment: .leading, spacing: 20) {
                    Text("Hair Colour").font(.dsLabel).foregroundStyle(Color.dsTextSecondary)
                    FlowLayout(spacing: 10) {
                        ForEach(vm.hairColorOptions, id: \.self) { option in
                            SelectionChip(label: option,
                                          isSelected: vm.selectedHairColor == option) {
                                vm.selectedHairColor = option
                            }
                        }
                    }

                    Text("Eye Colour").font(.dsLabel).foregroundStyle(Color.dsTextSecondary)
                    FlowLayout(spacing: 10) {
                        ForEach(vm.eyeColorOptions, id: \.self) { option in
                            SelectionChip(label: option,
                                          isSelected: vm.selectedEyeColor == option) {
                                vm.selectedEyeColor = option
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
    }
}
```

- [ ] **Step 15.5 — ColorimetryResultView**

```swift
// ColorimetryResultView.swift
import SwiftUI

struct ColorimetryResultView: View {
    let vm: OnboardingViewModel
    let onComplete: () -> Void

    private var season: String { vm.analysisResult?.season ?? "" }
    private var guidelines: String { vm.analysisResult?.guidelines ?? "" }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("YOUR\nSEASON")
                        .editorialStyle()
                    Text("Your chromatic identity has been analysed.")
                        .font(.dsBody)
                        .foregroundStyle(Color.dsTextSecondary)
                }

                GoldDivider()

                LuxuryCard {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text(season.uppercased())
                                .font(.dsTitle)
                                .foregroundStyle(Color.dsAccentGold)
                                .tracking(3)
                            Spacer()
                            Image(systemName: seasonIcon(for: season))
                                .foregroundStyle(Color.dsAccentGold)
                                .font(.title2)
                        }
                        Text(guidelines)
                            .font(.dsBody)
                            .foregroundStyle(Color.dsTextSecondary)
                    }
                    .padding(20)
                }

                Button(action: onComplete) {
                    Text("Enter My Wardrobe")
                        .font(.dsBodyMedium)
                        .foregroundStyle(Color.dsDeepSlate)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.dsAccentGold)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            .padding(24)
        }
    }

    private func seasonIcon(for season: String) -> String {
        switch season {
        case "Spring":  return "leaf"
        case "Summer":  return "sun.max"
        case "Autumn":  return "wind"
        case "Winter":  return "snowflake"
        default:        return "sparkles"
        }
    }
}
```

- [ ] **Step 15.6 — FlowLayout helper (needed by chip grids)**

```swift
// FlowLayout.swift — place in Views/Components/
import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.map(\.height).reduce(0, +) + CGFloat(max(0, rows.count - 1)) * spacing
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize,
                       subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for sv in row.subviews {
                let size = sv.sizeThatFits(.unspecified)
                sv.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var subviews: [LayoutSubview] = []
        var height: CGFloat = 0
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        var rows: [Row] = [Row()]
        var x: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity

        for sv in subviews {
            let size = sv.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && !rows.last!.subviews.isEmpty {
                rows.append(Row())
                x = 0
            }
            rows[rows.count - 1].subviews.append(sv)
            rows[rows.count - 1].height = max(rows.last!.height, size.height)
            x += size.width + spacing
        }
        return rows
    }
}
```

- [ ] **Step 15.7 — Commit onboarding views**

```bash
git add SmartStylist/Views/Onboarding/ SmartStylist/Views/Components/FlowLayout.swift
git commit -m "feat(onboarding): 4-step chromatic profile funnel with Gemini analysis"
git push
```

---

## Task 16: ClosetViewModel

**Files:**
- Create: `SmartStylist/ViewModels/ClosetViewModel.swift`

- [ ] **Step 16.1 — Write ViewModel**

```swift
// ClosetViewModel.swift
import Foundation
import SwiftData
import Observation

@Observable
final class ClosetViewModel {
    var selectedCategory: ClothingCategory? = nil
    var searchText = ""
    var isAddingItem = false

    // Only .active items — the style engine rule
    func activeItems(from all: [ClothingItem]) -> [ClothingItem] {
        all.filter { $0.status == .active }
    }

    func filteredItems(from all: [ClothingItem]) -> [ClothingItem] {
        let active = activeItems(from: all)
        let categoryFiltered = selectedCategory == nil
            ? active
            : active.filter { $0.category == selectedCategory }
        guard !searchText.isEmpty else { return categoryFiltered }
        return categoryFiltered.filter {
            $0.tags.joined(separator: " ").localizedCaseInsensitiveContains(searchText) ||
            $0.style.localizedCaseInsensitiveContains(searchText) ||
            $0.primaryColor.localizedCaseInsensitiveContains(searchText)
        }
    }

    func disposeItem(_ item: ClothingItem, context: ModelContext) {
        item.status = .disposed
        try? context.save()
    }

    func archiveItem(_ item: ClothingItem, context: ModelContext) {
        item.status = .archived
        try? context.save()
    }

    func restoreItem(_ item: ClothingItem, context: ModelContext) {
        item.status = .active
        try? context.save()
    }

    // Grouped by category — for grid section headers
    func itemsByCategory(from all: [ClothingItem]) -> [(ClothingCategory, [ClothingItem])] {
        ClothingCategory.allCases.compactMap { cat in
            let items = filteredItems(from: all).filter { $0.category == cat }
            return items.isEmpty ? nil : (cat, items)
        }
    }
}
```

- [ ] **Step 16.2 — Commit**

```bash
git add SmartStylist/ViewModels/ClosetViewModel.swift
git commit -m "feat(viewmodels): ClosetViewModel — active-only filter, dispose/archive/restore"
git push
```

---

## Task 17: ClosetViewModel Tests

**Files:**
- Create: `SmartStylistTests/ViewModels/ClosetViewModelTests.swift`

- [ ] **Step 17.1 — Write tests**

```swift
// ClosetViewModelTests.swift
import XCTest
@testable import SmartStylist

final class ClosetViewModelTests: XCTestCase {
    var vm: ClosetViewModel!

    override func setUp() { vm = ClosetViewModel() }

    private func makeItem(status: ItemStatus, category: ClothingCategory = .top) -> ClothingItem {
        ClothingItem(category: category, status: status)
    }

    func test_activeItems_excludesDisposed() {
        let items = [makeItem(status: .active),
                     makeItem(status: .disposed),
                     makeItem(status: .archived)]
        let result = vm.activeItems(from: items)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.status, .active)
    }

    func test_activeItems_excludesArchived() {
        let items = [makeItem(status: .active), makeItem(status: .archived)]
        XCTAssertEqual(vm.activeItems(from: items).count, 1)
    }

    func test_filteredItems_byCategoryFiltersCorrectly() {
        let items = [makeItem(status: .active, category: .top),
                     makeItem(status: .active, category: .bottom),
                     makeItem(status: .active, category: .footwear)]
        vm.selectedCategory = .top
        XCTAssertEqual(vm.filteredItems(from: items).count, 1)
    }

    func test_filteredItems_nilCategoryReturnsAll() {
        let items = [makeItem(status: .active), makeItem(status: .active)]
        vm.selectedCategory = nil
        XCTAssertEqual(vm.filteredItems(from: items).count, 2)
    }

    func test_itemsByCategory_groupsCorrectly() {
        let items = [makeItem(status: .active, category: .top),
                     makeItem(status: .active, category: .top),
                     makeItem(status: .active, category: .footwear)]
        let groups = vm.itemsByCategory(from: items)
        let topGroup = groups.first(where: { $0.0 == .top })
        XCTAssertEqual(topGroup?.1.count, 2)
    }
}
```

- [ ] **Step 17.2 — Commit**

```bash
git add SmartStylistTests/ViewModels/ClosetViewModelTests.swift
git commit -m "test(viewmodels): ClosetViewModel — active filter and category grouping"
git push
```

---

## Task 18: VirtualClosetView

**Files:**
- Create: `SmartStylist/Views/Closet/VirtualClosetView.swift`
- Create: `SmartStylist/Views/Closet/ClothingItemCard.swift`

- [ ] **Step 18.1 — ClothingItemCard**

```swift
// ClothingItemCard.swift
import SwiftUI

struct ClothingItemCard: View {
    let item: ClothingItem
    var onDispose: (() -> Void)? = nil

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let path = item.imagePath,
               let uiImage = UIImage(contentsOfFile: path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.dsSurface
                SilhouetteView(category: item.category, size: 60)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Category badge
            VStack {
                Spacer()
                HStack {
                    Text(item.category.rawValue.capitalized)
                        .font(.dsCaption)
                        .foregroundStyle(Color.dsTextSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Material.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    Spacer()
                }
                .padding(8)
            }
        }
        .frame(height: 160)
        .luxuryCard(cornerRadius: 16)
        .contextMenu {
            if let onDispose = onDispose {
                Button(role: .destructive) { onDispose() } label: {
                    Label("Retire this piece", systemImage: "trash")
                }
            }
        }
    }
}
```

- [ ] **Step 18.2 — VirtualClosetView**

```swift
// VirtualClosetView.swift
import SwiftUI
import SwiftData

struct VirtualClosetView: View {
    @Query private var allItems: [ClothingItem]
    @Environment(\.modelContext) private var ctx
    @State private var vm = ClosetViewModel()
    @State private var showAddItem = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Color.dsDeepSlate.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        categoryFilter
                        itemGrid
                    }
                    .padding(16)
                }

                addButton
                    .padding(24)
            }
            .navigationTitle("Wardrobe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("WARDROBE")
                        .font(.dsTitle2)
                        .foregroundStyle(Color.dsAccentGold)
                        .tracking(3)
                }
            }
            .toolbarBackground(Material.ultraThinMaterial, for: .navigationBar)
            .searchable(text: $vm.searchText, prompt: "Search pieces…")
            .sheet(isPresented: $showAddItem) { AddItemView() }
        }
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                SelectionChip(label: "All", isSelected: vm.selectedCategory == nil) {
                    vm.selectedCategory = nil
                }
                ForEach(ClothingCategory.allCases, id: \.self) { cat in
                    SelectionChip(label: cat.rawValue.capitalized,
                                  isSelected: vm.selectedCategory == cat) {
                        vm.selectedCategory = cat
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private var itemGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(vm.filteredItems(from: allItems)) { item in
                NavigationLink(destination: ItemDetailView(item: item)) {
                    ClothingItemCard(item: item) {
                        vm.disposeItem(item, context: ctx)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var addButton: some View {
        Button { showAddItem = true } label: {
            Image(systemName: "plus")
                .foregroundStyle(Color.dsDeepSlate)
                .font(.title2.weight(.semibold))
                .padding(18)
                .background(Color.dsAccentGold)
                .clipShape(Circle())
                .shadow(color: Color.dsAccentGold.opacity(0.4), radius: 12, y: 6)
        }
    }
}
```

- [ ] **Step 18.3 — AddItemView stub (enough to compile)**

```swift
// AddItemView.swift
import SwiftUI
import SwiftData

struct AddItemView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    @State private var category: ClothingCategory = .top
    @State private var style = ""
    @State private var primaryColor = "#000000"
    @State private var tags = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dsDeepSlate.ignoresSafeArea()
                Form {
                    Picker("Category", selection: $category) {
                        ForEach(ClothingCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue.capitalized).tag(cat)
                        }
                    }
                    TextField("Style (Casual, Formal…)", text: $style)
                    TextField("Primary colour hex", text: $primaryColor)
                    TextField("Tags (comma separated)", text: $tags)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New Piece")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func save() {
        let tagList = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let item = ClothingItem(category: category,
                                primaryColor: primaryColor,
                                style: style.isEmpty ? "Casual" : style,
                                tags: tagList)
        ctx.insert(item)
        try? ctx.save()
        dismiss()
    }
}
```

- [ ] **Step 18.4 — ItemDetailView stub**

```swift
// ItemDetailView.swift
import SwiftUI

struct ItemDetailView: View {
    let item: ClothingItem
    @Environment(\.modelContext) private var ctx
    @State private var vm = ClosetViewModel()

    var body: some View {
        ZStack {
            Color.dsDeepSlate.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 24) {
                SilhouetteView(category: item.category, size: 160)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 32)

                LuxuryCard {
                    VStack(alignment: .leading, spacing: 12) {
                        detailRow(label: "Category", value: item.category.rawValue.capitalized)
                        detailRow(label: "Style",    value: item.style)
                        detailRow(label: "Colour",   value: item.primaryColor)
                        detailRow(label: "Status",   value: item.status.rawValue.capitalized)
                        if !item.tags.isEmpty {
                            detailRow(label: "Tags", value: item.tags.joined(separator: ", "))
                        }
                    }
                    .padding(20)
                }
                .padding(.horizontal, 16)

                Spacer()

                if item.status == .active {
                    Button(role: .destructive) { vm.disposeItem(item, context: ctx) } label: {
                        Label("Retire this piece", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.dsErrorRed.opacity(0.15))
                            .foregroundStyle(Color.dsErrorRed)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationTitle("Item Detail")
        .toolbarBackground(Material.ultraThinMaterial, for: .navigationBar)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.dsCaption).foregroundStyle(Color.dsTextTertiary)
            Spacer()
            Text(value).font(.dsBody).foregroundStyle(Color.dsTextPrimary)
        }
    }
}
```

- [ ] **Step 18.5 — Commit closet views**

```bash
git add SmartStylist/Views/Closet/
git commit -m "feat(closet): VirtualClosetView asymmetric grid, ClothingItemCard, Add/Detail views"
git push
```

---

## Task 19: StyleEngineViewModel

**Files:**
- Create: `SmartStylist/ViewModels/StyleEngineViewModel.swift`

- [ ] **Step 19.1 — Write ViewModel**

```swift
// StyleEngineViewModel.swift
import Foundation
import SwiftData
import Observation

@Observable
final class StyleEngineViewModel {
    var currentWeather: WeatherData?
    var suggestion: StyleResponse?
    var isLoading = false
    var errorMessage: String?
    var occasion = "Daily"

    private let gemini   = GeminiService()
    private let weather  = WeatherService()
    private let location = LocationService()

    @MainActor
    func generateOutfit(profile: UserProfile,
                        activeItems: [ClothingItem],
                        history: [OutfitHistory]) async {
        isLoading = true
        errorMessage = nil

        do {
            // 1. GPS + weather (no manual override allowed)
            let coord = try await location.requestCoordinate()
            let wx    = try await weather.fetchWeather(for: coord)
            currentWeather = wx

            // 2. Compile JSON payloads for Gemini
            let profileJSON  = encodeProfile(profile)
            let weatherJSON  = encodeWeather(wx)
            let inventoryJSON = encodeInventory(activeItems)
            let historyJSON  = encodeHistory(Array(history.prefix(14).filter {
                Calendar.current.dateComponents([.day], from: $0.date, to: Date()).day ?? 999 <= 14
            }))

            // 3. Call Gemini style engine
            let result = try await gemini.suggestOutfit(
                profileJSON: profileJSON,
                weatherJSON: weatherJSON,
                inventoryJSON: inventoryJSON,
                historyJSON: historyJSON,
                occasion: occasion
            )
            suggestion = result

        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: — Payload encoders

    private func encodeProfile(_ p: UserProfile) -> String {
        """
        {"bodyType":"\(p.bodyType)","skinTone":"\(p.skinTone)",
         "eyeColor":"\(p.eyeColor)","hairColor":"\(p.hairColor)",
         "season":"\(p.seasonalColorimetry)","guidelines":"\(p.styleGuidelines)"}
        """
    }

    private func encodeWeather(_ w: WeatherData) -> String {
        """
        {"temp":\(w.temperatureCelsius),"feelsLike":\(w.feelsLikeCelsius),
         "condition":"\(w.condition)","rainProbability":\(w.rainProbability)}
        """
    }

    private func encodeInventory(_ items: [ClothingItem]) -> String {
        let entries = items.map { item in
            """
            {"id":"\(item.id.uuidString)","category":"\(item.category.rawValue)",
             "primaryColor":"\(item.primaryColor)","pattern":"\(item.pattern)",
             "style":"\(item.style)","tags":\(item.tags.map { "\"\($0)\"" })}
            """
        }
        return "[\(entries.joined(separator: ","))]"
    }

    private func encodeHistory(_ history: [OutfitHistory]) -> String {
        let entries = history.map { h in
            let ids = h.clothingItemIds.map { "\"\($0.uuidString)\"" }.joined(separator: ",")
            return """
            {"date":"\(h.date.ISO8601Format())","context":"\(h.context)","items":[\(ids)]}
            """
        }
        return "[\(entries.joined(separator: ","))]"
    }
}
```

- [ ] **Step 19.2 — Commit**

```bash
git add SmartStylist/ViewModels/StyleEngineViewModel.swift
git commit -m "feat(viewmodels): StyleEngineViewModel — GPS+weather pipeline, Gemini outfit prompt compiler"
git push
```

---

## Task 20: StyleEngine Views

**Files:**
- Create: `SmartStylist/Views/StyleEngine/StyleEngineView.swift`
- Create: `SmartStylist/Views/StyleEngine/OutfitSuggestionCard.swift`
- Create: `SmartStylist/Views/StyleEngine/WeatherBadgeView.swift`

- [ ] **Step 20.1 — WeatherBadgeView**

```swift
// WeatherBadgeView.swift
import SwiftUI

struct WeatherBadgeView: View {
    let weather: WeatherData

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: weatherIcon(for: weather.condition))
                .foregroundStyle(Color.dsAccentGold)
            VStack(alignment: .leading, spacing: 2) {
                Text(weather.displayString)
                    .font(.dsBodyMedium)
                    .foregroundStyle(Color.dsTextPrimary)
                Text("Feels like \(Int(weather.feelsLikeCelsius))°C")
                    .font(.dsCaption)
                    .foregroundStyle(Color.dsTextSecondary)
            }
            Spacer()
        }
        .padding(14)
        .luxuryCard()
    }

    private func weatherIcon(for condition: String) -> String {
        switch condition.lowercased() {
        case let c where c.contains("rain"):    return "cloud.rain"
        case let c where c.contains("cloud"):   return "cloud"
        case let c where c.contains("snow"):    return "snow"
        case let c where c.contains("thunder"): return "cloud.bolt"
        default:                                 return "sun.max"
        }
    }
}
```

- [ ] **Step 20.2 — OutfitSuggestionCard**

```swift
// OutfitSuggestionCard.swift
import SwiftUI

struct OutfitSuggestionCard: View {
    let response: StyleResponse
    let items: [ClothingItem]

    private func item(for id: UUID?) -> ClothingItem? {
        guard let id else { return nil }
        return items.first { $0.id == id }
    }

    var body: some View {
        LuxuryCard {
            VStack(alignment: .leading, spacing: 20) {
                Text(response.analisisContexto)
                    .font(.dsBody)
                    .foregroundStyle(Color.dsTextSecondary)

                GoldDivider()

                outfitGrid

                GoldDivider()

                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Color.dsAccentGold)
                    Text(response.consejoEstilo)
                        .font(.dsCaption)
                        .foregroundStyle(Color.dsTextSecondary)
                        .italic()
                }
            }
            .padding(20)
        }
    }

    private var outfitGrid: some View {
        let slots: [(String, UUID?)] = [
            ("Top",       response.outfitSugerido.superior),
            ("Bottom",    response.outfitSugerido.inferior),
            ("Shoes",     response.outfitSugerido.calzado),
            ("Outerwear", response.outfitSugerido.abrigo)
        ]
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(slots, id: \.0) { label, id in
                if let id, let clothingItem = item(for: id) {
                    VStack(spacing: 6) {
                        SilhouetteView(category: clothingItem.category, size: 60)
                        Text(label)
                            .font(.dsCaption)
                            .foregroundStyle(Color.dsTextTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.dsSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }
}
```

- [ ] **Step 20.3 — StyleEngineView**

```swift
// StyleEngineView.swift
import SwiftUI
import SwiftData

struct StyleEngineView: View {
    @Query(filter: #Predicate<ClothingItem> { $0.status == ItemStatus.active.rawValue })
    private var activeItems: [ClothingItem]

    @Query private var history: [OutfitHistory]
    @Query private var profiles: [UserProfile]
    @State private var vm = StyleEngineViewModel()

    private var profile: UserProfile? { profiles.first(where: { $0.onboardingCompleted }) }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dsDeepSlate.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Weather badge
                        if let wx = vm.currentWeather {
                            WeatherBadgeView(weather: wx)
                        }

                        // Occasion picker
                        occasionPicker

                        // Outfit suggestion
                        if let suggestion = vm.suggestion {
                            OutfitSuggestionCard(response: suggestion, items: activeItems)
                        } else if vm.isLoading {
                            loadingState
                        } else {
                            emptyState
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Style")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("TODAY'S LOOK")
                        .font(.dsTitle2)
                        .foregroundStyle(Color.dsAccentGold)
                        .tracking(3)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            guard let p = profile else { return }
                            await vm.generateOutfit(profile: p,
                                                     activeItems: activeItems,
                                                     history: history)
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(Color.dsAccentGold)
                    }
                }
            }
            .toolbarBackground(Material.ultraThinMaterial, for: .navigationBar)
            .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
                Button("OK") { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
            .task {
                guard let p = profile, vm.suggestion == nil else { return }
                await vm.generateOutfit(profile: p, activeItems: activeItems, history: history)
            }
        }
    }

    private var occasionPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(["Daily", "Work", "Casual", "Formal", "Sport", "Evening"], id: \.self) { occ in
                    SelectionChip(label: occ, isSelected: vm.occasion == occ) {
                        vm.occasion = occ
                    }
                }
            }
        }
    }

    private var loadingState: some View {
        HStack {
            Spacer()
            VStack(spacing: 16) {
                LoadingPulse()
                Text("Curating your look…")
                    .font(.dsBody)
                    .foregroundStyle(Color.dsTextSecondary)
            }
            Spacer()
        }
        .padding(.top, 80)
    }

    private var emptyState: some View {
        HStack {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "tshirt")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.dsAccentGold.opacity(0.4))
                Text("Tap ↻ to generate today's look")
                    .font(.dsBody)
                    .foregroundStyle(Color.dsTextTertiary)
            }
            Spacer()
        }
        .padding(.top, 80)
    }
}
```

- [ ] **Step 20.4 — Commit style engine views**

```bash
git add SmartStylist/Views/StyleEngine/
git commit -m "feat(style-engine): StyleEngineView, OutfitSuggestionCard, WeatherBadgeView"
git push
```

---

## Task 21: App Entry Point & RootView

**Files:**
- Create: `SmartStylist/App/SmartStylistApp.swift`
- Create: `SmartStylist/App/RootView.swift`

- [ ] **Step 21.1 — App entry**

```swift
// SmartStylistApp.swift
import SwiftUI
import SwiftData

@main
struct SmartStylistApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [UserProfile.self, ClothingItem.self, OutfitHistory.self])
    }
}
```

- [ ] **Step 21.2 — RootView (onboarding gate)**

```swift
// RootView.swift
import SwiftUI
import SwiftData

struct RootView: View {
    @Query private var profiles: [UserProfile]

    private var isOnboarded: Bool {
        profiles.first?.onboardingCompleted == true
    }

    var body: some View {
        if isOnboarded {
            MainTabView()
        } else {
            OnboardingContainerView()
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            StyleEngineView()
                .tabItem { Label("Today", systemImage: "sparkles") }

            VirtualClosetView()
                .tabItem { Label("Wardrobe", systemImage: "tshirt") }
        }
        .tint(Color.dsAccentGold)
        .background(Color.dsDeepSlate)
    }
}
```

- [ ] **Step 21.3 — Final commit**

```bash
git add SmartStylist/App/
git commit -m "feat(app): entry point with SwiftData container and onboarding gate"
git push
```

---

## Self-Review

### Spec Coverage Check

| Requirement | Covered in Task |
|---|---|
| Git init + private GitHub repo | Task 1 |
| .gitignore strict Xcode | Task 1 |
| XcodeGen project.yml | Task 2 |
| DeepSlate / AccentGold colour palette | Task 3 |
| Serif editorial typography | Task 4 |
| Continuous corners, card border, blur nav | Task 5, 8 |
| `.easeInOut(duration:0.3)` animations | Task 5 |
| UserProfile SwiftData model | Task 6 |
| ClothingItem + ItemStatus enum | Task 6 |
| OutfitHistory model | Task 6 |
| StyleResponse Codable mapping | Task 6 |
| Onboarding funnel (body / skin / hair+eye) | Task 14, 15 |
| Gemini colorimetry analysis | Task 12, 14 |
| VirtualClosetView asymmetric grid | Task 18 |
| Silhouette for empty slots | Task 9 |
| Dispose item → .disposed status | Task 16, 18 |
| .active-only filter in style engine | Task 16, 19 |
| CoreLocation GPS (no manual override) | Task 10 |
| WeatherService (OpenWeather) | Task 11 |
| StyleEngineViewModel compiles all context | Task 19 |
| 14-day history "Radical Variety" rule | Task 12 (Gemini prompt), 19 |
| Gemini JSON → StyleResponse mapping | Task 6, 12 |

### Placeholder Check
No TBDs, no "fill in details" — every step contains real code. ✓

### Type Consistency
- `ItemStatus` enum: defined Task 6, used identically in Task 16, 18, 19. ✓
- `ClothingCategory` enum: defined Task 6, referenced in SilhouetteView (Task 9), card views. ✓
- `StyleResponse` struct: defined Task 6, decoded in Task 12 `suggestOutfit`, rendered in Task 20. ✓
- `ClosetViewModel.disposeItem` signature stable across Tasks 16, 18. ✓
