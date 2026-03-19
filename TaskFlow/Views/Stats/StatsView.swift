import SwiftUI

struct StatsView: View {
    @EnvironmentObject var store: AppStore
    @State private var period: StatPeriod = .week
    @State private var offset = 0  // weeks/months/years back
    @State private var filterTag: String? = nil  // nil = all

    enum StatPeriod: String, CaseIterable { case week = "Week"; case month = "Month"; case year = "Year" }

    // Dates for current view
    var dates: [String] {
        switch period {
        case .week:
            let base = baseWeekDates()
            return base
        case .month:
            let (y, m) = monthOffset()
            return store.monthDates(year: y, month: m)
        case .year:
            return store.yearDates(yearOffset())
        }
    }

    var filteredTasks: [TFTask] {
        let inRange = store.tasks.filter { dates.contains($0.date) }
        guard let ft = filterTag else { return inRange }
        return inRange.filter { $0.tagSelections.contains { $0.tagId == ft } }
    }

    var activeDates: Set<String> { Set(filteredTasks.map(\.date)) }

    var periodLabel: String {
        switch period {
        case .week:
            guard let first = dates.first, let last = dates.last else { return "" }
            return "\(first.shortFormatted()) – \(last.shortFormatted())"
        case .month:
            let (y, m) = monthOffset()
            let f = DateFormatter(); f.dateFormat = "MMMM yyyy"
            let c = DateComponents(year: y, month: m)
            return f.string(from: Calendar.current.date(from: c) ?? Date())
        case .year:
            return "\(yearOffset())"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: DS.sp20) {

                // Period selector + nav
                VStack(spacing: DS.sp12) {
                    Picker("Period", selection: $period.animation()) {
                        ForEach(StatPeriod.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Button { offset -= 1 } label: {
                            Image(systemName: "chevron.left").font(.system(size: 13, weight: .semibold))
                                .frame(width: 32, height: 32).background(DS.card)
                                .clipShape(RoundedRectangle(cornerRadius: DS.r6))
                                .overlay(RoundedRectangle(cornerRadius: DS.r6).stroke(DS.border, lineWidth: 1))
                        }.buttonStyle(.plain).foregroundColor(DS.text2)

                        Spacer()
                        Text(periodLabel).font(.system(size: 15, weight: .semibold)).foregroundColor(DS.text)
                        Spacer()

                        Button { if offset < 0 { offset += 1 } } label: {
                            Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold))
                                .frame(width: 32, height: 32).background(DS.card)
                                .clipShape(RoundedRectangle(cornerRadius: DS.r6))
                                .overlay(RoundedRectangle(cornerRadius: DS.r6).stroke(DS.border, lineWidth: 1))
                        }.buttonStyle(.plain).foregroundColor(offset < 0 ? DS.text2 : DS.text3)
                        .disabled(offset >= 0)
                    }

                    // Tag filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            FilterChip(label: "All", color: DS.accent, active: filterTag == nil) { filterTag = nil }
                            ForEach(store.tags) { tag in
                                FilterChip(label: tag.name, color: Color(hex: tag.colorHex),
                                           active: filterTag == tag.id) { filterTag = tag.id }
                            }
                        }.padding(.horizontal, 1)
                    }
                }
                .padding(.horizontal, DS.sp16)

                // Summary cards
                let done = filteredTasks.filter(\.isDone).count
                LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: DS.sp12) {
                    StatCard(value: "\(filteredTasks.count)", label: "Total tasks", color: DS.text)
                    StatCard(value: "\(done)", label: "Completed", color: DS.green)
                    StatCard(value: "\(activeDates.count)", label: "Active days", color: DS.accent)
                    StatCard(value: dates.isEmpty ? "0" : String(format: "%.1f", Double(filteredTasks.count)/Double(dates.count)),
                             label: "Avg / day", color: DS.text2)
                }
                .padding(.horizontal, DS.sp16)

                // Heatmap
                heatmapSection

                // Bar chart
                barSection
            }
            .padding(.vertical, DS.sp16)
            .padding(.bottom, 60)
        }
        .background(DS.bg)
        .navigationTitle("Stats")
        .onChange(of: period) { offset = 0 }
    }

    // MARK: - Heatmap

    @ViewBuilder
    var heatmapSection: some View {
        VStack(alignment: .leading, spacing: DS.sp12) {
            Text(period == .week ? "Week Heatmap" : period == .month ? "Monthly Heatmap" : "Year Overview")
                .font(.system(size: 14, weight: .semibold)).foregroundColor(DS.text)

            let heatColor = filterTag.flatMap { id in store.tags.first { $0.id == id } }
                              .map { Color(hex: $0.colorHex) } ?? DS.accent
            let maxCount = dates.map { store.taskCount(for: $0) }.max() ?? 1

            switch period {
            case .week: WeekHeatmap(dates: dates, color: heatColor, maxCount: maxCount) { d in
                store.selectedDate = d
            }
            case .month: MonthHeatmap(dates: dates, color: heatColor, maxCount: maxCount) { d in
                store.selectedDate = d
            }
            case .year: YearHeatmap(dates: dates, color: heatColor, maxCount: maxCount) { d in
                store.selectedDate = d
            }
            }
        }
        .padding(DS.sp16)
        .cardStyle()
        .padding(.horizontal, DS.sp16)
    }

    // MARK: - Bar chart

    @ViewBuilder
    var barSection: some View {
        if !store.tags.isEmpty {
            VStack(alignment: .leading, spacing: DS.sp12) {
                Text("Tasks by Tag").font(.system(size: 14, weight: .semibold)).foregroundColor(DS.text)
                let tagCounts: [(TFTag, Int)] = store.tags.map { tag in
                    let cnt = filteredTasks.filter { $0.tagSelections.contains { $0.tagId == tag.id } }.count
                    return (tag, cnt)
                }.filter { $0.1 > 0 }
                let maxBar = tagCounts.map(\.1).max() ?? 1
                if tagCounts.isEmpty {
                    Text("No data for this period.")
                        .font(.system(size: 13)).foregroundColor(DS.text3)
                } else {
                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(tagCounts, id: \.0.id) { (tag, cnt) in
                            VStack(spacing: 4) {
                                Text("\(cnt)").font(.system(size: 10, weight: .semibold)).foregroundColor(DS.text3)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(hex: tag.colorHex).opacity(0.75))
                                    .frame(height: max(4, CGFloat(cnt) / CGFloat(maxBar) * 80))
                                Text(tag.name.prefix(6) + (tag.name.count > 6 ? "…" : ""))
                                    .font(.system(size: 9)).foregroundColor(DS.text3).lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(height: 110, alignment: .bottom)
                }
            }
            .padding(DS.sp16)
            .cardStyle()
            .padding(.horizontal, DS.sp16)
        }
    }

    // MARK: - Date calculation helpers

    func baseWeekDates() -> [String] {
        let cal = Calendar.current; let now = Date()
        let wd = cal.component(.weekday, from: now)
        let toMon = wd == 1 ? -6 : -(wd - 2)
        let mon = cal.date(byAdding: .day, value: toMon + offset * 7, to: now)!
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        return (0..<7).map { fmt.string(from: cal.date(byAdding: .day, value: $0, to: mon)!) }
    }

    func monthOffset() -> (Int, Int) {
        let cal = Calendar.current; var c = cal.dateComponents([.year, .month], from: Date())
        let totalM = (c.year! * 12 + c.month! - 1) + offset
        c.year = totalM / 12; c.month = totalM % 12 + 1; return (c.year!, c.month!)
    }

    func yearOffset() -> Int {
        Calendar.current.component(.year, from: Date()) + offset
    }
}

