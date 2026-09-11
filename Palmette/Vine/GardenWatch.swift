import Foundation
import Observation

/// Role: Vine. Presentation fold over VineStoring. Views observe the garden; they never touch UserDefaults.
@MainActor
@Observable
final class GardenWatch {
    private(set) var garden: Garden
    private(set) var warning: GardenWarning?
    private(set) var fault: String?
    private(set) var isHauling = false
    private(set) var isCommitting = false
    private(set) var commitTick = 0
    private(set) var pinchTick = 0
    private(set) var dayAnchor: Date

    var tab: GardenTab = .garden

    let store: any VineStoring
    private let calendar: Calendar
    private let now: @Sendable () -> Date
    private let shouldLoad: Bool
    private var appeared = false
    private var reviewConsumed = false
    private var reviewPane: GardenPane?
    private var haulToken: UUID?

    init(
        store: any VineStoring,
        calendar: Calendar = .current,
        now: @escaping @Sendable () -> Date = { Date() },
        garden: Garden = .empty,
        warning: GardenWarning? = nil,
        shouldLoad: Bool = true
    ) {
        self.store = store
        self.calendar = calendar
        self.now = now
        self.garden = garden
        self.warning = warning
        self.shouldLoad = shouldLoad
        self.dayAnchor = calendar.startOfDay(for: now())
    }

    var today: TrellisDay {
        TrellisDay.from(dayAnchor, calendar: calendar)
    }

    var onboardingComplete: Bool {
        garden.onboardingComplete
    }

    var loadFailed: Bool {
        warning == .startedEmpty
    }

    var isFreshGarden: Bool {
        garden.vines.isEmpty
    }

    var openVine: Vine? {
        garden.openVine
    }

    var canPinchLeader: Bool {
        garden.canPinchLeader
    }

    var canRetract: Bool {
        (openVine?.leader.flush.amount ?? 0) > 0
    }

    var jobTitle: String {
        if openVine?.isRipe == true, !canPinchLeader {
            return "Wood reached the target"
        }
        if canPinchLeader {
            return "Pinch the leader"
        }
        if openVine != nil {
            return "Pour onto the leader"
        }
        return "Plant a vine"
    }

    var jobLine: String {
        if let vine = openVine, vine.isRipe, !canPinchLeader {
            return "\(vine.name) is ripe. Wood holds the target. Plant another goal whenever you like."
        }
        if canPinchLeader, let vine = openVine {
            return "\(vine.name) has cash waiting. Pinch the leader to lock it into wood and write node beads."
        }
        if let vine = openVine {
            return "Add cash onto \(vine.name). Wood and beads stay put until you pinch."
        }
        return "Plant a named goal, then pour cash and pinch the leader on this garden."
    }

    var pinchDetail: String {
        guard let vine = openVine else { return "Pick a vine first." }
        if !canPinchLeader {
            return "No waiting cash on \(vine.name). Pour first."
        }
        return "Moves waiting cash into wood and beads every quarter \(vine.name) newly reaches."
    }

