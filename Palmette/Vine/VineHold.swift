import Foundation

/// Role: Vine. In-memory garden for previews and tests. Views never see this type.
actor VineHold: VineStoring {
    private var latest: Garden
    private var warning: GardenWarning?

    init(garden: Garden = .empty, warning: GardenWarning? = nil) {
        self.latest = garden
        self.warning = warning
    }

    func load() async -> (garden: Garden, warning: GardenWarning?) {
        (latest, warning)
    }

    func snapshot() async -> Garden {
        latest
    }

    func plant(name: String, target: Double, vineSeed: Int) async throws -> Garden {
        latest = try latest.planting(name: name, target: target, vineSeed: vineSeed)
        return latest
    }

    func pour(vineID: UUID, amount: Double, now: Date, calendar: Calendar) async throws -> Garden {
        latest = try latest.pouring(vineID: vineID, amount: amount, now: now, calendar: calendar)
        return latest
    }

    func pinchLeader(vineID: UUID, now: Date) async throws -> Garden {
        latest = try latest.pinchLeader(vineID: vineID, now: now)
        return latest
    }

    func retract(vineID: UUID, amount: Double) async throws -> Garden {
        latest = try latest.retracting(vineID: vineID, amount: amount)
        return latest
    }

    func retractFlush(vineID: UUID) async throws -> Garden {
        latest = try latest.retractingFlush(vineID: vineID)
        return latest
    }

    func openVine(_ vineID: UUID) async throws -> Garden {
        latest = try latest.opening(vineID)
        return latest
    }

    func setOnboardingComplete(_ flag: Bool) async -> Garden {
        if flag {
            latest = latest.completingOnboarding()
        } else {
            latest.onboardingComplete = false
        }
        return latest
    }

    func flush() async throws {}

    func resetAllData() async throws {
        latest = .empty
        warning = nil
    }

    func seedDemoIfNeeded(now: Date, calendar: Calendar) async throws -> Garden? {
        _ = now
        _ = calendar
        return nil
    }
}