// MARK: - Filter chip

struct FilterChip: View {
    let label: String; let color: Color; let active: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: active ? .semibold : .regular))
                .foregroundColor(active ? .white : DS.text2)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(active ? color : DS.card)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(active ? color : DS.border, lineWidth: 1))
        }.buttonStyle(.plain)
    }
}

// MARK: - Week Heatmap

struct WeekHeatmap: View {
    @EnvironmentObject var store: AppStore
    let dates: [String]; let color: Color; let maxCount: Int
    let onTap: (String) -> Void
    let dow = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]

    var body: some View {
        HStack(spacing: DS.sp8) {
            ForEach(Array(dates.enumerated()), id: \.1) { i, d in
                let cnt = store.taskCount(for: d)
                let intensity = maxCount > 0 ? Double(cnt) / Double(maxCount) : 0
                let isToday = d == .today()
                VStack(spacing: 4) {
                    Text(dow[i]).font(.system(size: 10, weight: .medium)).foregroundColor(DS.text3)
                    HeatCell(intensity: intensity, color: color, isToday: isToday) { onTap(d) }
                        .frame(height: 40)
                    Text("\(cnt)").font(.system(size: 11, weight: .semibold)).foregroundColor(DS.text3)
                    Text(d.shortFormatted()).font(.system(size: 9)).foregroundColor(DS.text3)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Month Heatmap

struct MonthHeatmap: View {
    @EnvironmentObject var store: AppStore
    let dates: [String]; let color: Color; let maxCount: Int
    let onTap: (String) -> Void
    let headers = ["M","T","W","T","F","S","S"]

    var body: some View {
        VStack(spacing: 4) {
            // Day-of-week headers
            HStack(spacing: 4) {
                ForEach(headers, id: \.self) { h in
                    Text(h).font(.system(size: 10, weight: .medium)).foregroundColor(DS.text3)
                        .frame(maxWidth: .infinity)
                }
            }
            // Cells
            let startOffset = startDayOffset()
            let allCells = Array(repeating: "", count: startOffset) + dates
            let rows = allCells.chunked(into: 7)
            ForEach(rows.indices, id: \.self) { ri in
                HStack(spacing: 4) {
                    ForEach(rows[ri].indices, id: \.self) { ci in
                        let d = rows[ri][ci]
                        if d.isEmpty {
                            Color.clear.frame(maxWidth: .infinity, minHeight: 28, maxHeight: 28)
                        } else {
                            let cnt = store.taskCount(for: d)
                            let intensity = maxCount > 0 ? Double(cnt) / Double(maxCount) : 0
                            HeatCell(intensity: intensity, color: color, isToday: d == .today()) { onTap(d) }
                                .frame(maxWidth: .infinity, minHeight: 28, maxHeight: 28)
                        }
                    }
                }
            }
        }
    }

    func startDayOffset() -> Int {
        guard let first = dates.first, let d = first.toDate() else { return 0 }
        let wd = Calendar.current.component(.weekday, from: d)
        return wd == 1 ? 6 : wd - 2
    }
}

// MARK: - Year Heatmap

struct YearHeatmap: View {
    @EnvironmentObject var store: AppStore
    let dates: [String]; let color: Color; let maxCount: Int
    let onTap: (String) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            let weeks = dates.chunked(into: 7)
            HStack(alignment: .top, spacing: 3) {
                ForEach(weeks.indices, id: \.self) { wi in
                    VStack(spacing: 3) {
                        ForEach(weeks[wi], id: \.self) { d in
                            let cnt = store.taskCount(for: d)
                            let intensity = maxCount > 0 ? Double(cnt) / Double(maxCount) : 0
                            HeatCell(intensity: intensity, color: color, isToday: d == .today()) { onTap(d) }
                                .frame(width: 13, height: 13)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Array chunked helper

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map { Array(self[$0..<Swift.min($0+size, count)]) }
    }
}
