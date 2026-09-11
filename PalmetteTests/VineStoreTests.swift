import XCTest
@testable import Palmette

final class VineStoreTests: XCTestCase {
    private var directory = FileManager.default.temporaryDirectory
    private var suiteName = ""
    private var defaults = UserDefaults.standard
    private var calendar = Calendar(identifier: .gregorian)
    private var now = Date(timeIntervalSince1970: 0)

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        suiteName = "pmt.test.\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        utc.locale = Locale(identifier: "en_US_POSIX")
        calendar = utc
        now = instant(2026, 9, 11)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
        if !suiteName.isEmpty {
            defaults.removePersistentDomain(forName: suiteName)
        }
    }

    func test_roundTrip_reloadPreservesWoodFlushNodesAndPourLog() async throws {
        let store = makeStore()
        _ = await store.load()
        _ = await store.setOnboardingComplete(true)
        try await store.flush()
        var garden = try await store.plant(name: "Cordon lamp", target: 200, vineSeed: 88)
        let vineID = try XCTUnwrap(garden.openVine?.id)
        garden = try await store.pour(vineID: vineID, amount: 80, now: now, calendar: calendar)
        garden = try await store.pinchLeader(vineID: vineID, now: now)
        garden = try await store.pour(vineID: vineID, amount: 25, now: now, calendar: calendar)
        XCTAssertEqual(garden.vines.first?.leader.wood.amount, 80)
        XCTAssertEqual(garden.vines.first?.leader.flush.amount, 25)
        XCTAssertEqual(garden.nodeMarkCount, 1)

        let relaunched = makeStore()
        let loaded = await relaunched.load()
        XCTAssertNil(loaded.warning)
        XCTAssertTrue(loaded.garden.onboardingComplete)
        XCTAssertEqual(loaded.garden.vines.first?.vineSeed, 88)
        XCTAssertEqual(loaded.garden.vines.first?.leader.wood.amount, 80)
        XCTAssertEqual(loaded.garden.vines.first?.leader.flush.amount, 25)
        XCTAssertEqual(loaded.garden.vines.first?.nodeMarks.map(\.quartile), [0.25])
        XCTAssertEqual(loaded.garden.pourCount, 2)
        XCTAssertEqual(try XCTUnwrap(loaded.garden.vines.first).progress, 0.4, accuracy: 0.000_000_1)
        XCTAssertNotNil(defaults.data(forKey: VineKey.snapshot))
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.appendingPathComponent("garden.json").path))
    }

    func test_corruptSnapshotFallsBackToBackup() async throws {
        let store = makeStore()
        _ = await store.load()
        let garden = try await store.plant(name: "Boots", target: 80, vineSeed: 4)
        let vineID = try XCTUnwrap(garden.openVine?.id)
        _ = try await store.pour(vineID: vineID, amount: 20, now: now, calendar: calendar)
        try await store.flush()
        if let good = defaults.data(forKey: VineKey.snapshot) {
            defaults.set(good, forKey: VineKey.backup)
        }
        let file = directory.appendingPathComponent("garden.json")
        let backup = directory.appendingPathComponent("garden.json.backup")
        if FileManager.default.fileExists(atPath: file.path) {
            try? FileManager.default.removeItem(at: backup)
            try FileManager.default.copyItem(at: file, to: backup)
        }
        defaults.set(Data("{not-json".utf8), forKey: VineKey.snapshot)
        try Data("{not-json".utf8).write(to: file)

        let loaded = await makeStore().load()
        XCTAssertEqual(loaded.warning, .recoveredFromBackup)
        XCTAssertEqual(loaded.garden.vines.first?.leader.flush.amount, 20)
        XCTAssertEqual(loaded.garden.vines.first?.name, "Boots")
    }

    func test_corruptSnapshotWithoutBackupStartsEmpty() async throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defaults.set(Data("nope".utf8), forKey: VineKey.snapshot)
        try Data("nope".utf8).write(to: directory.appendingPathComponent("garden.json"))
        let loaded = await makeStore().load()
        XCTAssertEqual(loaded.warning, .startedEmpty)
        XCTAssertTrue(loaded.garden.vines.isEmpty)
        XCTAssertFalse(loaded.garden.onboardingComplete)
    }

    func test_codecSwitchesOnSchemaVersion() throws {
        let garden = try VineSeed.garden(now: now, calendar: calendar)
        let document = GardenCodec.committed(from: garden)
        let data = try GardenCodec.encode(document)
        let decoded = try GardenCodec.decode(data)
        XCTAssertEqual(decoded.schemaVersion, 1)
        XCTAssertEqual(decoded.garden.vines.count, garden.vines.count)
        XCTAssertEqual(decoded.garden.nodeMarkCount, garden.nodeMarkCount)
        XCTAssertEqual(decoded.garden.openVine?.leader.flush.amount, garden.openVine?.leader.flush.amount)
        XCTAssertEqual(decoded.garden.pourCount, garden.pourCount)
        XCTAssertEqual(decoded.garden.vines.map(\.vineSeed), garden.vines.map(\.vineSeed))

        let future = Data("{\"schemaVersion\":99}".utf8)
        XCTAssertThrowsError(try GardenCodec.decode(future)) { error in
            XCTAssertEqual(error as? GardenCodec.Failure, .unsupportedSchema(99))
        }
        XCTAssertThrowsError(try GardenCodec.decode(Data("[]".utf8))) { error in
            XCTAssertEqual(error as? GardenCodec.Failure, .corrupt)
        }
    }

    func test_resetAllDataClearsSnapshotAndFiles() async throws {
        let store = makeStore()
        _ = await store.load()
        _ = try await store.plant(name: "Fare", target: 50, vineSeed: 1)
        try await store.resetAllData()
        let loaded = await store.load()
        XCTAssertTrue(loaded.garden.vines.isEmpty)
        XCTAssertFalse(loaded.garden.onboardingComplete)
        XCTAssertNil(defaults.data(forKey: VineKey.snapshot))
        XCTAssertNil(defaults.data(forKey: VineKey.backup))
        let leftovers = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        XCTAssertTrue(leftovers.filter { $0.pathExtension == "json" }.isEmpty)
    }

    func test_onboardingFlagDebouncesUntilFlush() async throws {
        let store = makeStore()
        _ = await store.load()
        _ = await store.setOnboardingComplete(true)
        try await store.flush()
        let loaded = await makeStore().load()
        XCTAssertTrue(loaded.garden.onboardingComplete)
    }

    func test_storePinchThenNodePersistsOnTheSeam() async throws {
        let store = makeStore()
        _ = await store.load()
        var garden = try await store.plant(name: "Trip", target: 100, vineSeed: 5)
        let vineID = try XCTUnwrap(garden.openVine?.id)
        garden = try await store.pour(vineID: vineID, amount: 50, now: now, calendar: calendar)
        XCTAssertEqual(garden.nodeMarkCount, 0)
        garden = try await store.pinchLeader(vineID: vineID, now: now)
        XCTAssertEqual(garden.nodeMarkCount, 2)
        let loaded = await makeStore().load()
        XCTAssertEqual(loaded.garden.nodeMarkCount, 2)
        XCTAssertEqual(try XCTUnwrap(loaded.garden.vines.first).progress, 0.5, accuracy: 0.000_000_1)
    }

    #if targetEnvironment(simulator)
    func test_simulatorSeedWritesOnceAndEnablesPinch() async throws {
        let store = makeStore()
        let first = try await store.seedDemoIfNeeded(now: now, calendar: calendar)
        let second = try await store.seedDemoIfNeeded(now: now, calendar: calendar)
        XCTAssertNil(second)
        XCTAssertEqual(first?.onboardingComplete, true)
        XCTAssertEqual(first?.canPinchLeader, true)
        XCTAssertGreaterThanOrEqual(first?.vines.count ?? 0, 4)
        XCTAssertGreaterThan(first?.nodeMarkCount ?? 0, 0)
        XCTAssertGreaterThan(first?.openVine?.leader.flush.amount ?? 0, 0)
        XCTAssertTrue(defaults.bool(forKey: VineKey.demo))
        XCTAssertNotNil(defaults.data(forKey: VineKey.snapshot))
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.appendingPathComponent("garden.json").path))
    }
    #endif

    private func makeStore() -> VineStore {
        VineStore(
            directory: directory,
            defaultsSuiteName: suiteName,
            writeDelayNanoseconds: 0
        )
    }

    private func instant(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var parts = DateComponents()
        parts.year = year
        parts.month = month
        parts.day = day
        parts.hour = 12
        return calendar.date(from: parts) ?? Date(timeIntervalSince1970: 0)
    }
}
