import XCTest
@testable import Palmette

@MainActor
final class GardenWatchTests: XCTestCase {
    func test_pourWritesFlushOnly_pinchWritesNodes() async throws {
        let watch = GardenWatch(
            store: VineHold(garden: .empty),
            garden: .empty,
            shouldLoad: false
        )
        await watch.finishOnboarding()
        await watch.plant(name: "Cordon lamp", target: 200)
        XCTAssertNil(watch.fault)
        XCTAssertEqual(watch.garden.vines.count, 1)
        await watch.pour(amount: 50)
        XCTAssertEqual(watch.openVine?.leader.flush.amount, 50)
        XCTAssertEqual(watch.openVine?.leader.wood.amount, 0)
        XCTAssertEqual(watch.garden.nodeMarkCount, 0)
        XCTAssertTrue(watch.canPinchLeader)
        await watch.pinchLeader()
        XCTAssertEqual(watch.openVine?.leader.flush.amount, 0)
        XCTAssertEqual(watch.openVine?.leader.wood.amount, 50)
        XCTAssertEqual(watch.garden.nodeMarkCount, 1)
        XCTAssertEqual(try XCTUnwrap(watch.openVine).progress, 0.25, accuracy: 0.000_000_1)
    }

    func test_invalidPourSetsFault_retractPeelsFlushOnly() async throws {
        var garden = try Garden.empty.completingOnboarding().planting(name: "Boots", target: 80, vineSeed: 4)
        let vineID = try XCTUnwrap(garden.openVine?.id)
        garden = try garden.pouring(vineID: vineID, amount: 20, now: Date(), calendar: .current)
        let watch = GardenWatch(
            store: VineHold(garden: garden),
            garden: garden,
            shouldLoad: false
        )
        await watch.pour(amount: -4)
        XCTAssertEqual(watch.fault, "Pour a positive amount.")
        XCTAssertEqual(watch.openVine?.leader.flush.amount, 20)
        await watch.retractFlush()
        XCTAssertEqual(watch.openVine?.leader.flush.amount, 0)
        XCTAssertEqual(watch.openVine?.leader.wood.amount, 0)
    }

    func test_applyReviewThreeKeys_afterOnboarding() {
        let garden = Garden.empty.completingOnboarding()
        let watch = GardenWatch(
            store: VineHold(garden: garden),
            garden: garden,
            shouldLoad: false
        )
        watch.applyReview(arguments: ["-ReviewScreen", "today"])
        XCTAssertEqual(watch.tab, .garden)
        watch.applyReview(arguments: ["-ReviewScreen", "log"])
        XCTAssertEqual(watch.tab, .garden, "consume once")

        let second = GardenWatch(
            store: VineHold(garden: garden),
            garden: garden,
            shouldLoad: false
        )
        second.applyReview(arguments: ["-ReviewScreen", "log"])
        XCTAssertEqual(second.tab, .analytics)

        let third = GardenWatch(
            store: VineHold(garden: garden),
            garden: garden,
            shouldLoad: false
        )
        third.applyReview(arguments: ["-ReviewScreen", "goals"])
        XCTAssertEqual(third.tab, .settings)

        third.tab = .garden
        third.applyReview(arguments: ["-ReviewScreen", "log"])
        XCTAssertEqual(third.tab, .settings, "stored pane reapplies after chrome mounts")
    }

    func test_applyReviewIgnoredUntilOnboarding() {
        let watch = GardenWatch(
            store: VineHold(garden: .empty),
            garden: .empty,
            shouldLoad: false
        )
        watch.applyReview(arguments: ["-ReviewScreen", "log"])
        XCTAssertEqual(watch.tab, .garden)
        XCTAssertFalse(watch.onboardingComplete)
    }

    func test_seededHomeNamesTheJobAndEnablesPinch() throws {
        let garden = try VineSeed.garden()
        let watch = GardenWatch(
            store: VineHold(garden: garden),
            garden: garden,
            shouldLoad: false
        )
        XCTAssertTrue(watch.onboardingComplete)
        XCTAssertTrue(watch.canPinchLeader)
        XCTAssertEqual(watch.jobTitle, "Pinch the leader")
        XCTAssertTrue(watch.jobLine.contains("Pinch the leader"))
        XCTAssertTrue(watch.jobLine.contains("Weekend glass"))
        XCTAssertFalse(watch.isFreshGarden)
        XCTAssertEqual(watch.tab, .garden)
        XCTAssertGreaterThan(watch.garden.nodeMarkCount, 0)
        XCTAssertGreaterThan(watch.openVine?.leader.flush.amount ?? 0, 0)
    }

