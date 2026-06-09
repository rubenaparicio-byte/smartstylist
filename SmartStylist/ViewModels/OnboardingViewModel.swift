import Foundation
import SwiftData
import Observation

@Observable
final class OnboardingViewModel {
    var currentStep: OnboardingStep = .language
    var isLoading = false
    var errorMessage: String?

    var selectedLanguage = "system"
    var selectedGender = ""
    var selectedBodyType = ""
    var selectedSkinTone = ""
    var selectedEyeColor = ""
    var selectedHairColor = ""
    var selectedAccessoryStyles: [String] = []

    var analysisResult: ColorimetryAnalysis?

    private let gemini = GeminiService()

    enum OnboardingStep: Int, CaseIterable {
        case language = 0, gender, bodyType, skinTone, hairEye, result
    }

    var canAdvance: Bool {
        switch currentStep {
        case .language:  return true
        case .gender:    return !selectedGender.isEmpty
        case .bodyType:  return !selectedBodyType.isEmpty
        case .skinTone:  return !selectedSkinTone.isEmpty
        case .hairEye:   return !selectedEyeColor.isEmpty && !selectedHairColor.isEmpty
        case .result:    return false
        }
    }

    func advance() {
        switch currentStep {
        case .language, .gender, .bodyType, .skinTone:
            if let next = OnboardingStep(rawValue: currentStep.rawValue + 1) {
                currentStep = next
            }
        case .hairEye:
            Task { await analyseProfile() }
        case .result:
            break
        }
    }

    @MainActor
    func analyseProfile() async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await gemini.analyseProfile(
                gender: selectedGender,
                bodyType: selectedBodyType,
                skinTone: selectedSkinTone,
                eyeColor: selectedEyeColor,
                hairColor: selectedHairColor
            )
            analysisResult = result
            currentStep = .result
        } catch {
            let detail = DebugLogger.shared.entries.first ?? ""
            errorMessage = detail.isEmpty
                ? error.localizedDescription
                : "\(error.localizedDescription)\n\n\(detail)"
        }
        isLoading = false
    }

    func save(to context: ModelContext) {
        guard let result = analysisResult else { return }
        let profile = UserProfile(
            gender: selectedGender,
            bodyType: selectedBodyType,
            skinTone: selectedSkinTone,
            eyeColor: selectedEyeColor,
            hairColor: selectedHairColor,
            seasonalColorimetry: result.season,
            styleGuidelines: result.guidelines,
            onboardingCompleted: true,
            recommendedColorNames: result.recommendedColors.map(\.name),
            recommendedColorHexes: result.recommendedColors.map(\.hex),
            avoidColorNames: result.avoidColors.map(\.name),
            avoidColorHexes: result.avoidColors.map(\.hex),
            metalPreference: result.metalPreference,
            accessoryStyle: selectedAccessoryStyles
        )
        context.insert(profile)
        try? context.save()
    }

    let skinToneOptions  = ["Warm Light", "Warm Medium", "Warm Deep",
                            "Cool Light", "Cool Medium", "Cool Deep", "Neutral"]
    let eyeColorOptions  = ["Brown", "Dark Brown", "Hazel", "Green", "Blue", "Grey"]
    let hairColorOptions = ["Black", "Dark Brown", "Brown", "Light Brown",
                            "Blonde", "Auburn", "Red", "Grey", "White"]
    let accessoryStyleOptions = ["Minimal", "Statement", "Layered", "Vintage"]

    var bodyTypeOptions: [String] {
        selectedGender == "Male"
            ? ["Athletic", "Rectangle", "Oval", "Trapezoid", "Triangle"]
            : ["Hourglass", "Rectangle", "Triangle", "Inverted Triangle", "Oval"]
    }
}