    func appear() async {
        guard shouldLoad else {
            applyReview()
            return
        }
        if appeared {
            applyReview()
            return
        }
        appeared = true
        let token = UUID()
        haulToken = token
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 150_000_000)
            guard let self, self.haulToken == token else { return }
            self.isHauling = true
        }
        let loaded = await store.load()
        garden = loaded.garden
        warning = loaded.warning
        do {
            if let seeded = try await store.seedDemoIfNeeded(now: now(), calendar: calendar) {
                garden = seeded
                warning = nil
            }
        } catch {
            fault = "The garden could not be opened."
        }
        applyWarning()
        applyReview()
        haulToken = nil
        isHauling = false
    }

    func retry() async {
        fault = nil
        appeared = false
        await appear()
    }

    func flush() async {
        do {
            try await store.flush()
        } catch {
            fault = "The garden could not be written."
        }
    }

    func markDay() {
        dayAnchor = calendar.startOfDay(for: now())
    }

    func pour(amount: Double) async {
        await run {
            guard let vineID = self.garden.openVine?.id else { throw VineFault.unknownVine }
            self.garden = try await self.store.pour(
                vineID: vineID,
                amount: amount,
                now: self.now(),
                calendar: self.calendar
            )
            self.commitTick += 1
        }
    }

    func pinchLeader() async {
        guard canPinchLeader else { return }
        await run {
            guard let vineID = self.garden.openVine?.id else { throw VineFault.unknownVine }
            self.garden = try await self.store.pinchLeader(vineID: vineID, now: self.now())
            self.commitTick += 1
            self.pinchTick += 1
        }
    }

    func retractFlush() async {
        guard canRetract else { return }
        await run {
            guard let vineID = self.garden.openVine?.id else { throw VineFault.unknownVine }
            self.garden = try await self.store.retractFlush(vineID: vineID)
            self.commitTick += 1
        }
    }

    func openVine(_ vineID: UUID) async {
        await run {
            self.garden = try await self.store.openVine(vineID)
        }
    }

    func openOnGarden(_ vineID: UUID) async {
        await openVine(vineID)
        if garden.openVine?.id == vineID {
            tab = .garden
        }
    }

    func plant(name: String, target: Double) async {
        let seed = TrellisFigures.seed(for: name, existing: garden.vines.map(\.vineSeed))
        await run {
            let before = Set(self.garden.vines.map(\.id))
            self.garden = try await self.store.plant(name: name, target: target, vineSeed: seed)
            if let created = self.garden.vines.first(where: { !before.contains($0.id) }) {
                self.garden = try await self.store.openVine(created.id)
            }
            self.commitTick += 1
        }
    }

    func finishOnboarding() async {
        garden = await store.setOnboardingComplete(true)
        do {
            try await store.flush()
        } catch {
            fault = "The garden could not be written."
        }
        applyReview()
    }

    func reopenOnboarding() async {
        garden = await store.setOnboardingComplete(false)
        tab = .garden
    }

    func resetAll() async {
        await run {
            try await self.store.resetAllData()
            self.garden = .empty
            self.warning = nil
            self.tab = .garden
        }
    }

    func applyReview(arguments: [String] = ProcessInfo.processInfo.arguments) {
        if let pane = GardenLaunch.consume(
            arguments: arguments,
            onboardingComplete: garden.onboardingComplete,
            consumed: &reviewConsumed
        ) {
            reviewPane = pane
        }
        if let pane = reviewPane {
            tab = pane.tab
        }
    }

    static func live() -> GardenWatch {
        let directory: URL
        do {
            directory = try VineStore.applicationSupportDirectory()
        } catch {
            directory = FileManager.default.temporaryDirectory.appendingPathComponent(
                "Palmette",
                isDirectory: true
            )
        }
        return GardenWatch(store: VineStore(directory: directory))
    }

    static func previewPopulated() -> GardenWatch {
        let garden = (try? VineSeed.garden()) ?? Garden.empty.completingOnboarding()
        return GardenWatch(
            store: VineHold(garden: garden),
            garden: garden,
            shouldLoad: false
        )
    }

    static func previewEmpty() -> GardenWatch {
        let garden = Garden.empty.completingOnboarding()
        return GardenWatch(
            store: VineHold(garden: garden),
            garden: garden,
            shouldLoad: false
        )
    }

    static func previewError() -> GardenWatch {
        let garden = Garden.empty.completingOnboarding()
        return GardenWatch(
            store: VineHold(garden: garden, warning: .startedEmpty),
            garden: garden,
            warning: .startedEmpty,
            shouldLoad: false
        )
    }

    private func applyWarning() {
        if warning == .startedEmpty {
            fault = "The garden could not be read. It started empty."
        } else if warning == .recoveredFromBackup {
            fault = "Recovered the last good garden."
        }
    }

    private func run(_ work: () async throws -> Void) async {
        guard !isCommitting else { return }
        isCommitting = true
        defer { isCommitting = false }
        do {
            fault = nil
            try await work()
        } catch let fold as VineFault {
            fault = Self.copy(fold)
        } catch {
            fault = "Something went wrong. Try again."
        }
    }

    private static func copy(_ fault: VineFault) -> String {
        switch fault {
        case .invalidPour:
            "Pour a positive amount."
        case .invalidTarget:
            "Target must be greater than zero."
        case .emptyName:
            "Give the vine a name."
        case .unknownVine:
            "Pick a vine on the garden."
        }
    }
}