    func test_openOnGardenSelectsVineAndLeavesAnalytics() async throws {
        let garden = try VineSeed.garden()
        let watch = GardenWatch(
            store: VineHold(garden: garden),
            garden: garden,
            shouldLoad: false
        )
        watch.tab = .analytics
        let fare = try XCTUnwrap(garden.vines.first)
        XCTAssertEqual(fare.name, "Train fare")
        await watch.openOnGarden(fare.id)
        XCTAssertEqual(watch.tab, .garden)
        XCTAssertEqual(watch.openVine?.id, fare.id)
        XCTAssertEqual(watch.openVine?.name, "Train fare")
    }

    func test_pinchWithNoFlushIsNoOp() async throws {
        let garden = try Garden.empty.completingOnboarding().planting(name: "Fare", target: 40, vineSeed: 1)
        let watch = GardenWatch(
            store: VineHold(garden: garden),
            garden: garden,
            shouldLoad: false
        )
        XCTAssertFalse(watch.canPinchLeader)
        let tick = watch.commitTick
        await watch.pinchLeader()
        XCTAssertEqual(watch.commitTick, tick)
        XCTAssertEqual(watch.garden.nodeMarkCount, 0)
    }

    func test_figureParseRejectsNonPositive() {
        XCTAssertNil(TrellisFigures.parseDecimal("-2"))
        XCTAssertNil(TrellisFigures.parseDecimal("abc"))
        XCTAssertNil(TrellisFigures.parseDecimal("0"))
        let separator = Locale.current.decimalSeparator ?? "."
        XCTAssertEqual(TrellisFigures.parseDecimal("80\(separator)5"), 80.5)
        XCTAssertEqual(TrellisFigures.sanitizeDecimal("12a3"), "123")
        XCTAssertNotEqual(TrellisFigures.money(1_200), "—")
        XCTAssertFalse(TrellisFigures.money(1_200).isEmpty)
        XCTAssertNotEqual(TrellisFigures.count(4), "—")
        XCTAssertFalse(TrellisFigures.count(4).isEmpty)
        XCTAssertNotEqual(
            PalmetteFanLayout.headingRadians(seed: 1103, index: 0, count: 4),
            PalmetteFanLayout.headingRadians(seed: 4417, index: 0, count: 4)
        )
        XCTAssertNotEqual(
            PalmetteFanLayout.bow(seed: 1103),
            PalmetteFanLayout.bow(seed: 4417)
        )
        XCTAssertEqual(
            TrellisFigures.seed(for: "Lamp", existing: []),
            TrellisFigures.seed(for: "Lamp", existing: [])
        )
        XCTAssertNotEqual(
            TrellisFigures.seed(for: "Lamp", existing: []),
            TrellisFigures.seed(for: "Boots", existing: [])
        )
    }

    func test_fanFillsTallCanvasAndKeepsTipsInside() throws {
        let vine = try Vine.planted(name: "Weekend glass", target: 400, vineSeed: 4417)
        let size = CGSize(width: 420, height: 920)
        let canes = (0..<4).map {
            PalmetteFanLayout.cane(vine: vine, index: $0, count: 4, size: size)
        }
        let xs = canes.map(\.targetTip.x)
        let ys = canes.map(\.targetTip.y)
        XCTAssertGreaterThan(xs.min() ?? 0, 8)
        XCTAssertLessThan(xs.max() ?? size.width, size.width - 8)
        XCTAssertGreaterThan(ys.min() ?? 0, 8)
        XCTAssertLessThan(ys.max() ?? size.height, size.height - 8)
        XCTAssertLessThan(ys.min() ?? size.height, size.height * 0.22)
        XCTAssertLessThan(xs.min() ?? size.width, size.width * 0.22)
        XCTAssertGreaterThan(xs.max() ?? 0, size.width * 0.78)
    }
}
