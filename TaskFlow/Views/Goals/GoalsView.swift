import SwiftUI

struct GoalsView: View {
    @EnvironmentObject var store: AppStore
    @State private var editGoalFor: TFTag? = nil

    var tagsWithGoals: [(tag: TFTag, goal: TFGoal)] {
        store.tags.compactMap { tag in
            guard let g = store.goalFor(tagId: tag.id), g.hasAny else { return nil }
            return (tag, g)
        }
    }

    var tagsWithoutGoals: [TFTag] {
        store.tags.filter { tag in !tagsWithGoals.contains { $0.tag.id == tag.id } }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: DS.sp16) {
                if tagsWithGoals.isEmpty && store.tags.isEmpty {
                    EmptyState(icon: "🎯", title: "No goals yet",
                               subtitle: "Create tags first, then set weekly, monthly or yearly goals.")
                        .frame(minHeight: 300)
                } else if tagsWithGoals.isEmpty {
                    EmptyState(icon: "🎯", title: "No goals set",
                               subtitle: "Tap a tag below to set a goal.",
                               action: nil)
                        .frame(minHeight: 200)
                } else {
                    ForEach(tagsWithGoals, id: \.tag.id) { pair in
                        GoalCard(tag: pair.tag, goal: pair.goal) {
                            editGoalFor = pair.tag
                        }
                        .padding(.horizontal, DS.sp16)
                    }
                }

                // Tags without goals
                if !tagsWithoutGoals.isEmpty {
                    VStack(alignment: .leading, spacing: DS.sp8) {
                        SectionHeader(title: "Set a goal", count: tagsWithoutGoals.count)
                            .padding(.horizontal, DS.sp16)
                        ForEach(tagsWithoutGoals) { tag in
                            Button { editGoalFor = tag } label: {
                                HStack(spacing: DS.sp12) {
                                    Circle().fill(Color(hex: tag.colorHex)).frame(width: 10, height: 10)
                                    Text(tag.name).font(.system(size: 14)).foregroundColor(DS.text)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12)).foregroundColor(DS.text3)
                                }
                                .padding(DS.sp12).cardStyle()
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, DS.sp16)
                        }
                    }
                }
            }
            .padding(.vertical, DS.sp16)
            .padding(.bottom, 60)
        }
        .background(DS.bg)
        .navigationTitle("Goals")
        .sheet(item: $editGoalFor) { tag in
            GoalFormView(tag: tag)
        }
    }
}

// MARK: - Goal Card

struct GoalCard: View {
    @EnvironmentObject var store: AppStore
    let tag: TFTag
    let goal: TFGoal
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DS.sp12) {
            // Header
            HStack(spacing: DS.sp8) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(hex: tag.colorHex))
                    .frame(width: 3, height: 18)
                Circle().fill(Color(hex: tag.colorHex)).frame(width: 10, height: 10)
                Text(tag.name)
                    .font(.system(size: 15, weight: .semibold)).foregroundColor(DS.text)
                Spacer()
                Button(action: onEdit) {
                    Image(systemName: "pencil").font(.system(size: 12))
                        .padding(6).background(DS.bg).clipShape(RoundedRectangle(cornerRadius: 5))
                }
                .buttonStyle(.plain).foregroundColor(DS.text3)
            }

            // Period rows
            if let w = goal.weekly, w > 0 {
                let days = store.countActiveDays(tagId: tag.id, in: store.weekDates())
                ProgressRow(label: "This week", current: days, goal: min(w, 7), color: Color(hex: tag.colorHex))
            }
            if let m = goal.monthly, m > 0 {
                let now = Calendar.current.dateComponents([.year, .month], from: Date())
                let days = store.countActiveDays(tagId: tag.id,
                    in: store.monthDates(year: now.year!, month: now.month!))
                let daysInMonth = store.monthDates(year: now.year!, month: now.month!).count
                ProgressRow(label: "This month", current: days, goal: min(m, daysInMonth), color: Color(hex: tag.colorHex))
            }
            if let y = goal.yearly, y > 0 {
                let year = Calendar.current.component(.year, from: Date())
                let days = store.countActiveDays(tagId: tag.id, in: store.yearDates(year))
                ProgressRow(label: "This year", current: days, goal: min(y, 365), color: Color(hex: tag.colorHex))
            }
        }
        .padding(DS.sp16)
        .cardStyle()
    }
}

// MARK: - Goal Form

struct GoalFormView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss

    let tag: TFTag

    @State private var weekly:  String = ""
    @State private var monthly: String = ""
    @State private var yearly:  String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: DS.sp8) {
                        Circle().fill(Color(hex: tag.colorHex)).frame(width: 12, height: 12)
                        Text(tag.name).font(.system(size: 15, weight: .semibold))
                    }
                }

                Section("Goals (days per period)") {
                    GoalField(label: "Weekly",  max: 7,   value: $weekly)
                    GoalField(label: "Monthly", max: 31,  value: $monthly)
                    GoalField(label: "Yearly",  max: 365, value: $yearly)
                }

                Section {
                    Text("Leave blank to skip a period. Progress tracks unique days with this tag logged.")
                        .font(.system(size: 12)).foregroundColor(DS.text3)
                }
            }
            .scrollContentBackground(.hidden)
            .background(DS.bg)
            .navigationTitle("Set Goals")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(DS.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .font(.system(size: 14, weight: .semibold)).foregroundColor(DS.accent)
                }
            }
        }
        .onAppear {
            if let g = store.goalFor(tagId: tag.id) {
                weekly  = g.weekly.map  { $0 > 0 ? "\($0)" : "" } ?? ""
                monthly = g.monthly.map { $0 > 0 ? "\($0)" : "" } ?? ""
                yearly  = g.yearly.map  { $0 > 0 ? "\($0)" : "" } ?? ""
            }
        }
    }

    private func save() {
        let w = Int(weekly).flatMap  { $0 > 0 ? $0 : nil }
        let m = Int(monthly).flatMap { $0 > 0 ? $0 : nil }
        let y = Int(yearly).flatMap  { $0 > 0 ? $0 : nil }
        store.upsertGoal(tagId: tag.id, weekly: w, monthly: m, yearly: y)
        dismiss()
    }
}

struct GoalField: View {
    let label: String
    let max: Int
    @Binding var value: String

    var body: some View {
        HStack {
            Text(label).font(.system(size: 14)).foregroundColor(DS.text)
            Spacer()
            TextField("—", text: $value)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 60)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(DS.accent)
                .onChange(of: value) { v in
                    // clamp to max
                    if let n = Int(v), n > max { value = "\(max)" }
                }
            Text("/ \(max)")
                .font(.system(size: 12)).foregroundColor(DS.text3)
        }
    }
}
