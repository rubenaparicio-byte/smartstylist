import SwiftUI

extension Animation {
    static let dsDefault    = Animation.easeInOut(duration: 0.3)
    static let dsFast       = Animation.easeInOut(duration: 0.18)
    static let dsSpring     = Animation.spring(response: 0.4, dampingFraction: 0.75)
}
