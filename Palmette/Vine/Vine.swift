import Foundation

/// Role: Vine. Aggregate for one planted goal: name, target, stable vineSeed, Leader (Flush + Wood), and NodeMarks. SavingGoal in this lexicon.
struct Vine: Equatable, Sendable, Identifiable {
    var id: UUID
    var name: String
    var target: Double
    var vineSeed: Int
    var leader: Leader
    var nodeMarks: [NodeMark]

    /// progress = wood / target. Flush never enters this ratio.
    var progress: Double {
        guard target.isFinite, target > 0 else { return 0 }
        let wood = leader.wood.amount
        guard wood.isFinite, wood >= 0 else { return 0 }
        return wood / target
    }

    /// Visual cane length includes unpinched Flush. Not progress. Not a NodeMark source.
    var caneFill: Double {
        guard target.isFinite, target > 0 else { return 0 }
        let length = leader.wood.amount + leader.flush.amount
        guard length.isFinite, length >= 0 else { return 0 }
        return length / target
    }

    var isRipe: Bool {
        target.isFinite && target > 0 && leader.wood.amount + 0.000_000_1 >= target
    }

    var canPinchLeader: Bool { leader.canPinch }

    static func planted(
        name: String,
        target: Double,
        vineSeed: Int,
        id: UUID = UUID()
    ) throws -> Vine {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw VineFault.emptyName }
        guard target.isFinite, target > 0 else { throw VineFault.invalidTarget }
        return Vine(
            id: id,
            name: trimmed,
            target: target,
            vineSeed: vineSeed,
            leader: .dormant,
            nodeMarks: []
        )
    }

    /// Writes Flush only. Wood and NodeMarks stay put because Flush is not Wood.
    func pouring(_ amount: Double) throws -> Vine {
        var next = self
        next.leader = try leader.pouring(amount)
        return next
    }

    /// The only fold that lignifies: all Flush becomes Wood, then NodeMarks for newly reached quartiles of this vine's target.
    func pinchLeader(now: Date = Date(), markIDs: [UUID] = []) -> Vine {
        guard leader.canPinch else { return self }
        let beforeWood = leader.wood.amount
        var next = self
        next.leader = leader.lignifying()
        let afterWood = next.leader.wood.amount
        let crossed = CaneQuartile.newlyReached(
            beforeWood: beforeWood,
            afterWood: afterWood,
            target: next.target
        )
        let written = now.timeIntervalSince1970
        for (index, quartile) in crossed.enumerated() {
            let markID = markIDs.indices.contains(index) ? markIDs[index] : UUID()
            next.nodeMarks.append(
                NodeMark(
                    id: markID,
                    quartile: quartile.rawValue,
                    woodAmount: afterWood,
                    writtenUnix: written
                )
            )
        }
        return next
    }

    /// Peels Flush only and floors at 0. Wood and NodeMarks stay.
    func retracting(_ amount: Double) throws -> Vine {
        var next = self
        next.leader = try leader.retracting(amount)
        return next
    }

    func retractingFlush() -> Vine {
        var next = self
        next.leader = leader.retractingFlush()
        return next
    }
}
