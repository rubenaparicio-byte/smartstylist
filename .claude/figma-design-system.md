# SmartStylist — Figma ↔ Code Design System Rules

Reference for translating Figma designs into SmartStylist SwiftUI code and back.
All rules are derived from the live codebase in `SmartStylist/DesignSystem/` and `SmartStylist/Views/Components/`.

---

## 1. Design Tokens

### Color Palette

All tokens are Swift extensions on `Color` with a `ds` prefix.
Source: `SmartStylist/DesignSystem/DS+Colors.swift`

| Token | Hex | Role |
|---|---|---|
| `Color.dsBackground` | `#1C1C1E` | Full-screen background (every view) |
| `Color.dsCardBackground` | `#2C2C2E` | Card/surface background (tab bar, cards) |
| `Color.dsSurface` | `#3A3A3C` | Inner surface, input fields, chips (unselected) |
| `Color.dsAccentPrimary` | `#D4AF37` | Primary interactive — CTA fills, tints, icons, strokes |
| `Color.dsAccentSecondary` | `#E9C46A` | Secondary gold (lighter highlights) |
| `Color.dsErrorRed` | `#E63946` | Destructive actions, danger zone, error states |
| `Color.dsTextPrimary` | `white` | Headings, values, primary labels |
| `Color.dsTextSecondary` | `white @ 60%` | Body text, subtitles, descriptions |
| `Color.dsTextTertiary` | `white @ 35%` | Section labels, captions, placeholder text |

**Hex initialiser is built-in** — `Color(hex: "#D4AF37")` works anywhere.

**In Figma:** create a matching library with these exact fill styles. Gold borders are always the token value at reduced opacity (see Shapes section).

---

### Typography

Source: `SmartStylist/DesignSystem/DS+Typography.swift`

| Token | SwiftUI spec | Role |
|---|---|---|
| `Font.dsLargeTitle` | `.largeTitle` serif regular | Editorial page titles |
| `Font.dsTitle` | `.title` serif regular | Section headings |
| `Font.dsTitle2` | `.title2` serif light | Navigation bar titles, card headings |
| `Font.dsBody` | `.body` default light | Paragraph content, descriptions |
| `Font.dsBodyMedium` | `.body` default regular | Button labels, important body |
| `Font.dsCaption` | `.caption` default light | Section labels (ALL CAPS + tracking), metadata |
| `Font.dsLabel` | `.footnote` default medium | Chips, filter labels, small interactive text |

**Letter-spacing conventions (`.tracking()`):**

- `2.5 pt` — `editorialStyle()` modifier (large title headings, onboarding step titles)
- `3 pt` — navigation bar titles (`dsTitle2` in toolbars)
- `2 pt` — section headers in caps (captions used as section titles)
- `0` — body text, chip labels, everything else

**`editorialStyle()` is the editorial heading modifier:**
```swift
Text("SKIN\nTONE")
    .editorialStyle()
// Expands to: .dsLargeTitle + .tracking(2.5) + .foregroundStyle(.dsTextPrimary)
```
Use for multi-line ALL-CAPS page titles in onboarding and major sections.

**In Figma:** serif font stack maps to Georgia / Didot / similar. System sans-serif for body/labels. Tracking values above must match exactly — these create the luxury editorial feel.

---

### Shape & Corner Radius

Source: `SmartStylist/DesignSystem/DS+Shapes.swift`

| Usage | Corner radius | Style |
|---|---|---|
| Cards (`LuxuryCard`, `WeatherBadgeView`) | `20 pt` (default) | `.continuous` |
| Buttons (primary CTA, action rows) | `14 pt` | `.continuous` |
| Item grid cards (`ClothingItemCard`) | `16 pt` | `.continuous` |
| Search field, filter panel | `12 pt` | `.continuous` |
| Context badge, archived badge | `8 pt` / `4 pt` | `.continuous` |
| Pills / chips (`SelectionChip`) | `24 pt` (fully rounded) | `.continuous` |
| FAB (add button) | circle | — |
| Colour swatches | circle | — |
| Progress bar segments (onboarding) | `Capsule()` | — |

`.continuous` = Apple's super-ellipse (squircle) — always use `style: .continuous` on `RoundedRectangle`.

**Gold border rule** — all cards, inputs, and chips carry a `0.5 pt` gold stroke at reduced opacity:
```swift
.overlay(
    RoundedRectangle(cornerRadius: r, style: .continuous)
        .stroke(Color.dsAccentPrimary.opacity(0.15), lineWidth: 0.5)  // cards
        // 0.12 inactive, 0.3 hover/focused, 0.55 active input field
)
```

---

### Spacing Grid

Based on observed padding values across all views:

