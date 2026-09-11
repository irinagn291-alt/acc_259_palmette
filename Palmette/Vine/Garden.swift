import Foundation

/// Role: Vine. In-memory garden: planted vines, the open leader, onboarding, and the YYYYMMDD pour log. VineStore is the only mutator views talk to.
struct Garden: Equatable, Sendable {
    var onboardingComplete: Bool
    var vines: [Vine]
    var openVineID: UUID?
    var poursByDay: [TrellisDay: [Pour]]

    static let empty = Garden(
        onboardingComplete: false,
        vines: [],
        openVineID: nil,
        poursByDay: [:]
    )

    var openVine: Vine? {
        if let openVineID, let match = vines.first(where: { $0.id == openVineID }) {
            return match
        }
        return vines.first
    }

    var canPinchLeader: Bool { openVine?.canPinchLeader ?? false }

    var nodeMarkCount: Int {
        vines.reduce(0) { $0 + $1.nodeMarks.count }
    }

    var ripeVineCount: Int {
        vines.filter(\.isRipe).count
    }

    var pourCount: Int {
        poursByDay.values.reduce(0) { $0 + $1.count }
    }

    var woodAmount: Double {
        vines.reduce(0) { $0 + $1.leader.wood.amount }
    }

    var flushAmount: Double {
        vines.reduce(0) { $0 + $1.leader.flush.amount }
    }

    func vine(id: UUID) -> Vine? {
        vines.first(where: { $0.id == id })
    }

    func completingOnboarding() -> Garden {
        var next = self
        next.onboardingComplete = true
        return next
    }

    func resolvingOpenVine() -> Garden {
        var next = self
        if let openVineID, next.vines.contains(where: { $0.id == openVineID }) {
            return next
        }
        next.openVineID = next.vines.first?.id
        return next
    }

    func planting(
        name: String,
        target: Double,
        vineSeed: Int,
        id: UUID = UUID()
    ) throws -> Garden {
        let vine = try Vine.planted(name: name, target: target, vineSeed: vineSeed, id: id)
        var next = self
        next.vines.append(vine)
        if next.openVineID == nil {
            next.openVineID = vine.id
        }
        return next
    }

    func opening(_ vineID: UUID) throws -> Garden {
        guard vines.contains(where: { $0.id == vineID }) else { throw VineFault.unknownVine }
        var next = self
        next.openVineID = vineID
        return next
    }

    func pouring(
        vineID: UUID,
        amount: Double,
        now: Date,
        calendar: Calendar,
        pourID: UUID = UUID()
    ) throws -> Garden {
        var next = self
        guard let index = next.vines.firstIndex(where: { $0.id == vineID }) else {
            throw VineFault.unknownVine
        }
        next.vines[index] = try next.vines[index].pouring(amount)
        let day = TrellisDay.from(now, calendar: calendar)
        let pour = Pour(id: pourID, vineID: vineID, amount: amount, day: day)
        next.poursByDay[day, default: []].append(pour)
        return next
    }

    func pouringOnOpen(
        amount: Double,
        now: Date,
        calendar: Calendar,
        pourID: UUID = UUID()
    ) throws -> Garden {
        guard let vineID = openVine?.id else { throw VineFault.unknownVine }
        return try pouring(vineID: vineID, amount: amount, now: now, calendar: calendar, pourID: pourID)
    }

    /// pinchLeader is the only fold that moves Flush into Wood and writes NodeMarks. No flush is a no-op.
    func pinchLeader(vineID: UUID, now: Date, markIDs: [UUID] = []) throws -> Garden {
        guard let index = vines.firstIndex(where: { $0.id == vineID }) else {
            throw VineFault.unknownVine
        }
        var next = self
        next.vines[index] = next.vines[index].pinchLeader(now: now, markIDs: markIDs)
        return next
    }

    func pinchOpenLeader(now: Date, markIDs: [UUID] = []) throws -> Garden {
        guard let vineID = openVine?.id else { throw VineFault.unknownVine }
        return try pinchLeader(vineID: vineID, now: now, markIDs: markIDs)
    }

    func retracting(vineID: UUID, amount: Double) throws -> Garden {
        guard let index = vines.firstIndex(where: { $0.id == vineID }) else {
            throw VineFault.unknownVine
        }
        var next = self
        next.vines[index] = try next.vines[index].retracting(amount)
        return next
    }

    func retractingFlush(vineID: UUID) throws -> Garden {
        guard let index = vines.firstIndex(where: { $0.id == vineID }) else {
            throw VineFault.unknownVine
        }
        var next = self
        next.vines[index] = next.vines[index].retractingFlush()
        return next
    }

    func retractingOpenFlush() throws -> Garden {
        guard let vineID = openVine?.id else { throw VineFault.unknownVine }
        return try retractingFlush(vineID: vineID)
    }
}
