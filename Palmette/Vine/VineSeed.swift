import Foundation

/// Role: Vine. Simulator demo garden. Device never writes this. Key: pmt.demo.v1.
enum VineSeed {
    private static func fixed(_ value: String) -> UUID {
        UUID(uuidString: value) ?? UUID()
    }

    static func garden(now: Date = Date(), calendar: Calendar = .current) throws -> Garden {
        var next = Garden.empty.completingOnboarding()

        let fare = fixed("AAAAAAAA-0001-4000-8000-000000000001")
        let boots = fixed("AAAAAAAA-0001-4000-8000-000000000002")
        let lamp = fixed("AAAAAAAA-0001-4000-8000-000000000003")
        let weekend = fixed("AAAAAAAA-0001-4000-8000-000000000004")

        next = try next.planting(name: "Train fare", target: 240, vineSeed: 1103, id: fare)
        next = try next.pouring(
            vineID: fare,
            amount: 240,
            now: now.addingTimeInterval(-86_400 * 6),
            calendar: calendar,
            pourID: fixed("BBBBBBBB-0001-4000-8000-000000000001")
        )
        next = try next.pinchLeader(vineID: fare, now: now.addingTimeInterval(-86_400 * 6))

        next = try next.planting(name: "Cordon boots", target: 1_600, vineSeed: 2241, id: boots)
        next = try next.pouring(
            vineID: boots,
            amount: 400,
            now: now.addingTimeInterval(-86_400 * 4),
            calendar: calendar,
            pourID: fixed("BBBBBBBB-0001-4000-8000-000000000002")
        )
        next = try next.pinchLeader(vineID: boots, now: now.addingTimeInterval(-86_400 * 4))
        next = try next.pouring(
            vineID: boots,
            amount: 400,
            now: now.addingTimeInterval(-86_400 * 2),
            calendar: calendar,
            pourID: fixed("BBBBBBBB-0001-4000-8000-000000000003")
        )
        next = try next.pinchLeader(vineID: boots, now: now.addingTimeInterval(-86_400 * 2))

        next = try next.planting(name: "Espalier lamp", target: 900, vineSeed: 3088, id: lamp)
        next = try next.pouring(
            vineID: lamp,
            amount: 225,
            now: now.addingTimeInterval(-86_400),
            calendar: calendar,
            pourID: fixed("BBBBBBBB-0001-4000-8000-000000000004")
        )
        next = try next.pinchLeader(vineID: lamp, now: now.addingTimeInterval(-86_400))

        next = try next.planting(name: "Weekend glass", target: 400, vineSeed: 4417, id: weekend)
        next = try next.pouring(
            vineID: weekend,
            amount: 100,
            now: now.addingTimeInterval(-3_600),
            calendar: calendar,
            pourID: fixed("BBBBBBBB-0001-4000-8000-000000000005")
        )
        next = try next.pinchLeader(vineID: weekend, now: now.addingTimeInterval(-3_600))
        next = try next.pouring(
            vineID: weekend,
            amount: 85,
            now: now,
            calendar: calendar,
            pourID: fixed("BBBBBBBB-0001-4000-8000-000000000006")
        )
        next = try next.opening(weekend)
        return next
    }
}
