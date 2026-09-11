import XCTest
@testable import Palmette

final class VineFoldTests: XCTestCase {
    func test_architecture_pourWritesFlushOnly_pinchLeaderIsTheOnlyWoodFold() throws {
        var vine = try Vine.planted(name: "Espalier bike", target: 100, vineSeed: 9)
        vine = try vine.pouring(40)
        vine = try vine.pouring(10)
        XCTAssertEqual(vine.leader.flush.amount, 50)
        XCTAssertEqual(vine.leader.wood.amount, 0)
        XCTAssertTrue(vine.nodeMarks.isEmpty)
        XCTAssertEqual(vine.progress, 0)

        let pinched = vine.pinchLeader(
            now: Date(timeIntervalSince1970: 10),
            markIDs: [
                UUID(uuidString: "CCCCCCCC-0001-4000-8000-000000000001")!,
                UUID(uuidString: "CCCCCCCC-0001-4000-8000-000000000002")!,
            ]
        )
        XCTAssertEqual(pinched.leader.flush.amount, 0)
        XCTAssertEqual(pinched.leader.wood.amount, 50)
        XCTAssertEqual(pinched.progress, 0.5, accuracy: 0.000_000_1)
        XCTAssertEqual(pinched.nodeMarks.map(\.quartile), [0.25, 0.5])
        XCTAssertEqual(pinched.nodeMarks.map(\.woodAmount), [50, 50])
        XCTAssertEqual(pinched.nodeMarks.first?.id.uuidString, "CCCCCCCC-0001-4000-8000-000000000001")

        let again = pinched.pinchLeader()
        XCTAssertEqual(again, pinched, "pinch with no flush is a no-op")
    }

    func test_primaryVerb_emptyNoOp_populatedWritesNodes_invalidUnknownVine() throws {
        var garden = try Garden.empty.planting(name: "Lamp", target: 80, vineSeed: 3)
        let vineID = try XCTUnwrap(garden.openVine?.id)
        XCTAssertFalse(garden.canPinchLeader)
        let idle = try garden.pinchOpenLeader(now: Date(timeIntervalSince1970: 0))
        XCTAssertEqual(idle.nodeMarkCount, 0)
        XCTAssertEqual(idle.vines.first?.leader.wood.amount, 0)

        garden = try garden.pouringOnOpen(amount: 40, now: Date(timeIntervalSince1970: 0), calendar: Calendar(identifier: .gregorian))
        XCTAssertTrue(garden.canPinchLeader)
        garden = try garden.pinchOpenLeader(now: Date(timeIntervalSince1970: 1))
        XCTAssertEqual(garden.nodeMarkCount, 2)
        XCTAssertEqual(garden.ripeVineCount, 0)
        XCTAssertEqual(garden.vines.first?.leader.wood.amount, 40)

        XCTAssertThrowsError(try garden.pinchLeader(vineID: UUID(), now: Date())) { error in
            XCTAssertEqual(error as? VineFault, .unknownVine)
        }
        XCTAssertThrowsError(try garden.pouring(vineID: UUID(), amount: 1, now: Date(), calendar: .current)) { error in
            XCTAssertEqual(error as? VineFault, .unknownVine)
        }
        XCTAssertEqual(vineID, garden.openVineID)
    }

    func test_pourAndRetract_emptyPopulatedInvalid() throws {
        XCTAssertThrowsError(try Vine.planted(name: "  ", target: 10, vineSeed: 1)) { error in
            XCTAssertEqual(error as? VineFault, .emptyName)
        }
        XCTAssertThrowsError(try Vine.planted(name: "Cane", target: 0, vineSeed: 1)) { error in
            XCTAssertEqual(error as? VineFault, .invalidTarget)
        }
        XCTAssertThrowsError(try Vine.planted(name: "Cane", target: -4, vineSeed: 1)) { error in
            XCTAssertEqual(error as? VineFault, .invalidTarget)
        }

        var vine = try Vine.planted(name: "Cane", target: 100, vineSeed: 2)
        XCTAssertThrowsError(try vine.pouring(0)) { error in
            XCTAssertEqual(error as? VineFault, .invalidPour)
        }
        XCTAssertThrowsError(try vine.pouring(-8)) { error in
            XCTAssertEqual(error as? VineFault, .invalidPour)
        }
        XCTAssertThrowsError(try vine.pouring(.nan)) { error in
            XCTAssertEqual(error as? VineFault, .invalidPour)
        }

        vine = try vine.pouring(30)
        vine = vine.pinchLeader()
        vine = try vine.pouring(20)
        XCTAssertEqual(vine.leader.flush.amount, 20)
        XCTAssertEqual(vine.leader.wood.amount, 30)
        vine = try vine.retracting(100)
        XCTAssertEqual(vine.leader.flush.amount, 0)
        XCTAssertEqual(vine.leader.wood.amount, 30)
        XCTAssertEqual(vine.nodeMarks.count, 1)

        vine = try vine.pouring(15)
        vine = vine.retractingFlush()
        XCTAssertEqual(vine.leader.flush.amount, 0)
        XCTAssertEqual(vine.leader.wood.amount, 30)
        XCTAssertThrowsError(try vine.retracting(-1)) { error in
            XCTAssertEqual(error as? VineFault, .invalidPour)
        }
    }