| Value | Usage |
|---|---|
| `8 pt` | Icon-text gap, tight internal padding, small chip vertical padding |
| `10 pt` | Chip vertical padding, filter panel internal rows |
| `12 pt` | Grid spacing, internal card sub-spacing, swatch gap |
| `14 pt` | Card internal horizontal padding, badge padding, filter chip horizontal |
| `16 pt` | Main content horizontal padding, primary screen padding |
| `18 pt` | Card content padding (used in `ProfileSettingsView` sections) |
| `20 pt` | Card content padding (`OutfitSuggestionCard`), major section spacing |
| `24 pt` | FAB margin, onboarding horizontal padding, action section bottom padding |
| `28 pt` | `LuxuryLoadingView` spinner-to-label gap |
| `32 pt` | Onboarding `VStack` main spacing, scroll bottom padding |

---

### Animations

Source: `SmartStylist/DesignSystem/DS+Animations.swift`

| Token | Spec | Use case |
|---|---|---|
| `Animation.dsDefault` | `easeInOut(0.3s)` | State transitions, filter shows/hides, chip selection |
| `Animation.dsFast` | `easeInOut(0.18s)` | Micro-interactions (icon colour changes) |
| `Animation.dsSpring` | `spring(response: 0.4, dampingFraction: 0.75)` | Save/confirmation actions |

Custom durations used directly:
- Spinner: `.linear(2.8s).repeatForever` (outer arc) / `.easeInOut(1.3s).repeatForever` (pulse)
- Grid filter key: `.easeInOut(0.22s)` (slightly faster than default)
- Message cycling: `2.2s` sleep between messages

---

## 2. Component Library

Source: `SmartStylist/Views/Components/`

### `LuxuryCard<Content>`

Generic card container. Apply via modifier `.luxuryCard(cornerRadius:)` or wrap in `LuxuryCard { ... }`.

```swift
// Modifier usage (preferred for complex views):
SomeView()
    .padding(20)
    .luxuryCard()

// View wrapper:
LuxuryCard(cornerRadius: 16) {
    content
}
```

Renders: `dsCardBackground` background + continuous corner clip + `dsAccentPrimary @ 0.15` stroke at `0.5 pt`.

**In Figma:** dark fill `#2C2C2E`, stroke `#D4AF37` at 15% opacity, 0.5 width, matching radius.

---

### `SelectionChip`

Pill-shaped toggle chip. Used for category filters, event context, style/pattern selectors.

```swift
SelectionChip(
    label: "Casual",
    isSelected: vm.selected == "Casual",
    swatchColor: Color(hex: "#F2D8C2")  // optional color dot
) { vm.selected = "Casual" }
```

| State | Background | Text | Border |
|---|---|---|---|
| Unselected | `dsSurface` | `dsTextSecondary` | `dsAccentPrimary @ 30%` |
| Selected | `dsAccentPrimary` | `dsBackground` | none |

Sizes: `.dsLabel` font, `18 pt` H-padding (no swatch) / `14 pt` (with swatch), `10 pt` V-padding, `24 pt` radius.

**In Figma:** two variants — Default and Selected. Auto-layout pill shape.

---

### `AccentDivider`

Horizontal rule. `0.5 pt` height, `dsAccentPrimary @ 25%` fill. Full-width by default.

```swift
AccentDivider()
```

**In Figma:** line stroke `#D4AF37` at 25%, 0.5 height.

---

### `LuxuryLoadingView`

Full-width loading state for AI generation. Multi-ring gold spinner + cycling localized messages.

```swift
LuxuryLoadingView()
```

Structure: `72 pt` outer arc (AngularGradient, gold) + `50 pt` static ring + `30 pt` pulsing inner circle + `5 pt` center dot. Vertical padding `80 pt` top/bottom.

**In Figma:** use as a full-width overlay/section. Center-aligned. Not interactive.

---

### `LuxuryErrorView`

Error display for `StyleEngineError` cases. Icon badge + title/subtitle + optional retry/settings button.

```swift
LuxuryErrorView(error: .aiUnavailable("msg")) {
    // retry action
}
```

Icon badge: `80 pt` circle, `dsSurface` fill, `dsAccentPrimary @ 22%` stroke, SF Symbol at `28 pt` light weight.
Primary button: `dsAccentPrimary` fill, `dsBackground` text, `14 pt` radius, gold shadow.
Secondary button: `dsSurface` fill, `dsAccentPrimary` text, `dsAccentPrimary @ 30%` stroke.

---

### `SilhouetteView`

Canvas-drawn clothing silhouette placeholder. One per `ClothingCategory` using procedural `Path` geometry. No external images.

```swift
SilhouetteView(category: .top, size: 60)
```

