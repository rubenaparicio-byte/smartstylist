import SwiftUI

struct StyleEngineRootView: View {
    @State private var mode: Mode = .planner

    private enum Mode: String, CaseIterable {
        case planner
        case instant

        var label: String {
            switch self {
            case .planner: return Strings.plannerTabLabel
            case .instant: return Strings.instantTabLabel
            }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                switch mode {
                case .planner: LookPlannerView()
                case .instant: InstantLookView()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("", selection: $mode) {
                        ForEach(Mode.allCases, id: \.self) { m in
                            Text(m.label).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 220)
                    .onChange(of: mode) { _, _ in
                        HapticManager.impact(.light)
                    }
                }
            }
            .toolbarBackground(Material.ultraThinMaterial, for: .navigationBar)
        }
    }
}
