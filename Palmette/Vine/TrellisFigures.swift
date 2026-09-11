import Foundation

/// Role: Vine. Locale figures for Wood, Flush, target, and NodeMark counts. Round only at display.
enum TrellisFigures {
    static func money(_ value: Double, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: value)) ?? "—"
    }

    static func count(_ value: Int, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: value)) ?? "—"
    }

    static func percent(_ value: Double, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        formatter.usesGroupingSeparator = false
        return formatter.string(from: NSNumber(value: value)) ?? "—"
    }

    static func quartile(_ value: Double, locale: Locale = .current) -> String {
        percent(value, locale: locale)
    }

    static func parseDecimal(_ raw: String, locale: Locale = .current) -> Double? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        guard let value = formatter.number(from: trimmed)?.doubleValue else { return nil }
        guard value.isFinite, value > 0 else { return nil }
        return value
    }

    static func sanitizeDecimal(_ raw: String, locale: Locale = .current) -> String {
        let separator = locale.decimalSeparator ?? "."
        var seenSeparator = false
        var out = ""
        for character in raw {
            if character.isNumber {
                out.append(character)
            } else if String(character) == separator || character == "." || character == "," {
                guard !seenSeparator else { continue }
                seenSeparator = true
                out.append(contentsOf: separator)
            }
        }
        return out
    }

    static func seed(for name: String, existing: [Int]) -> Int {
        let scalars = name.unicodeScalars.reduce(into: 0) { partial, scalar in
            partial = partial &+ Int(scalar.value) &* 33
        }
        var value = abs(scalars) % 7919 + 211
        var step = 0
        while existing.contains(value), step < 240 {
            value = 211 + (value + 97) % 7919
            step += 1
        }
        return value
    }
}
