import SwiftUI

/// Role: Vine. Garden-tab chrome. Garden holds the trellis; Analytics and Settings are siblings. No Plot or GardenGame.
struct GardenChrome: View {
    @Bindable var watch: GardenWatch
    @State private var tab: GardenTab
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    init(watch: GardenWatch) {
        self.watch = watch
        watch.applyReview()
        _tab = State(initialValue: watch.tab)
    }

    private var usesPadTabs: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .regular
    }

    var body: some View {
        Group {
            if usesPadTabs {
                padChrome
            } else {
                phoneChrome
            }
        }
        .tint(TrellisInk.Palette.accent)
        .onAppear {
            watch.applyReview()
            tab = watch.tab
        }
        .onChange(of: tab) { _, new in
            watch.tab = new
        }
        .onChange(of: watch.tab) { _, new in
            tab = new
        }
    }

    private var phoneChrome: some View {
        VStack(spacing: 0) {
            Group {
                switch tab {
                case .garden:
                    NavigationStack {
                        TrellisPane(watch: watch)
                    }
                case .analytics:
                    NavigationStack {
                        AnalyticsView(watch: watch)
                    }
                case .settings:
                    NavigationStack {
                        SettingsView(watch: watch)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            GardenTabStrip(tab: $tab)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(TrellisInk.Palette.background.ignoresSafeArea())
    }

    @ViewBuilder
    private var padChrome: some View {
        Group {
            if #available(iOS 18.0, *) {
                TabView(selection: $tab) {
                    Tab("Garden", systemImage: "leaf", value: GardenTab.garden) {
                        NavigationStack {
                            TrellisPane(watch: watch)
                        }
                    }
                    Tab("Analytics", systemImage: "chart.bar", value: GardenTab.analytics) {
                        NavigationStack {
                            AnalyticsView(watch: watch)
                        }
                    }
                    Tab("Settings", systemImage: "gearshape", value: GardenTab.settings) {
                        NavigationStack {
                            SettingsView(watch: watch)
                        }
                    }
                }
                .tabViewStyle(.tabBarOnly)
            } else {
                TabView(selection: $tab) {
                    NavigationStack {
                        TrellisPane(watch: watch)
                    }
                    .tabItem {
                        Label("Garden", systemImage: "leaf")
                    }
                    .tag(GardenTab.garden)

                    NavigationStack {
                        AnalyticsView(watch: watch)
                    }
                    .tabItem {
                        Label("Analytics", systemImage: "chart.bar")
                    }
                    .tag(GardenTab.analytics)

                    NavigationStack {
                        SettingsView(watch: watch)
                    }
                    .tabItem {
                        Label("Settings", systemImage: "gearshape")
                    }
                    .tag(GardenTab.settings)
                }
            }
        }
        .toolbarBackground(TrellisInk.Palette.background, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

/// Role: Vine. Full-width tab strip that sits on the home indicator. Not a floating pill.
private struct GardenTabStrip: View {
    @Binding var tab: GardenTab

    var body: some View {
        HStack(spacing: 0) {
            stripButton(.garden, title: "Garden", systemName: "leaf")
            stripButton(.analytics, title: "Analytics", systemName: "chart.bar")
            stripButton(.settings, title: "Settings", systemName: "gearshape")
        }
        .padding(.top, TrellisRail.space(1))
        .padding(.horizontal, TrellisRail.space(1))
        .frame(maxWidth: .infinity)
        .background {
            TrellisInk.Palette.background
                .ignoresSafeArea(edges: .bottom)
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(TrellisInk.Palette.ink.opacity(0.12))
                .frame(height: 1)
                .frame(maxWidth: .infinity)
                .allowsHitTesting(false)
        }
        .accessibilityElement(children: .contain)
    }

    private func stripButton(_ value: GardenTab, title: String, systemName: String) -> some View {
        let selected = tab == value
        return Button {
            tab = value
        } label: {
            VStack(spacing: 2) {
                Image(systemName: systemName)
                    .font(TrellisFace.font(.body).weight(.semibold))
                    .symbolVariant(selected ? .fill : .none)
                Text(title)
                    .font(TrellisFace.font(.caption).weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(selected ? TrellisInk.Palette.accent : TrellisInk.Palette.ink)
            .frame(maxWidth: .infinity, minHeight: TrellisRail.tap)
            .contentShape(Rectangle())
        }
        .buttonStyle(TrellisPressStyle(enabled: true))
        .accessibilityLabel(title)
        .accessibilityAddTraits(selected ? AccessibilityTraits.isSelected : AccessibilityTraits())
    }
}
