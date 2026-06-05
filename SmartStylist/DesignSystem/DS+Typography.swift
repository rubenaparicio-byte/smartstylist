import SwiftUI

extension Font {
    static let dsLargeTitle  = Font.system(.largeTitle,  design: .serif).weight(.regular)
    static let dsTitle        = Font.system(.title,       design: .serif).weight(.regular)
    static let dsTitle2       = Font.system(.title2,      design: .serif).weight(.light)
    static let dsBody         = Font.system(.body,        design: .default).weight(.light)
    static let dsBodyMedium   = Font.system(.body,        design: .default).weight(.regular)
    static let dsCaption      = Font.system(.caption,     design: .default).weight(.light)
    static let dsLabel        = Font.system(.footnote,    design: .default).weight(.medium)
}

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
