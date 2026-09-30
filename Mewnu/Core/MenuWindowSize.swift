import Foundation
import SwiftUI

@MainActor
final class MenuWindowSize: ObservableObject {
    static let width: CGFloat = 364
    static let defaultHeight: CGFloat = 620
    static let minimumHeight: CGFloat = 500
    static let maximumHeight: CGFloat = 1_000

    private static let heightKey = "menuWindowHeight"
    private let defaults: UserDefaults
    @Published private(set) var height: CGFloat

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let stored = (defaults.object(forKey: Self.heightKey) as? NSNumber).map { CGFloat($0.doubleValue) }
        height = Self.clamped(stored ?? Self.defaultHeight, maximum: Self.maximumHeight)
    }

    func height(maximum: CGFloat) -> CGFloat {
        Self.clamped(height, maximum: maximum)
    }

    func saveHeight(_ value: CGFloat, maximum: CGFloat) {
        let value = Self.clamped(value, maximum: maximum)
        height = value
        defaults.set(Double(value), forKey: Self.heightKey)
    }

    static func clamped(_ value: CGFloat, maximum: CGFloat) -> CGFloat {
        let upperBound = max(1, min(maximum.isFinite ? maximum : maximumHeight, maximumHeight))
        let lowerBound = min(minimumHeight, upperBound)
        guard value.isFinite else { return min(defaultHeight, upperBound) }
        return min(max(value, lowerBound), upperBound)
    }
}
