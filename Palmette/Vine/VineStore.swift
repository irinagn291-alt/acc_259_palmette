import Foundation

/// Role: Vine. The only persistence seam. Views observe the garden; they never touch UserDefaults or files.
protocol VineStoring: Sendable {
    func load() async -> (garden: Garden, warning: GardenWarning?)
    func snapshot() async -> Garden
    func plant(name: String, target: Double, vineSeed: Int) async throws -> Garden
    func pour(vineID: UUID, amount: Double, now: Date, calendar: Calendar) async throws -> Garden
    func pinchLeader(vineID: UUID, now: Date) async throws -> Garden
    func retract(vineID: UUID, amount: Double) async throws -> Garden
    func retractFlush(vineID: UUID) async throws -> Garden
    func openVine(_ vineID: UUID) async throws -> Garden
    func setOnboardingComplete(_ flag: Bool) async -> Garden
    func flush() async throws
    func resetAllData() async throws
    func seedDemoIfNeeded(now: Date, calendar: Calendar) async throws -> Garden?
}

/// Role: Vine. Memory is the source of truth. UserDefaults pmt.garden.v1 plus an Application Support file are projections.
actor VineStore: VineStoring {
    private let directory: URL
    private let defaultsSuiteName: String?
    private let fileManager: FileManager
    private let writeDelayNanoseconds: UInt64

    private var latest: Garden = .empty
    private var dirty = false
    private var writeTask: Task<Void, Never>?
    private(set) var warning: GardenWarning?
    private(set) var lastWriteError: String?

    init(
        directory: URL,
        defaultsSuiteName: String? = nil,
        fileManager: FileManager = .default,
        writeDelayNanoseconds: UInt64 = 300_000_000
    ) {
        self.directory = directory
        self.defaultsSuiteName = defaultsSuiteName
        self.fileManager = fileManager
        self.writeDelayNanoseconds = writeDelayNanoseconds
    }

    static func applicationSupportDirectory(fileManager: FileManager = .default) throws -> URL {
        let root = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return root.appendingPathComponent("Palmette", isDirectory: true)
    }

    func load() async -> (garden: Garden, warning: GardenWarning?) {
        warning = nil
        latest = .empty
        dirty = false
        let defaults = preferenceDefaults()
        if let garden = decode(defaults.data(forKey: VineKey.snapshot)) {
            latest = garden
            return (latest, nil)
        }
        if let garden = decodeFile(fileURL) {
            latest = garden
            return (latest, nil)
        }
        if let garden = decode(defaults.data(forKey: VineKey.backup)) {
            latest = garden
            warning = .recoveredFromBackup
            return (latest, warning)
        }
        if let garden = decodeFile(backupURL) {
            latest = garden
            warning = .recoveredFromBackup
            return (latest, warning)
        }
        let hadPayload = defaults.data(forKey: VineKey.snapshot) != nil
            || fileManager.fileExists(atPath: fileURL.path)
        if hadPayload {
            warning = .startedEmpty
        }
        return (latest, warning)
    }

    func snapshot() async -> Garden {
        latest
    }

    func plant(name: String, target: Double, vineSeed: Int) async throws -> Garden {
        try Task.checkCancellation()
        latest = try latest.planting(name: name, target: target, vineSeed: vineSeed)
        try persistCommitted()
        return latest
    }

    func pour(vineID: UUID, amount: Double, now: Date = Date(), calendar: Calendar = .current) async throws -> Garden {
        try Task.checkCancellation()
        latest = try latest.pouring(vineID: vineID, amount: amount, now: now, calendar: calendar)
        try persistCommitted()
        return latest
    }

    func pinchLeader(vineID: UUID, now: Date = Date()) async throws -> Garden {
        try Task.checkCancellation()
        latest = try latest.pinchLeader(vineID: vineID, now: now)
        try persistCommitted()
        return latest
    }

    func retract(vineID: UUID, amount: Double) async throws -> Garden {
        try Task.checkCancellation()
        latest = try latest.retracting(vineID: vineID, amount: amount)
        try persistCommitted()
        return latest
    }

    func retractFlush(vineID: UUID) async throws -> Garden {
        try Task.checkCancellation()
        latest = try latest.retractingFlush(vineID: vineID)
        try persistCommitted()
        return latest
    }

    func openVine(_ vineID: UUID) async throws -> Garden {
        try Task.checkCancellation()
        latest = try latest.opening(vineID)
        try persistCommitted()
        return latest
    }

    func setOnboardingComplete(_ flag: Bool) async -> Garden {
        if flag {
            latest = latest.completingOnboarding()
        } else {
            latest.onboardingComplete = false
        }
        dirty = true
        scheduleFlush()
        return latest
    }

    func flush() async throws {
        writeTask?.cancel()
        writeTask = nil
        if dirty {
            try persistCommitted()
        }
    }

    func resetAllData() async throws {
        writeTask?.cancel()
        writeTask = nil
        latest = .empty
        dirty = false
        warning = nil
        lastWriteError = nil
        let defaults = preferenceDefaults()
        defaults.removeObject(forKey: VineKey.snapshot)
        defaults.removeObject(forKey: VineKey.backup)
        if fileManager.fileExists(atPath: directory.path) {
            try fileManager.removeItem(at: directory)
        }
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    func seedDemoIfNeeded(now: Date = Date(), calendar: Calendar = .current) async throws -> Garden? {
        #if targetEnvironment(simulator)
        let defaults = preferenceDefaults()
        guard defaults.object(forKey: VineKey.demo) == nil else { return nil }
        latest = try VineSeed.garden(now: now, calendar: calendar)
        try persistCommitted()
        defaults.set(true, forKey: VineKey.demo)
        return latest
        #else
        _ = now
        _ = calendar
        return nil
        #endif
    }

    /// File IO stays on this actor, which is not MainActor — the main thread never waits on disk.
    private func persistCommitted() throws {
        let document = GardenCodec.committed(from: latest)
        let data = try GardenCodec.encode(document)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let defaults = preferenceDefaults()
        if fileManager.fileExists(atPath: fileURL.path) {
            if fileManager.fileExists(atPath: backupURL.path) {
                try? fileManager.removeItem(at: backupURL)
            }
            try? fileManager.copyItem(at: fileURL, to: backupURL)
        }
        try data.write(to: fileURL, options: .atomic)
        if let previous = defaults.data(forKey: VineKey.snapshot) {
            defaults.set(previous, forKey: VineKey.backup)
        }
        defaults.set(data, forKey: VineKey.snapshot)
        dirty = false
        lastWriteError = nil
    }

    private func scheduleFlush() {
        writeTask?.cancel()
        let delay = writeDelayNanoseconds
        writeTask = Task { [weak self] in
            if delay > 0 {
                try? await Task.sleep(nanoseconds: delay)
            }
            guard !Task.isCancelled else { return }
            await self?.flushIfNeeded()
        }
    }

    private func flushIfNeeded() async {
        writeTask = nil
        do {
            if dirty {
                try persistCommitted()
            }
        } catch {
            lastWriteError = String(describing: error)
        }
    }

    private func decode(_ data: Data?) -> Garden? {
        guard let data, let document = try? GardenCodec.decode(data) else { return nil }
        return document.garden
    }

    private func decodeFile(_ url: URL) -> Garden? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return decode(data)
    }

    private var fileURL: URL {
        directory.appendingPathComponent("garden.json")
    }

    private var backupURL: URL {
        directory.appendingPathComponent("garden.json.backup")
    }

    private func preferenceDefaults() -> UserDefaults {
        if let defaultsSuiteName {
            return UserDefaults(suiteName: defaultsSuiteName) ?? .standard
        }
        return .standard
    }
}
