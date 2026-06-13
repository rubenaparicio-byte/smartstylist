import SwiftUI
import SwiftData

struct OnboardingContainerView: View {
    @Environment(\.modelContext) private var ctx
    @State private var vm = OnboardingViewModel()

    var body: some View {
        @Bindable var vm = vm
        return ZStack {
            Color.dsDeepSlate.ignoresSafeArea()

            VStack(spacing: 0) {
                progressBar
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                TabView(selection: $vm.currentStep) {
                    LanguageStepView(vm: vm).tag(OnboardingViewModel.OnboardingStep.language)
                    GenderStepView(vm: vm).tag(OnboardingViewModel.OnboardingStep.gender)
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

            // Premium loading overlay during Gemini analysis
            if vm.isLoading {
                Color.dsDeepSlate.opacity(0.82)
                    .ignoresSafeArea()
                    .transition(.opacity)
                LuxuryLoadingView()
                    .transition(.opacity)
            }
        }
        .animation(.dsDefault, value: vm.isLoading)
        .alert(Strings.commonError, isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { _ in vm.errorMessage = nil }
        )) {
            Button(Strings.commonRetry) {
                vm.errorMessage = nil
                Task { await vm.analyseProfile() }
            }
            Button(Strings.commonCancel, role: .cancel) { vm.errorMessage = nil }
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
            Text(vm.currentStep == .hairEye
                 ? Strings.onboardingAnalyseMyStyle
                 : Strings.onboardingContinue)
                .font(.dsBodyMedium)
                .foregroundStyle(Color.dsDeepSlate)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(vm.canAdvance ? Color.dsAccentGold : Color.dsSurface)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .accessibilityIdentifier("onboarding.advance")
        .disabled(!vm.canAdvance)
        .animation(.dsDefault, value: vm.canAdvance)
    }
}
