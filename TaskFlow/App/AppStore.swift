import Foundation
import SwiftUI
import Combine

@MainActor
final class AppStore: ObservableObject {

    // MARK: Published data
    @Published var tags:  [TFTag]  = []
    @Published var tasks: [TFTask] = []
    @Published var goals: [TFGoal] = []

    // MARK: UI state
    @Published var selectedDate: String = .today()

    private let localKey = "tf_store_v1"

    // MARK: - Boot

    init() { loadLocal() }

    // MARK: - Local persistence

    private struct Snapshot: Codable {
        var tags: [TFTag]; var tasks: [TFTask]; var goals: [TFGoal]
    }

    private func loadLocal() {
        guard let d = UserDefaults.standard.data(forKey: localKey),
              let s = try? JSONDecoder().decode(Snapshot.self, from: d) else {
            seedDefaults(); return
        }
        tags = s.tags; tasks = s.tasks; goals = s.goals
    }

    func persist() {
        let s = Snapshot(tags: tags, tasks: tasks, goals: goals)
        if let d = try? JSONEncoder().encode(s) {
            UserDefaults.standard.set(d, forKey: localKey)
        }
    }

    private func seedDefaults() {
        tags = [
            TFTag(name: "Workout", colorHex: "#DC2626",
                  subtags: [TFSubtag(name: "Cardio"), TFSubtag(name: "Strength")]),
            TFTag(name: "Work",    colorHex: "#2563EB",
                  subtags: [TFSubtag(name: "Study"), TFSubtag(name: "Meetings")]),
            TFTag(name: "Health",  colorHex: "#059669",
                  subtags: [TFSubtag(name: "Diet")]),
            TFTag(name: "Personal", colorHex: "#7C3AED", subtags: []),
        ]
        persist()
    }

    // MARK: - Tags

    func addTag(_ t: TFTag) { tags.append(t); persist() }

    func updateTag(_ t: TFTag) {
        if let i = tags.firstIndex(where: { $0.id == t.id }) { tags[i] = t }
        persist()
    }

    func deleteTag(_ t: TFTag) {
        tags.removeAll { $0.id == t.id }
        tasks = tasks.map { var x = $0; x.tagSelections.removeAll { $0.tagId == t.id }; return x }
        goals.removeAll { $0.tagId == t.id }
        persist()
    }

    func addSubtag(_ s: TFSubtag, to tagId: String) {
        guard let i = tags.firstIndex(where: { $0.id == tagId }) else { return }
        tags[i].subtags.append(s); persist()
    }

    func deleteSubtag(subId: String, tagId: String) {
        guard let i = tags.firstIndex(where: { $0.id == tagId }) else { return }
        tags[i].subtags.removeAll { $0.id == subId }
        tasks = tasks.map { task in
            var t = task
            t.tagSelections = t.tagSelections.map { sel in
                if sel.tagId == tagId {
                    var s = sel; s.subtagIds.removeAll { $0 == subId }; return s
                }; return sel
            }; return t
        }
        persist()
    }

    // MARK: - Tasks

    func tasksFor(date: String) -> [TFTask] {
        tasks.filter { $0.date == date }
             .sorted {
                 if let a = $0.timeStart, let b = $1.timeStart { return a < b }
                 if $0.timeStart != nil { return true }
                 if $1.timeStart != nil { return false }
                 return $0.priority.sortOrder < $1.priority.sortOrder
             }
    }

    func addTask(_ t: TFTask)    { tasks.append(t); persist() }

    func updateTask(_ t: TFTask) {
        if let i = tasks.firstIndex(where: { $0.id == t.id }) { tasks[i] = t }
        persist()
    }

    func deleteTask(_ t: TFTask) { tasks.removeAll { $0.id == t.id }; persist() }

    func toggleDone(_ t: TFTask) { var x = t; x.isDone.toggle(); updateTask(x) }

    // MARK: - Goals
    // TFGoal in Models.swift: id, tagId (String), weekly, monthly, yearly (Int?)

    func goalFor(tagId: String) -> TFGoal? { goals.first { $0.tagId == tagId } }

    func upsertGoal(tagId: String, weekly: Int?, monthly: Int?, yearly: Int?) {
        if let i = goals.firstIndex(where: { $0.tagId == tagId }) {
            goals[i].weekly  = weekly
            goals[i].monthly = monthly
            goals[i].yearly  = yearly
            persist()
        } else {
            goals.append(TFGoal(tagId: tagId, weekly: weekly, monthly: monthly, yearly: yearly))
            persist()
        }
    }

    // MARK: - Stats helpers

    func countActiveDays(tagId: String, in dates: [String]) -> Int {
        Set(tasks.filter { t in
            dates.contains(t.date) && t.tagSelections.contains { $0.tagId == tagId }
        }.map(\.date)).count
    }

    func taskCount(for date: String) -> Int { tasks.filter { $0.date == date }.count }

    func weekDates() -> [String] {
        let cal = Calendar.current; let now = Date()
        let wd  = cal.component(.weekday, from: now)
        let off = wd == 1 ? -6 : -(wd - 2)
        let mon = cal.date(byAdding: .day, value: off, to: now)!
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        return (0..<7).map { fmt.string(from: cal.date(byAdding: .day, value: $0, to: mon)!) }
    }

    func monthDates(year: Int, month: Int) -> [String] {
        let cal = Calendar.current
        guard let first = cal.date(from: DateComponents(year: year, month: month, day: 1)),
              let range = cal.range(of: .day, in: .month, for: first) else { return [] }
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        return range.map { fmt.string(from: cal.date(from: DateComponents(year: year, month: month, day: $0))!) }
    }

    func yearDates(_ year: Int) -> [String] {
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        let cal = Calendar.current
        guard let jan1  = cal.date(from: DateComponents(year: year, month: 1, day: 1)),
              let dec31 = cal.date(from: DateComponents(year: year, month: 12, day: 31)) else { return [] }
        var dates: [String] = []; var d = jan1
        while d <= dec31 { dates.append(fmt.string(from: d)); d = cal.date(byAdding: .day, value: 1, to: d)! }
        return dates
    }
}
