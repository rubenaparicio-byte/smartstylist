import Foundation

// ── Strings ───────────────────────────────────────────────────────────────────
// Central namespace for all user-facing strings in SmartStylist.
// Each computed var calls String(localized:) so the bundle lookup happens at
// call time, picking the correct language from Localizable.strings.
//
// Supported locales: en (development), es
//
// Usage in views:   Text(Strings.commonRetry)
// Usage in VM:      Strings.eventDaily  (already resolved String)
//
// For new strings: add the var here, add the key to both .strings files.

enum Strings {

    // MARK: — Common actions
    static var commonRetry:        String { String(localized: "common.retry") }
    static var commonCancel:       String { String(localized: "common.cancel") }
    static var commonError:        String { String(localized: "common.error") }
    static var commonOpenSettings: String { String(localized: "common.open_settings") }

    // MARK: — Loading messages (also referenced as LocalizedStringKey in LuxuryLoadingView)
    static var loadingAnalysingWardrobe: String { String(localized: "loading.analysing_wardrobe") }
    static var loadingReadingColour:     String { String(localized: "loading.reading_colour") }
    static var loadingCuratingLook:      String { String(localized: "loading.curating_look") }
    static var loadingAlmostReady:       String { String(localized: "loading.almost_ready") }

    // MARK: — Onboarding
    static var onboardingAnalyseMyStyle:   String { String(localized: "onboarding.cta.analyse") }
    static var onboardingContinue:         String { String(localized: "onboarding.cta.continue") }
    static var onboardingAnalysingProfile: String { String(localized: "onboarding.loading.analysing") }

    // MARK: — Style Engine
    static var styleNavTitle:         String { String(localized: "style.nav.title") }
    static var styleEventContext:     String { String(localized: "style.section.event_context") }
    static var styleOutfitRegistered: String { String(localized: "style.outfit.registered") }
    static var styleOutfitSave:       String { String(localized: "style.outfit.save") }
    static var styleEmptyTitle:       String { String(localized: "style.empty.title") }
    static var styleEmptySubtitle:    String { String(localized: "style.empty.subtitle") }
    static var styleOfflineMode:      String { String(localized: "style.offline.mode") }

    // MARK: — Event contexts
    static var eventDaily:         String { String(localized: "event.daily") }
    static var eventWork:          String { String(localized: "event.work") }
    static var eventEveningDate:   String { String(localized: "event.evening_date") }
    static var eventGym:           String { String(localized: "event.gym") }
    static var eventCasualWeekend: String { String(localized: "event.casual_weekend") }
    static var eventFormal:        String { String(localized: "event.formal") }

    // MARK: — Wardrobe
    static var wardrobeNavTitle:        String { String(localized: "wardrobe.nav.title") }
    static var wardrobeSearchPlaceholder: String { String(localized: "wardrobe.search.placeholder") }
    static var wardrobeFilterAll:       String { String(localized: "wardrobe.filter.all") }
    static var wardrobeStatusActive:    String { String(localized: "wardrobe.status.active") }
    static var wardrobeStatusArchived:  String { String(localized: "wardrobe.status.archived") }

    // MARK: — Clothing categories
    static var categoryTop:       String { String(localized: "category.top") }
    static var categoryBottom:    String { String(localized: "category.bottom") }
    static var categoryFootwear:  String { String(localized: "category.footwear") }
    static var categoryOuterwear: String { String(localized: "category.outerwear") }
    static var categoryAccessory: String { String(localized: "category.accessory") }

    // MARK: — Error states
    static var errorWardrobeTitle:    String { String(localized: "error.wardrobe.title") }
    static var errorWardrobeSubtitle: String { String(localized: "error.wardrobe.subtitle") }
    static var errorLocationTitle:    String { String(localized: "error.location.title") }
    static var errorLocationSubtitle: String { String(localized: "error.location.subtitle") }
    static var errorAITitle:          String { String(localized: "error.ai.title") }
    static var errorAISubtitle:       String { String(localized: "error.ai.subtitle") }

    // MARK: — Tab labels
    static var tabsToday:    String { String(localized: "tabs.today") }
    static var tabsWardrobe: String { String(localized: "tabs.wardrobe") }
    static var tabsInsights: String { String(localized: "tabs.insights") }
    static var tabsProfile:  String { String(localized: "tabs.profile") }

    // MARK: — Insights
    static var insightsNavTitle:       String { String(localized: "insights.nav.title") }
    static var insightsStyleTitle:     String { String(localized: "insights.style.title") }
    static var insightsTopTitle:       String { String(localized: "insights.top.title") }
    static var insightsHealthTitle:    String { String(localized: "insights.health.title") }
    static var insightsHealthActive:   String { String(localized: "insights.health.active") }
    static var insightsHealthArchived: String { String(localized: "insights.health.archived") }
    static var insightsHealthDisposed: String { String(localized: "insights.health.disposed") }
    static var insightsEmptyTitle:     String { String(localized: "insights.empty.title") }
    static var insightsEmptySubtitle:  String { String(localized: "insights.empty.subtitle") }
    static var insightsWorn:           String { String(localized: "insights.worn") }

    // MARK: — Profile & settings
    static var profileNavTitle:            String { String(localized: "profile.nav.title") }
    static var profileSectionColorimetry:  String { String(localized: "profile.section.colorimetry") }
    static var profileSectionAvoid:        String { String(localized: "profile.section.avoid") }
    static var profileSectionTraits:       String { String(localized: "profile.section.traits") }
    static var profileTraitBody:           String { String(localized: "profile.trait.body") }
    static var profileTraitSkin:           String { String(localized: "profile.trait.skin") }
    static var profileTraitEye:            String { String(localized: "profile.trait.eye") }
    static var profileTraitHair:           String { String(localized: "profile.trait.hair") }
    static var profileTraitMetal:          String { String(localized: "profile.trait.metal") }
    static var profileRetakeButton:        String { String(localized: "profile.retake.button") }
    static var profileRetakeTitle:         String { String(localized: "profile.retake.title") }
    static var profileRetakeMessage:       String { String(localized: "profile.retake.message") }
    static var profileDangerZone:          String { String(localized: "profile.danger.zone") }
    static var profileDeleteButton:        String { String(localized: "profile.delete.button") }
    static var profileDeleteTitle:         String { String(localized: "profile.delete.title") }
    static var profileDeleteMessage:       String { String(localized: "profile.delete.message") }

    // MARK: — Wardrobe filters
    static var filterSectionStatus:     String { String(localized: "filter.section.status") }
    static var filterSectionStyles:     String { String(localized: "filter.section.styles") }
    static var filterSectionPatterns:   String { String(localized: "filter.section.patterns") }
    static var filterStatusActive:      String { String(localized: "filter.status.active") }
    static var filterStatusArchived:    String { String(localized: "filter.status.archived") }
    static var filterClearAll:          String { String(localized: "filter.clear_all") }
    static var filterNoResultsTitle:    String { String(localized: "filter.no_results.title") }
    static var filterNoResultsSubtitle: String { String(localized: "filter.no_results.subtitle") }
}

// ── ClothingCategory display names ────────────────────────────────────────────
// Extension here keeps all localization concerns in one file.

extension ClothingCategory {
    var localizedName: String {
        switch self {
        case .top:       return Strings.categoryTop
        case .bottom:    return Strings.categoryBottom
        case .footwear:  return Strings.categoryFootwear
        case .outerwear: return Strings.categoryOuterwear
        case .accessory: return Strings.categoryAccessory
        }
    }
}
