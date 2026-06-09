import Foundation

// ── Strings ───────────────────────────────────────────────────────────────────
// Central namespace for all user-facing strings in SmartStylist.
// Reads the user's language preference from UserDefaults at call time so the
// correct locale is always used regardless of the iOS system language.
//
// Supported locales: en (development fallback), es
//
// Usage in views:   Text(Strings.commonRetry)
// Usage in VM:      Strings.eventDaily  (already resolved String)
//
// For new strings: add the var here, add the key to both .strings files.

enum Strings {

    // MARK: — Locale

    static var activeLocale: Locale {
        switch UserDefaults.standard.string(forKey: "preferredLanguage") ?? "system" {
        case "es": return Locale(identifier: "es")
        case "en": return Locale(identifier: "en")
        default:   return .autoupdatingCurrent
        }
    }

    // MARK: — Common actions
    static var commonRetry:        String { String(localized: "common.retry",         locale: activeLocale) }
    static var commonCancel:       String { String(localized: "common.cancel",        locale: activeLocale) }
    static var commonError:        String { String(localized: "common.error",         locale: activeLocale) }
    static var commonOpenSettings: String { String(localized: "common.open_settings", locale: activeLocale) }
    static var commonSave:         String { String(localized: "add.button.save",      locale: activeLocale) }

    // MARK: — Loading messages
    static var loadingAnalysingWardrobe: String { String(localized: "loading.analysing_wardrobe", locale: activeLocale) }
    static var loadingReadingColour:     String { String(localized: "loading.reading_colour",     locale: activeLocale) }
    static var loadingCuratingLook:      String { String(localized: "loading.curating_look",      locale: activeLocale) }
    static var loadingAlmostReady:       String { String(localized: "loading.almost_ready",       locale: activeLocale) }

    // MARK: — Onboarding
    static var onboardingAnalyseMyStyle:   String { String(localized: "onboarding.cta.analyse",        locale: activeLocale) }
    static var onboardingContinue:         String { String(localized: "onboarding.cta.continue",       locale: activeLocale) }
    static var onboardingAnalysingProfile: String { String(localized: "onboarding.loading.analysing",  locale: activeLocale) }

    static var onboardingGenderTitle:    String { String(localized: "onboarding.gender.title",    locale: activeLocale) }
    static var onboardingGenderSubtitle: String { String(localized: "onboarding.gender.subtitle", locale: activeLocale) }
    static var onboardingGenderMale:     String { String(localized: "onboarding.gender.male",     locale: activeLocale) }
    static var onboardingGenderFemale:   String { String(localized: "onboarding.gender.female",   locale: activeLocale) }

    static var onboardingBodyTitle:    String { String(localized: "onboarding.body.title",    locale: activeLocale) }
    static var onboardingBodySubtitle: String { String(localized: "onboarding.body.subtitle", locale: activeLocale) }
    static var onboardingSkinTitle:    String { String(localized: "onboarding.skin.title",    locale: activeLocale) }
    static var onboardingSkinSubtitle: String { String(localized: "onboarding.skin.subtitle", locale: activeLocale) }
    static var onboardingHairTitle:    String { String(localized: "onboarding.hair.title",    locale: activeLocale) }
    static var onboardingHairSubtitle: String { String(localized: "onboarding.hair.subtitle", locale: activeLocale) }
    static var onboardingHairColour:   String { String(localized: "onboarding.hair.colour",   locale: activeLocale) }
    static var onboardingEyeColour:    String { String(localized: "onboarding.eye.colour",    locale: activeLocale) }
    static var onboardingResultTitle:           String { String(localized: "onboarding.result.title",            locale: activeLocale) }
    static var onboardingResultSubtitle:        String { String(localized: "onboarding.result.subtitle",         locale: activeLocale) }
    static var onboardingResultPalette:         String { String(localized: "onboarding.result.palette",          locale: activeLocale) }
    static var onboardingResultMinimise:        String { String(localized: "onboarding.result.minimise",         locale: activeLocale) }
    static var onboardingResultEnter:           String { String(localized: "onboarding.result.enter",            locale: activeLocale) }
    static var onboardingResultAccessoryTitle:  String { String(localized: "onboarding.result.accessory.title",  locale: activeLocale) }
    static var onboardingResultAccessorySubtitle: String { String(localized: "onboarding.result.accessory.subtitle", locale: activeLocale) }

    // MARK: — Style Engine
    static var styleNavTitle:         String { String(localized: "style.nav.title",           locale: activeLocale) }
    static var styleEventContext:     String { String(localized: "style.section.event_context", locale: activeLocale) }
    static var styleOutfitRegistered: String { String(localized: "style.outfit.registered",   locale: activeLocale) }
    static var styleOutfitSave:       String { String(localized: "style.outfit.save",         locale: activeLocale) }
    static var styleEmptyTitle:       String { String(localized: "style.empty.title",         locale: activeLocale) }
    static var styleEmptySubtitle:    String { String(localized: "style.empty.subtitle",      locale: activeLocale) }
    static var styleOfflineMode:      String { String(localized: "style.offline.mode",        locale: activeLocale) }

