import XCTest
@testable import Palmette

final class PalmetteTests: XCTestCase {
    func test_appModuleImports() {
        XCTAssertEqual(String(describing: PalmetteApp.self), "PalmetteApp")
        XCTAssertEqual(VineKey.snapshot, "pmt.garden.v1")
        XCTAssertEqual(VineKey.demo, "pmt.demo.v1")
        XCTAssertEqual(TrellisInk.face, "SF Pro")
        XCTAssertEqual(TrellisInk.Hex.background, "#FBF5F4")
        XCTAssertEqual(TrellisInk.Hex.surface, "#FEFEFD")
        XCTAssertEqual(TrellisInk.Hex.ink, "#391F18")
        XCTAssertEqual(TrellisInk.Hex.accent, "#CF3C17")
        XCTAssertEqual(TrellisInk.Hex.muted, "#90655B")
        XCTAssertEqual(TrellisFace.Step.allCases.count, 6)
        XCTAssertEqual(TrellisRail.cardRadius, 24)
        XCTAssertEqual(TrellisRail.chipRadius, 14)
        XCTAssertEqual(TrellisRail.unit, 8)
        XCTAssertEqual(TrellisRail.tap, 44)
        XCTAssertEqual(String(describing: AnalyticsView.self), "AnalyticsView")
        XCTAssertEqual(String(describing: SettingsView.self), "SettingsView")
    }
}