Stroke: `dsAccentPrimary @ 35%`, `1 pt` line width. Scales proportionally via the `size` parameter.

**In Figma:** can substitute with actual outlined clothing icons at same gold opacity.

---

### `FlowLayout`

SwiftUI `Layout` protocol implementation. Wraps children into rows at available width.

```swift
FlowLayout(spacing: 10) {
    ForEach(options, id: \.self) { SelectionChip(...) }
}
```

Default spacing `8 pt`. Used for chip groups in onboarding steps.

---

## 3. Screen Patterns

### Background pattern (all screens)

Every screen root wraps content in:
```swift
ZStack {
    Color.dsBackground.ignoresSafeArea()
    // content
}
```

### Navigation bar pattern

All `NavigationStack` screens use:
```swift
.toolbar {
    ToolbarItem(placement: .principal) {
        Text("TITLE")
            .font(.dsTitle2)
            .foregroundStyle(Color.dsAccentPrimary)
            .tracking(3)
    }
}
.toolbarBackground(Material.ultraThinMaterial, for: .navigationBar)
```

Navigation title display mode: `.inline`. Actual `navigationTitle` string is ignored visually — the principal toolbar item is the visible title.

**In Figma:** nav bar = ultra-thin material blur overlay + gold serif title centered.

### Primary CTA button

```swift
Button { action } label: {
    Text("Label")
        .font(.dsBodyMedium)
        .foregroundStyle(Color.dsBackground)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.dsAccentPrimary)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.dsAccentPrimary.opacity(0.35), radius: 12, y: 6)
}
```

**In Figma:** full-width, 48 pt tall (16 pt V-padding × 2 + 16 pt body line height). Gold fill. Deep slate text. 14 pt continuous radius. Gold shadow: 0.35 opacity, 12 blur, 6 Y-offset.

### Secondary / outlined button

```swift
.foregroundStyle(Color.dsAccentPrimary)
.overlay(
    RoundedRectangle(cornerRadius: 12, style: .continuous)
        .stroke(Color.dsAccentPrimary, lineWidth: 1)
)
```

**In Figma:** transparent fill, 1 pt gold stroke, 12 pt radius.

### Destructive button

```swift
.foregroundStyle(Color.dsErrorRed)
.background(Color.dsErrorRed.opacity(0.08))
.overlay(RoundedRectangle(...).stroke(Color.dsErrorRed.opacity(0.45), lineWidth: 0.5))
```

### Section header label (ALL CAPS)

```swift
Text("SECTION TITLE")
    .font(.dsCaption)
    .foregroundStyle(Color.dsTextTertiary)
    .tracking(2)
```

**In Figma:** caption size, 35% white, 2 pt tracking. Always uppercase in the string literal (no `textCase`).

### Glassmorphism panel

```swift
.background(Material.ultraThinMaterial)
.clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
.overlay(
    RoundedRectangle(cornerRadius: 14, style: .continuous)
        .strokeBorder(Color.dsAccentPrimary.opacity(0.18), lineWidth: 0.5)
)
```

Used for: filter panel, category badge overlays. Not for main cards (those use `dsCardBackground` solid).

---

## 4. Frameworks & Build System

| Layer | Technology |
|---|---|
| UI framework | SwiftUI (iOS 17+) |
| Data persistence | SwiftData (`@Model`, `@Query`, `ModelContainer`) |
| State | `@Observable` (Swift 5.9 Observation framework) |
| Build system | XcodeGen (`project.yml`) + Xcode |
| Asset pipeline | Xcode asset catalogs (`Assets.xcassets`) |
| Styling | Swift extensions + ViewModifiers (no CSS) |
| Localization | `.strings` files, `String(localized:)`, `Strings` enum |

No web technologies, no CSS, no external styling libraries.

---

## 5. Asset Management

- **App icon:** `SmartStylist/Assets.xcassets/AppIcon.appiconset/AppIcon.png` — single 1024×1024 universal PNG (Xcode 26+ format, no per-size variants)
- **Clothing item photos:** stored on-device at file paths in `ClothingItem.imagePath`. Loaded via `UIImage(contentsOfFile:)`. No remote URLs.
- **Clothing silhouettes:** procedural Canvas drawing in `SilhouetteView.swift` — **no image assets**
- **Icons:** SF Symbols exclusively (`Image(systemName:)`)
- **No CDN, no remote images**

When adding image assets from Figma:
1. Export as 1× PNG (iOS renders @2x/@3x automatically via asset catalogs)
2. Use `Image("AssetName")` where the asset name matches the xcassets entry
3. All non-icon graphics should go in `Assets.xcassets`; never bundle loose images

---

## 6. Icon System

**All icons are SF Symbols.** There is no custom icon set.

Common symbols used in SmartStylist:

| Screen | Symbol |
|---|---|
| Style Engine tab | `sparkles` |
| Wardrobe tab | `tshirt` |
| Insights tab | `chart.pie` |
| Profile tab | `person.crop.circle` |
| Refresh/Generate | `arrow.clockwise` |
| Search | `magnifyingglass` |
| Filter | `line.3.horizontal.decrease.circle` / `.fill` |
| Save/Confirm | `checkmark.circle` / `.fill` |
| Add | `plus` |
| Archive | `archivebox` |
| Restore | `arrow.uturn.up` |
| Delete | `trash` |
| Umbrella warning | `umbrella.fill` |
| Offline | `wifi.slash` |
| AI unavailable | `wifi.exclamationmark` |
| Location denied | `location.slash` |
| Empty/magic | `wand.and.stars` |

When a Figma design uses a custom icon shape: find the closest SF Symbol first. Only add a custom SVG if no SF Symbol matches semantically.

Icon sizing convention:
- Tab bar: default SF Symbol tab size (system-managed)
- Toolbar buttons: `.font(.title3)` or `.font(.system(size: N, weight: .light))`
- Inline icons in text: `.font(.caption)` or `.font(.subheadline)`
- Standalone icon badges: `.font(.system(size: 28, weight: .light))`
- Error/empty state large icons: `.font(.system(size: 40–44))` at `.thin` weight

---

## 7. Localization

**All user-facing strings go through the `Strings` enum** in `SmartStylist/Localization/Strings.swift`.

```swift
// In views:
Text(Strings.styleNavTitle)

// For LocalizedStringKey (e.g. in LuxuryLoadingView):
private let messages: [LocalizedStringKey] = ["loading.analysing_wardrobe", ...]
```

Key naming convention: `domain.noun.descriptor` e.g.:
- `style.nav.title`, `wardrobe.filter.all`, `error.ai.title`, `filter.no_results.subtitle`

Supported locales: `en` (development language), `es`.

When implementing a Figma design:
1. Add the key to `Strings.swift` as a new `static var`
2. Add the English string to `SmartStylist/en.lproj/Localizable.strings`
3. Add the Spanish string to `SmartStylist/es.lproj/Localizable.strings`
4. Reference via `Strings.yourNewKey` in the view

**Never hardcode display strings in views** (exception: internal data-model values like `"ARCHIVED"` category badge which is not localized by intent).

---

## 8. MVVM Pattern for New Screens

```
Views/FeatureName/        ← Pure SwiftUI, no business logic
  FeatureView.swift       ← Root screen, owns @State var vm = FeatureViewModel()
  SubcomponentView.swift  ← Receives data, emits callbacks

ViewModels/
  FeatureViewModel.swift  ← @Observable class, owns state + coordinates services

Services/
  FeatureService.swift    ← pure async functions, no SwiftUI imports
```

ViewModel is `@Observable` (not `ObservableObject`). Views use `@State var vm = VM()`.
SwiftData queries live in views (`@Query`), not ViewModels — pass results down as parameters.

---

## 9. Figma → Code Translation Checklist

When implementing a screen from Figma:

- [ ] Background is `Color.dsBackground.ignoresSafeArea()` wrapping everything
- [ ] Navigation title uses the `principal` toolbar item pattern with `.dsTitle2 + .dsAccentPrimary + tracking(3)`
- [ ] `.toolbarBackground(Material.ultraThinMaterial, for: .navigationBar)` applied
- [ ] Cards use `.luxuryCard(cornerRadius:)` modifier or `LuxuryCard` wrapper
- [ ] All border strokes are `dsAccentPrimary` at 0.12–0.55 opacity, 0.5 pt weight
- [ ] Shared components from `Views/Components/` are used before writing new ones
- [ ] All text uses `ds` font tokens (no `.font(.system(...))` inline except for icon sizing)
- [ ] ALL-CAPS section headers use `.dsCaption + .dsTextTertiary + .tracking(2)`
- [ ] Primary CTA matches the established button pattern (gold fill, 16 pt V-padding, 14 pt radius, gold shadow)
- [ ] Animations use `dsDefault`/`dsFast`/`dsSpring` tokens (not custom values)
- [ ] Icons use SF Symbols only
- [ ] All strings go through the `Strings` enum and `.strings` files
- [ ] New screens created in the appropriate `Views/FeatureName/` subdirectory
- [ ] ViewModel created as `@Observable` class in `ViewModels/`

---

## 10. Spacing Quick Reference

```
Chip/badge internal:     H:14-18 / V:8-10
Card internal padding:   18-20
Screen edge padding:     16
Section gap:             20
Major section gap:       28-32
Grid item gap:           12
Horizontal chip gap:     8
```