    func test_twist_unpinchedFlushNeverBeads_pinchWritesNewlyReachedQuartiles() throws {
        var vine = try Vine.planted(name: "Trellis trip", target: 400, vineSeed: 12)
        vine = try vine.pouring(200)
        XCTAssertEqual(vine.caneFill, 0.5, accuracy: 0.000_000_1)
        XCTAssertTrue(vine.nodeMarks.isEmpty)
        XCTAssertEqual(vine.progress, 0)

        vine = vine.pinchLeader()
        XCTAssertEqual(vine.nodeMarks.map(\.quartile), [0.25, 0.5])
        XCTAssertEqual(vine.progress, 0.5, accuracy: 0.000_000_1)

        vine = try vine.pouring(99)
        XCTAssertEqual(vine.nodeMarks.count, 2, "a halfway-looking cane still does not bead until pinch")
        vine = vine.pinchLeader()
        XCTAssertEqual(vine.leader.wood.amount, 299)
        XCTAssertEqual(vine.nodeMarks.map(\.quartile), [0.25, 0.5])

        vine = try vine.pouring(101).pinchLeader()
        XCTAssertEqual(vine.nodeMarks.map(\.quartile), [0.25, 0.5, 0.75, 1.0])
        XCTAssertTrue(vine.isRipe)
        XCTAssertEqual(vine.progress, 1.0, accuracy: 0.000_000_1)
    }

    func test_seedLeavesPinchEnabledAndFillsWoodAndNodes() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let now = Date(timeIntervalSince1970: 1_788_000_000)
        let garden = try VineSeed.garden(now: now, calendar: calendar)
        XCTAssertTrue(garden.onboardingComplete)
        XCTAssertGreaterThanOrEqual(garden.vines.count, 4)
        XCTAssertTrue(garden.canPinchLeader)
        XCTAssertGreaterThan(garden.openVine?.leader.flush.amount ?? 0, 0)
        XCTAssertGreaterThan(garden.nodeMarkCount, 0)
        XCTAssertGreaterThanOrEqual(garden.ripeVineCount, 1)
        XCTAssertGreaterThan(garden.pourCount, 1)
        XCTAssertEqual(Set(garden.vines.map(\.vineSeed)).count, garden.vines.count)
        XCTAssertEqual(garden.openVine?.name, "Weekend glass")
        XCTAssertGreaterThan(garden.poursByDay.keys.count, 1)
    }

    func test_analyticsCountsNodeMarksAndRipeVinesNotPours() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let now = Date(timeIntervalSince1970: 0)
        var garden = try Garden.empty.planting(name: "Fare", target: 40, vineSeed: 1)
        let id = try XCTUnwrap(garden.openVine?.id)
        garden = try garden.pouring(vineID: id, amount: 10, now: now, calendar: calendar)
        garden = try garden.pouring(vineID: id, amount: 10, now: now, calendar: calendar)
        XCTAssertEqual(garden.pourCount, 2)
        XCTAssertEqual(garden.nodeMarkCount, 0)
        XCTAssertEqual(garden.ripeVineCount, 0)
        garden = try garden.pinchLeader(vineID: id, now: now)
        XCTAssertEqual(garden.nodeMarkCount, 2)
        XCTAssertEqual(garden.ripeVineCount, 0)
        garden = try garden.pouring(vineID: id, amount: 20, now: now, calendar: calendar)
        garden = try garden.pinchLeader(vineID: id, now: now)
        XCTAssertEqual(garden.ripeVineCount, 1)
        XCTAssertEqual(garden.nodeMarkCount, 4)
        XCTAssertEqual(garden.pourCount, 3)
    }
}
