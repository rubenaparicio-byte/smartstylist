import SwiftUI

struct SilhouetteView: View {
    let category: ClothingCategory
    var size: CGFloat = 120

    var body: some View {
        Canvas { ctx, canvasSize in
            let s = min(canvasSize.width, canvasSize.height)
            ctx.stroke(path(for: category, in: s),
                       with: .color(Color.dsAccentPrimary.opacity(0.35)),
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

    private func topSilhouette(in s: CGFloat) -> Path {
        Path { p in
            let cx = s / 2
            p.move(to: CGPoint(x: cx - s*0.1, y: s*0.1))
            p.addQuadCurve(to: CGPoint(x: cx + s*0.1, y: s*0.1),
                           control: CGPoint(x: cx, y: s*0.18))
            p.addLine(to: CGPoint(x: s*0.85, y: s*0.2))
            p.addLine(to: CGPoint(x: s*0.95, y: s*0.35))
            p.addLine(to: CGPoint(x: s*0.75, y: s*0.35))
            p.addLine(to: CGPoint(x: s*0.75, y: s*0.9))
            p.addLine(to: CGPoint(x: s*0.25, y: s*0.9))
            p.addLine(to: CGPoint(x: s*0.25, y: s*0.35))
            p.addLine(to: CGPoint(x: s*0.05, y: s*0.35))
            p.addLine(to: CGPoint(x: s*0.15, y: s*0.2))
            p.closeSubpath()
        }
    }

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
    .background(Color.dsBackground)
}
