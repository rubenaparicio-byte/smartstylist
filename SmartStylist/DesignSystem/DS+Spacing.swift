import Foundation

// Spacing scale based on a 4-pt base unit.
// Use DSSpacing tokens instead of hardcoded padding/spacing values.
enum DSSpacing {
    static let xs:   CGFloat = 4
    static let sm:   CGFloat = 8
    static let md:   CGFloat = 12
    static let lg:   CGFloat = 16
    static let xl:   CGFloat = 24
    static let xxl:  CGFloat = 32
    static let xxxl: CGFloat = 48
}

// Fixed component dimensions — avoids magic numbers in view code.
enum DSSize {
    static let thumbnailSquare:    CGFloat = 96
    static let cardHeight:         CGFloat = 160
    static let garmentTileWidth:   CGFloat = 52
    static let garmentTileHeight:  CGFloat = 68
    static let iconButton:         CGFloat = 38
    static let floatingButton:     CGFloat = 56
    static let tabBarPadding:      CGFloat = 24
    static let cornerRadiusCard:   CGFloat = 20
    static let cornerRadiusMedium: CGFloat = 14
    static let cornerRadiusSmall:  CGFloat = 10
    static let cornerRadiusChip:   CGFloat = 8
}