    // MARK: — Event contexts
    static var eventDaily:         String { String(localized: "event.daily",          locale: activeLocale) }
    static var eventWork:          String { String(localized: "event.work",           locale: activeLocale) }
    static var eventEveningDate:   String { String(localized: "event.evening_date",   locale: activeLocale) }
    static var eventGym:           String { String(localized: "event.gym",            locale: activeLocale) }
    static var eventCasualWeekend: String { String(localized: "event.casual_weekend", locale: activeLocale) }
    static var eventFormal:        String { String(localized: "event.formal",         locale: activeLocale) }

    // MARK: — Wardrobe
    static var wardrobeNavTitle:          String { String(localized: "wardrobe.nav.title",          locale: activeLocale) }
    static var wardrobeSearchPlaceholder: String { String(localized: "wardrobe.search.placeholder", locale: activeLocale) }
    static var wardrobeFilterAll:         String { String(localized: "wardrobe.filter.all",         locale: activeLocale) }
    static var wardrobeStatusActive:      String { String(localized: "wardrobe.status.active",      locale: activeLocale) }
    static var wardrobeStatusArchived:    String { String(localized: "wardrobe.status.archived",    locale: activeLocale) }

    // MARK: — Clothing categories
    static var categoryTop:       String { String(localized: "category.top",       locale: activeLocale) }
    static var categoryBottom:    String { String(localized: "category.bottom",    locale: activeLocale) }
    static var categoryFootwear:  String { String(localized: "category.footwear",  locale: activeLocale) }
    static var categoryOuterwear: String { String(localized: "category.outerwear", locale: activeLocale) }
    static var categoryAccessory: String { String(localized: "category.accessory", locale: activeLocale) }

    // MARK: — Add item
    static var addNavTitle:          String { String(localized: "add.nav.title",          locale: activeLocale) }
    static var addSectionPhoto:      String { String(localized: "add.section.photo",      locale: activeLocale) }
    static var addSectionDetails:    String { String(localized: "add.section.details",    locale: activeLocale) }
    static var addPickerCategory:    String { String(localized: "add.picker.category",    locale: activeLocale) }
    static var addPickerSubcategory: String { String(localized: "add.picker.subcategory", locale: activeLocale) }
    static var addPickerLayer:       String { String(localized: "add.picker.layer",       locale: activeLocale) }
    static var addFieldStyle:        String { String(localized: "add.field.style",        locale: activeLocale) }
    static var addFieldColour:       String { String(localized: "add.field.colour",       locale: activeLocale) }
    static var addFieldPattern:      String { String(localized: "add.field.pattern",      locale: activeLocale) }
    static var addFieldTags:         String { String(localized: "add.field.tags",         locale: activeLocale) }
    static var addButtonCamera:      String { String(localized: "add.button.camera",      locale: activeLocale) }
    static var addButtonGallery:     String { String(localized: "add.button.gallery",     locale: activeLocale) }
    static var addButtonAnalyse:     String { String(localized: "add.button.analyse",     locale: activeLocale) }
    static var addButtonAnalysing:   String { String(localized: "add.button.analysing",   locale: activeLocale) }
    static var addLabelSegmenting:   String { String(localized: "add.label.segmenting",   locale: activeLocale) }

    // MARK: — Validate sheet
    static var validateNavTitle:       String { String(localized: "validate.nav.title",         locale: activeLocale) }
    static var validateHeader:         String { String(localized: "validate.header",             locale: activeLocale) }
    static var validateSubheader:      String { String(localized: "validate.subheader",          locale: activeLocale) }
    static var validatePickerCategory: String { String(localized: "validate.picker.category",    locale: activeLocale) }
    static var validatePickerSubcat:   String { String(localized: "validate.picker.subcategory", locale: activeLocale) }
    static var validatePickerLayer:    String { String(localized: "validate.picker.layer",       locale: activeLocale) }
    static var validatePickerPattern:  String { String(localized: "validate.picker.pattern",     locale: activeLocale) }
    static var validatePickerStyle:    String { String(localized: "validate.picker.style",       locale: activeLocale) }
    static var validateFieldColour:    String { String(localized: "validate.field.colour",       locale: activeLocale) }
    static var validateFieldTags:      String { String(localized: "validate.field.tags",         locale: activeLocale) }
    static var validateTagsPlaceholder: String { String(localized: "validate.field.tags.placeholder", locale: activeLocale) }
    static var validateButtonConfirm:  String { String(localized: "validate.button.confirm",     locale: activeLocale) }

