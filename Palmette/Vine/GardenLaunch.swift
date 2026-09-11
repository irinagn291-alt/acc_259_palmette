import Foundation

/// Role: Vine. Garden-tab chrome. Garden holds the trellis; Analytics and Settings are siblings. No Plot or GardenGame tab.
enum GardenTab: String, Hashable, Sendable, CaseIterable {
    case garden
    case analytics
    case settings
}

/// Role: Vine. Launch keys for live shots. today, log, and goals open three different screens.
enum GardenPane: String, Equatable, Sendable {
    case today
    case log
    case goals

    var tab: GardenTab {
        switch self {
        case .today: .garden
        case .log: .analytics
        case .goals: .settings
        }
    }
}

/// Role: Vine. Reads `-ReviewScreen today|log|goals` once, only after onboarding. Never hosts a View.
enum GardenLaunch {
    static func consume(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        onboardingComplete: Bool,
        consumed: inout Bool
    ) -> GardenPane? {
        guard onboardingComplete, !consumed else { return nil }
        consumed = true
        guard let index = arguments.firstIndex(of: "-ReviewScreen") else { return nil }
        let next = arguments.index(after: index)
        guard arguments.indices.contains(next) else { return nil }
        return GardenPane(rawValue: arguments[next])
    }
}
