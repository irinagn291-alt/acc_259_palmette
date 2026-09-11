import Foundation

/// Role: Flush. Unlignified pours sitting on the leader. A Pour writes here only; Flush is not Wood and never beads a NodeMark.
struct Flush: Equatable, Sendable {
    var amount: Double

    static let none = Flush(amount: 0)

    var isEmpty: Bool { amount <= 0 || !amount.isFinite }

    func adding(_ pour: Double) throws -> Flush {
        guard pour.isFinite, pour > 0 else { throw VineFault.invalidPour }
        return Flush(amount: amount + pour)
    }

    func peeling(_ pour: Double) throws -> Flush {
        guard pour.isFinite, pour > 0 else { throw VineFault.invalidPour }
        return Flush(amount: max(0, amount - pour))
    }
}