    // MARK: — Card actions
    static var cardArchived:      String { String(localized: "card.archived",       locale: activeLocale) }
    static var cardActionArchive: String { String(localized: "card.action.archive", locale: activeLocale) }
    static var cardActionRestore: String { String(localized: "card.action.restore", locale: activeLocale) }
    static var cardActionRetire:  String { String(localized: "card.action.retire",  locale: activeLocale) }

    // MARK: — Outfit card
    static var outfitLayerComposition: String { String(localized: "outfit.layer.composition", locale: activeLocale) }
    static var outfitNoItems:          String { String(localized: "outfit.no.items",          locale: activeLocale) }
    static var outfitFootwear:         String { String(localized: "outfit.footwear",          locale: activeLocale) }

    // MARK: — Dispose sheet
    static var disposeTitle:   String { String(localized: "dispose.title",   locale: activeLocale) }
    static var disposeSubtitle: String { String(localized: "dispose.subtitle", locale: activeLocale) }
    static var disposeConfirm: String { String(localized: "dispose.confirm", locale: activeLocale) }

    static var disposeReasonWorn:    String { String(localized: "dispose.reason.worn",    locale: activeLocale) }
    static var disposeReasonDamaged: String { String(localized: "dispose.reason.damaged", locale: activeLocale) }
    static var disposeReasonDonated: String { String(localized: "dispose.reason.donated", locale: activeLocale) }
    static var disposeReasonUnused:  String { String(localized: "dispose.reason.unused",  locale: activeLocale) }

    // MARK: — Language settings
    static var settingsSectionLanguage: String { String(localized: "settings.section.language", locale: activeLocale) }
    static var settingsLanguageLabel:   String { String(localized: "settings.language.label",   locale: activeLocale) }
    static var settingsLanguageSystem:  String { String(localized: "settings.language.system",  locale: activeLocale) }
    static var settingsLanguageEN:      String { String(localized: "settings.language.en",      locale: activeLocale) }
    static var settingsLanguageES:      String { String(localized: "settings.language.es",      locale: activeLocale) }

    // MARK: — Weather
    static func weatherFeelsLike(_ celsius: Int) -> String {
        String(format: String(localized: "weather.feels.like", locale: activeLocale), celsius)
    }
    static var weatherUmbrella: String { String(localized: "weather.umbrella", locale: activeLocale) }

    // MARK: — Error states
    static var errorWardrobeTitle:    String { String(localized: "error.wardrobe.title",    locale: activeLocale) }
    static var errorWardrobeSubtitle: String { String(localized: "error.wardrobe.subtitle", locale: activeLocale) }
    static var errorLocationTitle:    String { String(localized: "error.location.title",    locale: activeLocale) }
    static var errorLocationSubtitle: String { String(localized: "error.location.subtitle", locale: activeLocale) }
    static var errorAITitle:          String { String(localized: "error.ai.title",          locale: activeLocale) }
    static var errorAISubtitle:       String { String(localized: "error.ai.subtitle",       locale: activeLocale) }

    // MARK: — Tab labels
    static var tabsToday:    String { String(localized: "tabs.today",    locale: activeLocale) }
    static var tabsWardrobe: String { String(localized: "tabs.wardrobe", locale: activeLocale) }
    static var tabsInsights: String { String(localized: "tabs.insights", locale: activeLocale) }
    static var tabsProfile:  String { String(localized: "tabs.profile",  locale: activeLocale) }

    // MARK: — Insights
    static var insightsNavTitle:       String { String(localized: "insights.nav.title",        locale: activeLocale) }
    static var insightsStyleTitle:     String { String(localized: "insights.style.title",      locale: activeLocale) }
    static var insightsTopTitle:       String { String(localized: "insights.top.title",        locale: activeLocale) }
    static var insightsHealthTitle:    String { String(localized: "insights.health.title",     locale: activeLocale) }
    static var insightsHealthActive:   String { String(localized: "insights.health.active",    locale: activeLocale) }
    static var insightsHealthArchived: String { String(localized: "insights.health.archived",  locale: activeLocale) }
    static var insightsHealthDisposed: String { String(localized: "insights.health.disposed",  locale: activeLocale) }
    static var insightsEmptyTitle:     String { String(localized: "insights.empty.title",      locale: activeLocale) }
    static var insightsEmptySubtitle:  String { String(localized: "insights.empty.subtitle",   locale: activeLocale) }
    static var insightsWorn:           String { String(localized: "insights.worn",             locale: activeLocale) }
    static func insightsMostDisposed(_ label: String) -> String {
        String(format: String(localized: "insights.most.disposed", locale: activeLocale), label)
    }

