import XCTest
@testable import Palmette

final class GardenLaunchTests: XCTestCase {
    func test_readsOnceAfterOnboarding() {
        var consumed = false
        XCTAssertNil(
            GardenLaunch.consume(
                arguments: ["-ReviewScreen", "log"],
                onboardingComplete: false,
                consumed: &consumed
            )
        )
        XCTAssertFalse(consumed)

        let first = GardenLaunch.consume(
            arguments: ["app", "-ReviewScreen", "log"],
            onboardingComplete: true,
            consumed: &consumed
        )
        XCTAssertEqual(first, .log)
        XCTAssertEqual(first?.tab, .analytics)
        XCTAssertTrue(consumed)
        XCTAssertNil(
            GardenLaunch.consume(
                arguments: ["-ReviewScreen", "goals"],
                onboardingComplete: true,
                consumed: &consumed
            )
        )
    }

    func test_threeKeysAreDistinctScreens() {
        XCTAssertEqual(GardenPane.today.rawValue, "today")
        XCTAssertEqual(GardenPane.log.rawValue, "log")
        XCTAssertEqual(GardenPane.goals.rawValue, "goals")
        XCTAssertNotEqual(GardenPane.today, GardenPane.log)
        XCTAssertNotEqual(GardenPane.log, GardenPane.goals)
        XCTAssertNotEqual(GardenPane.today, GardenPane.goals)
        XCTAssertEqual(GardenPane.today.tab, .garden)
        XCTAssertEqual(GardenPane.log.tab, .analytics)
        XCTAssertEqual(GardenPane.goals.tab, .settings)
        XCTAssertNotEqual(GardenPane.today.tab, GardenPane.log.tab)
        XCTAssertNotEqual(GardenPane.log.tab, GardenPane.goals.tab)
        XCTAssertNotEqual(GardenPane.today.tab, GardenPane.goals.tab)
        XCTAssertEqual(GardenTab.allCases.map(\.rawValue), ["garden", "analytics", "settings"])
        XCTAssertFalse(GardenTab.allCases.map(\.rawValue).contains("game"))
        XCTAssertFalse(GardenTab.allCases.map(\.rawValue).contains("plot"))

        var consumed = false
        XCTAssertEqual(
            GardenLaunch.consume(
                arguments: ["-ReviewScreen", "today"],
                onboardingComplete: true,
                consumed: &consumed
            ),
            .today
        )
        consumed = false
        XCTAssertEqual(
            GardenLaunch.consume(
                arguments: ["-ReviewScreen", "goals"],
                onboardingComplete: true,
                consumed: &consumed
            ),
            .goals
        )
    }

    func test_unknownKeyIsIgnored() {
        var consumed = false
        XCTAssertNil(
            GardenLaunch.consume(
                arguments: ["-ReviewScreen", "aura"],
                onboardingComplete: true,
                consumed: &consumed
            )
        )
        XCTAssertTrue(consumed)
    }
}
