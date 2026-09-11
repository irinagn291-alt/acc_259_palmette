import SwiftUI

/// Role: Vine. Host. Passage first; then garden-tab chrome. Views never touch the store.
struct ContentView: View {
    @State private var watch: GardenWatch
    var handlesLaunch: Bool
    @Environment(\.scenePhase) private var scenePhase
    @State private var ready = false

    init(watch: GardenWatch = .live(), handlesLaunch: Bool = true) {
        self._watch = State(initialValue: watch)
        self.handlesLaunch = handlesLaunch
        self._ready = State(initialValue: !handlesLaunch)
    }

    var body: some View {
        Group {
            if handlesLaunch && !ready {
                TrellisInk.Palette.background
                    .ignoresSafeArea()
                    .overlay {
                        Image(TrellisPlate.splash)
                            .resizable()
                            .scaledToFill()
                            .ignoresSafeArea()
                            .accessibilityHidden(true)
                    }
                    .overlay {
                        if watch.isHauling {
                            ProgressView()
                                .tint(TrellisInk.Palette.accent)
                        }
                    }
            } else if watch.onboardingComplete {
                GardenChrome(watch: watch)
            } else {
                GardenPassage(watch: watch)
            }
        }
        .tint(TrellisInk.Palette.accent)
        .preferredColorScheme(.light)
        .background(TrellisInk.Palette.background.ignoresSafeArea())
        .task {
            guard handlesLaunch else {
                ready = true
                watch.applyReview()
                return
            }
            await watch.appear()
            ready = true
            await Task.yield()
            watch.applyReview()
        }
        .onChange(of: watch.onboardingComplete) { _, complete in
            if complete, ready {
                watch.applyReview()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            guard handlesLaunch else { return }
            if phase == .inactive || phase == .background {
                Task { await watch.flush() }
            }
            if phase == .active {
                watch.markDay()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            watch.markDay()
        }
    }
}

#Preview {
    ContentView(watch: .previewPopulated(), handlesLaunch: false)
}