    // MARK: — Profile & settings
    static var profileNavTitle:              String { String(localized: "profile.nav.title",              locale: activeLocale) }
    static var profileSectionIdentity:       String { String(localized: "profile.section.identity",       locale: activeLocale) }
    static var profileSectionColorimetry:    String { String(localized: "profile.section.colorimetry",    locale: activeLocale) }
    static var profileSectionAvoid:          String { String(localized: "profile.section.avoid",          locale: activeLocale) }
    static var profileSectionTraits:         String { String(localized: "profile.section.traits",         locale: activeLocale) }
    static var profileSectionShopping:       String { String(localized: "profile.section.shopping",       locale: activeLocale) }
    static var profileTraitGender:           String { String(localized: "profile.trait.gender",           locale: activeLocale) }
    static var profileTraitAge:              String { String(localized: "profile.trait.age",              locale: activeLocale) }
    static var profileTraitBody:             String { String(localized: "profile.trait.body",             locale: activeLocale) }
    static var profileTraitSkin:             String { String(localized: "profile.trait.skin",             locale: activeLocale) }
    static var profileTraitEye:              String { String(localized: "profile.trait.eye",              locale: activeLocale) }
    static var profileTraitHair:             String { String(localized: "profile.trait.hair",             locale: activeLocale) }
    static var profileTraitMetal:            String { String(localized: "profile.trait.metal",            locale: activeLocale) }
    static var profileTraitAccessoryStyle:   String { String(localized: "profile.trait.accessory_style",  locale: activeLocale) }
    static var profileStoresEdit:            String { String(localized: "profile.stores.edit",            locale: activeLocale) }
    static var profileStoresEmpty:           String { String(localized: "profile.stores.empty",           locale: activeLocale) }
    static var profileRetakeButton:          String { String(localized: "profile.retake.button",          locale: activeLocale) }
    static var profileRetakeTitle:           String { String(localized: "profile.retake.title",           locale: activeLocale) }
    static var profileRetakeMessage:         String { String(localized: "profile.retake.message",         locale: activeLocale) }
    static var profileDangerZone:            String { String(localized: "profile.danger.zone",            locale: activeLocale) }
    static var profileDeleteButton:          String { String(localized: "profile.delete.button",          locale: activeLocale) }
    static var profileDeleteTitle:           String { String(localized: "profile.delete.title",           locale: activeLocale) }
    static var profileDeleteMessage:         String { String(localized: "profile.delete.message",         locale: activeLocale) }

    // MARK: — Stores
    static var storesNavTitle: String { String(localized: "stores.nav.title", locale: activeLocale) }
    static var storesSubtitle: String { String(localized: "stores.subtitle",  locale: activeLocale) }
    static var storesDone:     String { String(localized: "stores.done",      locale: activeLocale) }

    // MARK: — Wardrobe filters
    static var filterSectionStatus:     String { String(localized: "filter.section.status",     locale: activeLocale) }
    static var filterSectionStyles:     String { String(localized: "filter.section.styles",     locale: activeLocale) }
    static var filterSectionPatterns:   String { String(localized: "filter.section.patterns",   locale: activeLocale) }
    static var filterStatusActive:      String { String(localized: "filter.status.active",      locale: activeLocale) }
    static var filterStatusArchived:    String { String(localized: "filter.status.archived",    locale: activeLocale) }
    static var filterClearAll:          String { String(localized: "filter.clear_all",          locale: activeLocale) }
    static var filterNoResultsTitle:    String { String(localized: "filter.no_results.title",   locale: activeLocale) }
    static var filterNoResultsSubtitle: String { String(localized: "filter.no_results.subtitle", locale: activeLocale) }
}

// ── ClothingCategory display names ────────────────────────────────────────────

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

// ── Pattern & style display names (DB values stay English for LLM) ────────────

extension String {
    var localizedPatternName: String {
        switch self {
        case "Solid":        return String(localized: "pattern.solid",        locale: Strings.activeLocale)
        case "Stripes":      return String(localized: "pattern.stripes",      locale: Strings.activeLocale)
        case "Checks":       return String(localized: "pattern.checks",       locale: Strings.activeLocale)
        case "Floral":       return String(localized: "pattern.floral",       locale: Strings.activeLocale)
        case "Abstract":     return String(localized: "pattern.abstract",     locale: Strings.activeLocale)
        case "Animal Print": return String(localized: "pattern.animal_print", locale: Strings.activeLocale)
        default: return self
        }
    }

    var localizedStyleName: String {
        switch self {
        case "Casual":       return String(localized: "style.casual",       locale: Strings.activeLocale)
        case "Formal":       return String(localized: "style.formal",       locale: Strings.activeLocale)
        case "Smart Casual": return String(localized: "style.smart_casual", locale: Strings.activeLocale)
        case "Athletic":     return String(localized: "style.athletic",     locale: Strings.activeLocale)
        case "Evening":      return String(localized: "style.evening",      locale: Strings.activeLocale)
        default: return self
        }
    }
}
