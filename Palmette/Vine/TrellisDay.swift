import Foundation

/// Role: Vine. Pour-log day as Int YYYYMMDD from Calendar.startOfDay. Never a Date dictionary key.
struct TrellisDay: RawRepresentable, Hashable, Sendable, Codable, Comparable {
    let rawValue: Int

    init(rawValue: Int) {
        self.rawValue = rawValue
    }

    static func from(_ date: Date, calendar: Calendar) -> TrellisDay {
        let start = calendar.startOfDay(for: date)
        let parts = calendar.dateComponents([.year, .month, .day], from: start)
        let year = parts.year ?? 1970
        let month = parts.month ?? 1
        let day = parts.day ?? 1
        return TrellisDay(rawValue: year * 10_000 + month * 100 + day)
    }

    static func < (lhs: TrellisDay, rhs: TrellisDay) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
