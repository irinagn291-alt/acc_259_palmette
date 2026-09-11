import Foundation

/// Role: Vine. One manual contribution onto a leader. The log is keyed by TrellisDay; Analytics counts NodeMarks, not these rows.
struct Pour: Equatable, Sendable, Identifiable {
    var id: UUID
    var vineID: UUID
    var amount: Double
    var day: TrellisDay
}
