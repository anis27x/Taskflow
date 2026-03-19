import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case tasks = "Tasks"; case stats = "Stats"; case tags = "Tags"; case goals = "Goals"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .tasks: return "checklist"
        case .stats: return "chart.bar"
        case .tags:  return "tag"
        case .goals: return "target"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var store: AppStore
    @State private var tab: AppTab = .tasks

    var body: some View {
        #if os(macOS)
        MacLayout(tab: $tab)
        #else
        IOSLayout(tab: $tab)
        #endif
    }
}

// MARK: - iOS

struct IOSLayout: View {
    @EnvironmentObject var store: AppStore
    @Binding var tab: AppTab

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack { DailyTasksView() }
                .tabItem { Label("Tasks", systemImage: "checklist") }.tag(AppTab.tasks)
            NavigationStack { StatsView() }
                .tabItem { Label("Stats", systemImage: "chart.bar") }.tag(AppTab.stats)
            NavigationStack { TagsView() }
                .tabItem { Label("Tags", systemImage: "tag") }.tag(AppTab.tags)
            NavigationStack { GoalsView() }
                .tabItem { Label("Goals", systemImage: "target") }.tag(AppTab.goals)
        }
        .tint(DS.accent)
    }
}

// MARK: - macOS

struct MacLayout: View {
    @Binding var tab: AppTab
    var body: some View {
        NavigationSplitView {
            MacSidebar(tab: $tab)
        } detail: {
            switch tab {
            case .tasks: DailyTasksView()
            case .stats: StatsView()
            case .tags:  TagsView()
            case .goals: GoalsView()
            }
        }
    }
}

struct MacSidebar: View {
    @EnvironmentObject var store: AppStore
    @Binding var tab: AppTab

    var dayTasks: [TFTask] { store.tasksFor(date: store.selectedDate) }
    var done: Int { dayTasks.filter(\.isDone).count }
    var pct:  Int { dayTasks.isEmpty ? 0 : Int(Double(done)/Double(dayTasks.count)*100) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Logo row
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 7)
                    .fill(DS.accent)
                    .frame(width: 30, height: 30)
                    .overlay(Text("TF").font(.system(size: 12, weight: .bold)).foregroundColor(.white))
                VStack(alignment: .leading, spacing: 1) {
                    Text("TaskFlow").font(.system(size: 14, weight: .semibold)).foregroundColor(DS.text)
                    Text("Task tracker").font(.system(size: 11)).foregroundColor(DS.text3)
                }
                Spacer()
                if store.isSyncing {
                    ProgressView().scaleEffect(0.65)
                } else if store.cloudAvailable {
                    Image(systemName: "icloud.fill")
                        .font(.system(size: 11)).foregroundColor(DS.text3)
                } else {
                    Image(systemName: "icloud.slash")
                        .font(.system(size: 11)).foregroundColor(DS.text3)
                }
            }
            .padding(DS.sp16)
            Divider()

            // Date nav
            DateNav()
            Divider()

            // Nav links
            VStack(alignment: .leading, spacing: 2) {
                Text("VIEWS")
                    .font(.system(size: 10, weight: .medium)).tracking(0.8).foregroundColor(DS.text3)
                    .padding(.horizontal, DS.sp12).padding(.top, DS.sp12).padding(.bottom, 4)
                ForEach(AppTab.allCases) { t in
                    SidebarRow(tab: t, selected: tab == t) { tab = t }
                }
            }
            .padding(.vertical, DS.sp8)

            Spacer()
            Divider()

            // Footer stats
            HStack(spacing: DS.sp20) {
                SidebarStat(value: "\(dayTasks.count)", label: "Tasks", color: DS.text)
                SidebarStat(value: "\(done)",           label: "Done",  color: DS.accent)
                SidebarStat(value: "\(pct)%",           label: "Rate",  color: DS.green)
            }
            .padding(DS.sp16)
        }
        .frame(width: 220)
        .background(DS.bg2)
    }
}

struct SidebarRow: View {
    let tab: AppTab; let selected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: tab.icon).font(.system(size: 13)).frame(width: 16)
                Text(tab.rawValue).font(.system(size: 13, weight: selected ? .semibold : .regular))
            }
            .foregroundColor(selected ? DS.accentDk : DS.text2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DS.sp12).padding(.vertical, DS.sp8)
            .background(selected ? DS.accentBg : .clear)
            .clipShape(RoundedRectangle(cornerRadius: DS.r6))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, DS.sp8)
    }
}

struct SidebarStat: View {
    let value: String; let label: String; let color: Color
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 18, weight: .semibold)).foregroundColor(color)
            Text(label.uppercased()).font(.system(size: 9, weight: .medium)).tracking(0.5).foregroundColor(DS.text3)
        }
    }
}

// MARK: - Date Nav (shared between macOS sidebar & iOS inline)

struct DateNav: View {
    @EnvironmentObject var store: AppStore

    var dow: String {
        guard let d = store.selectedDate.toDate() else { return "" }
        let f = DateFormatter(); f.dateFormat = "EEEE"; return f.string(from: d)
    }
    var isToday: Bool { store.selectedDate == .today() }

    var body: some View {
        VStack(spacing: DS.sp8) {
            HStack {
                navBtn("chevron.left")  { store.selectedDate = store.selectedDate.addingDays(-1) }
                Spacer()
                VStack(spacing: 1) {
                    Text(dow).font(.system(size: 13, weight: .semibold)).foregroundColor(DS.text)
                    Text(store.selectedDate.shortFormatted()).font(.system(size: 11)).foregroundColor(DS.text3)
                }
                Spacer()
                navBtn("chevron.right") { store.selectedDate = store.selectedDate.addingDays(1) }
            }
            Button("Jump to Today") { store.selectedDate = .today() }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isToday ? DS.text3 : .white)
                .frame(maxWidth: .infinity).padding(.vertical, 6)
                .background(isToday ? DS.bg2 : DS.accent)
                .clipShape(RoundedRectangle(cornerRadius: DS.r6))
                .buttonStyle(.plain)
                .disabled(isToday)
        }
        .padding(DS.sp12)
    }

    @ViewBuilder
    func navBtn(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 11, weight: .semibold))
                .frame(width: 28, height: 28)
                .background(DS.card)
                .clipShape(RoundedRectangle(cornerRadius: DS.r6))
                .overlay(RoundedRectangle(cornerRadius: DS.r6).stroke(DS.border, lineWidth: 1))
        }
        .buttonStyle(.plain).foregroundColor(DS.text2)
    }
}

// MARK: - macOS Settings stub

struct SettingsView: View {
    @EnvironmentObject var store: AppStore
    var body: some View {
        Form {
            Section("iCloud Sync") {
                HStack {
                    Label("Status", systemImage: store.cloudAvailable ? "icloud.fill" : "icloud.slash")
                    Spacer()
                    Text(store.cloudAvailable ? "Connected" : "Not available")
                        .foregroundColor(store.cloudAvailable ? DS.green : DS.text3)
                }
                Button("Sync Now") { Task { await store.pullFromCloud() } }
                    .disabled(!store.cloudAvailable || store.isSyncing)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 200)
        .navigationTitle("Settings")
    }
}
