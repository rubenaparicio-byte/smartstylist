import Foundation
import SwiftData
import Observation

@Observable
final class OnboardingViewModel {
    var currentStep: OnboardingStep = .bodyType
    var isLoading = false
    var errorMessage: String?

    var selectedBodyType = ""
    var selectedSkinTone = ""
    var selectedEyeColor = ""
    var selectedHairColor = ""

    var analysisResult: ColorimetryAnalysis?

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
            await gemini.logFreeModels()
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
            metalPreference: result.metalPreference
        )
        context.insert(profile)
        try? context.save()
    }

    let bodyTypeOptions    = ["Hourglass", "Rectangle", "Triangle", "Inverted Triangle", "Oval"]
    let skinToneOptions    = ["Warm Light", "Warm Medium", "Warm Deep", "Cool Light", "Cool Medium", "Cool Deep", "Neutral"]
    let eyeColorOptions    = ["Brown", "Dark Brown", "Hazel", "Green", "Blue", "Grey"]
    let hairColorOptions   = ["Black", "Dark Brown", "Brown", "Light Brown", "Blonde", "Auburn", "Red", "Grey", "White"]
}
