import XCTest
@testable import Palmette

final class FamilyInvariantTests: XCTestCase {
    func test_familyInvariant_progressIsWoodOverTarget_quartiles_vineSeed_manualOnly() throws {
        XCTAssertEqual(CaneQuartile.milestoneRatios, [0.25, 0.5, 0.75, 1.0])
        XCTAssertEqual(CaneQuartile.allCases.count, 4)

        var vine = try Vine.planted(name: "Cordon pot", target: 200, vineSeed: 4417)
        XCTAssertEqual(vine.vineSeed, 4417)
        XCTAssertEqual(vine.progress, 0)
        XCTAssertEqual(vine.caneFill, 0)

        vine = try vine.pouring(50)
        XCTAssertEqual(vine.leader.flush.amount, 50)
        XCTAssertEqual(vine.leader.wood.amount, 0)
        XCTAssertEqual(vine.progress, 0, "progress ignores Flush; current is Wood")
        XCTAssertEqual(vine.caneFill, 0.25, accuracy: 0.000_000_1)
        XCTAssertTrue(vine.nodeMarks.isEmpty, "unpinched flush never beads a node")

        vine = vine.pinchLeader(now: Date(timeIntervalSince1970: 1_700_000_000))
        XCTAssertEqual(vine.leader.flush.amount, 0)
        XCTAssertEqual(vine.leader.wood.amount, 50)
        XCTAssertEqual(vine.progress, 0.25, accuracy: 0.000_000_1)
        XCTAssertEqual(vine.nodeMarks.map(\.quartile), [0.25])
        XCTAssertEqual(vine.vineSeed, 4417, "vineSeed is stable and drives cane shape later")

        vine = try vine.pouring(50)
        XCTAssertEqual(vine.progress, 0.25, accuracy: 0.000_000_1)
        XCTAssertEqual(vine.caneFill, 0.5, accuracy: 0.000_000_1)
        XCTAssertEqual(vine.nodeMarks.count, 1)

        vine = vine.pinchLeader()
        XCTAssertEqual(vine.progress, 0.5, accuracy: 0.000_000_1)
        XCTAssertEqual(vine.nodeMarks.map(\.quartile), [0.25, 0.5])

        vine = try vine.pouring(50).pinchLeader()
        XCTAssertEqual(vine.progress, 0.75, accuracy: 0.000_000_1)
        vine = try vine.pouring(50).pinchLeader()
        XCTAssertEqual(vine.progress, 1.0, accuracy: 0.000_000_1)
        XCTAssertEqual(vine.nodeMarks.map(\.quartile), [0.25, 0.5, 0.75, 1.0])
        XCTAssertTrue(vine.isRipe)

        let labels = Mirror(reflecting: Garden.empty).children.compactMap(\.label).joined(separator: ",")
        XCTAssertFalse(labels.localizedCaseInsensitiveContains("bank"))
        XCTAssertFalse(labels.localizedCaseInsensitiveContains("plaid"))
        XCTAssertFalse(labels.localizedCaseInsensitiveContains("routing"))
        XCTAssertEqual(EspalierClient.contactURL.host, "palmette-vine.pro")
        XCTAssertFalse(EspalierClient.userAgent.localizedCaseInsensitiveContains("bank"))
    }

    func test_gardenSumsWoodAndWaitingFlush() throws {
        let garden = try VineSeed.garden()
        XCTAssertEqual(
            garden.woodAmount,
            garden.vines.reduce(0) { $0 + $1.leader.wood.amount }
        )
        XCTAssertEqual(
            garden.flushAmount,
            garden.vines.reduce(0) { $0 + $1.leader.flush.amount }
        )
        XCTAssertGreaterThan(garden.woodAmount, 0)
        XCTAssertEqual(garden.flushAmount, 85, accuracy: 0.000_000_1)
    }

    func test_familyInvariant_quartileCrossingsUseEachVineTarget() throws {
        var small = try Vine.planted(name: "Small cordon", target: 100, vineSeed: 1)
        var large = try Vine.planted(name: "Large palmette", target: 1_000, vineSeed: 2)
        small = try small.pouring(250).pinchLeader()
        large = try large.pouring(250).pinchLeader()
        XCTAssertEqual(small.progress, 2.5, accuracy: 0.000_000_1)
        XCTAssertEqual(small.nodeMarks.map(\.quartile), [0.25, 0.5, 0.75, 1.0])
        XCTAssertEqual(large.progress, 0.25, accuracy: 0.000_000_1)
        XCTAssertEqual(large.nodeMarks.map(\.quartile), [0.25])
        XCTAssertEqual(
            CaneQuartile.newlyReached(beforeWood: 0, afterWood: 249, target: 1_000),
            []
        )
        XCTAssertEqual(
            CaneQuartile.newlyReached(beforeWood: 0, afterWood: 250, target: 1_000),
            [.quarter]
        )
    }
}
