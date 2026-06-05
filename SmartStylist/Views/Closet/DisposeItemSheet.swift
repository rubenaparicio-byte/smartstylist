import SwiftUI

struct DisposeItemSheet: View {
    let item: ClothingItem
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss
    @State private var vm = ClosetViewModel()
    @State private var reason: DisposeReason = .unused

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dsDeepSlate.ignoresSafeArea()

                VStack(spacing: 0) {
                    VStack(spacing: 12) {
                        SilhouetteView(category: item.category, size: 80)
                        Text("RETIRE THIS PIECE")
                            .font(.dsTitle2)
                            .foregroundStyle(Color.dsTextPrimary)
                            .tracking(2)
                        Text("Select a reason to complete the retirement.")
                            .font(.dsBody)
                            .foregroundStyle(Color.dsTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 32)
                    .padding(.horizontal, 24)

                    GoldDivider()
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                    VStack(spacing: 10) {
                        ForEach(DisposeReason.allCases, id: \.rawValue) { r in
                            reasonRow(r)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    Spacer()

                    Button(role: .destructive) {
                        vm.disposeItem(item, reason: reason, context: ctx)
                        dismiss()
                    } label: {
                        Text("Confirm Retirement")
                            .font(.dsBodyMedium)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.dsErrorRed.opacity(0.85))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 36)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.dsTextSecondary)
                }
            }
        }
    }

    private func reasonRow(_ r: DisposeReason) -> some View {
        Button { reason = r } label: {
            HStack(spacing: 16) {
                Image(systemName: r.icon)
                    .foregroundStyle(reason == r ? Color.dsDeepSlate : Color.dsAccentGold)
                    .frame(width: 20)
                Text(r.label)
                    .font(.dsBodyMedium)
                    .foregroundStyle(reason == r ? Color.dsDeepSlate : Color.dsTextPrimary)
                Spacer()
                if reason == r {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.dsDeepSlate)
                        .font(.caption.weight(.semibold))
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(reason == r ? Color.dsAccentGold : Color.dsSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .animation(.dsDefault, value: reason)
    }
}
