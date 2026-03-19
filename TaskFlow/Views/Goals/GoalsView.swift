import SwiftUI

// MARK: - Goals View

struct GoalsView: View {
    @EnvironmentObject var store: AppStore
    @State private var editGoalFor: TFTag? = nil
    @State private var showNewGoal = false

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

                // No tags at all
                if store.tags.isEmpty {
                    EmptyState(
                        icon: "target",
                        title: "No goals yet",
                        subtitle: "Create tags first in the Tags tab, then come back to set goals."
                    )
                    .frame(minHeight: 340)

                } else {

                    // Active goal cards
                    if !tagsWithGoals.isEmpty {
                        VStack(alignment: .leading, spacing: DS.sp8) {
                            SectionHeader(title: "Active goals", count: tagsWithGoals.count)
                                .padding(.horizontal, DS.sp16)
                            ForEach(tagsWithGoals, id: \.tag.id) { pair in
                                GoalCard(tag: pair.tag, goal: pair.goal) {
                                    editGoalFor = pair.tag
                                }
                                .padding(.horizontal, DS.sp16)
                            }
                        }
                    }

                    // Tags without goals
                    if !tagsWithoutGoals.isEmpty {
                        VStack(alignment: .leading, spacing: DS.sp8) {
                            SectionHeader(
                                title: tagsWithGoals.isEmpty ? "Choose a tag to start" : "No goal yet",
                                count: tagsWithoutGoals.count
                            )
                            .padding(.horizontal, DS.sp16)

                            ForEach(tagsWithoutGoals) { tag in
                                Button { editGoalFor = tag } label: {
                                    HStack(spacing: DS.sp12) {
                                        Circle()
                                            .fill(Color(hex: tag.colorHex))
                                            .frame(width: 10, height: 10)
                                        Text(tag.name)
                                            .font(.system(size: 14))
                                            .foregroundColor(DS.text)
                                        Spacer()
                                        Text("Set goal")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(DS.accent)
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 11))
                                            .foregroundColor(DS.text3)
                                    }
                                    .padding(DS.sp12)
                                    .cardStyle()
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, DS.sp16)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, DS.sp16)
            .padding(.bottom, 80)
        }
        .background(DS.bg)
        .navigationTitle("Goals")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    if tagsWithoutGoals.isEmpty && !store.tags.isEmpty {
                        // All tags have goals — open picker to re-edit any
                        showNewGoal = true
                    } else if store.tags.count == 1 {
                        // Only one tag available, go straight to form
                        editGoalFor = tagsWithoutGoals.first ?? store.tags.first
                    } else {
                        showNewGoal = true
                    }
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(store.tags.isEmpty ? DS.text3 : DS.accent)
                }
                .disabled(store.tags.isEmpty)
            }
        }
        // Tag picker sheet → then goal form
        .sheet(isPresented: $showNewGoal) {
            TagPickerSheet(onSelect: { tag in
                showNewGoal = false
                // Small delay so the first sheet dismisses before the next presents
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    editGoalFor = tag
                }
            })
        }
        // Goal form sheet
        .sheet(item: $editGoalFor) { tag in
            GoalFormView(tag: tag)
        }
    }
}

// MARK: - Tag Picker Sheet

struct TagPickerSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    let onSelect: (TFTag) -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.tags) { tag in
                    Button {
                        onSelect(tag)
                    } label: {
                        HStack(spacing: DS.sp12) {
                            Circle()
                                .fill(Color(hex: tag.colorHex))
                                .frame(width: 12, height: 12)
                            Text(tag.name)
                                .font(.system(size: 15))
                                .foregroundColor(DS.text)
                            Spacer()

                            // Show current goal summary if one exists
                            if let g = store.goalFor(tagId: tag.id), g.hasAny {
                                GoalSummaryBadge(goal: g)
                            } else {
                                Text("No goal")
                                    .font(.system(size: 12))
                                    .foregroundColor(DS.text3)
                            }

                            Image(systemName: "chevron.right")
                                .font(.system(size: 11))
                                .foregroundColor(DS.text3)
                        }
                        .padding(.vertical, DS.sp4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(DS.bg)
            .navigationTitle("Select Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(DS.text3)
                }
            }
        }
    }
}

// MARK: - Small badge showing existing goal numbers

struct GoalSummaryBadge: View {
    let goal: TFGoal
    var summary: String {
        var parts: [String] = []
        if let w = goal.weekly,  w > 0 { parts.append("\(w)w") }
        if let m = goal.monthly, m > 0 { parts.append("\(m)m") }
        if let y = goal.yearly,  y > 0 { parts.append("\(y)y") }
        return parts.joined(separator: " · ")
    }
    var body: some View {
        Text(summary)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(DS.accent)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(DS.accentBg)
            .clipShape(RoundedRectangle(cornerRadius: 5))
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
            HStack(spacing: DS.sp8) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: tag.colorHex))
                    .frame(width: 3, height: 18)
                Circle()
                    .fill(Color(hex: tag.colorHex))
                    .frame(width: 10, height: 10)
                Text(tag.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(DS.text)
                Spacer()
                Button(action: onEdit) {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil").font(.system(size: 11))
                        Text("Edit").font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(DS.text3)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(DS.bg)
                    .clipShape(RoundedRectangle(cornerRadius: DS.r6))
                }
                .buttonStyle(.plain)
            }

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

    private var hasExisting: Bool { store.goalFor(tagId: tag.id)?.hasAny == true }

    var body: some View {
        NavigationStack {
            Form {
                // Tag header
                Section {
                    HStack(spacing: DS.sp10) {
                        Circle()
                            .fill(Color(hex: tag.colorHex))
                            .frame(width: 12, height: 12)
                        Text(tag.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(DS.text)
                    }
                }

                // Goal fields
                Section {
                    GoalField(label: "Weekly",  placeholder: "days / week",  max: 7,   value: $weekly)
                    GoalField(label: "Monthly", placeholder: "days / month", max: 31,  value: $monthly)
                    GoalField(label: "Yearly",  placeholder: "days / year",  max: 365, value: $yearly)
                } header: {
                    Text("Target days per period")
                } footer: {
                    Text("Leave a field blank to skip that period. Progress is counted as unique days where this tag appears on a task.")
                        .font(.system(size: 12))
                }

                // Delete option if goal already exists
                if hasExisting {
                    Section {
                        Button(role: .destructive) { deleteGoal() } label: {
                            HStack {
                                Spacer()
                                Text("Remove all goals for \(tag.name)")
                                    .font(.system(size: 14))
                                Spacer()
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(DS.bg)
            .navigationTitle(hasExisting ? "Edit Goal" : "New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(DS.text3)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(DS.accent)
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

    private func deleteGoal() {
        store.upsertGoal(tagId: tag.id, weekly: nil, monthly: nil, yearly: nil)
        dismiss()
    }
}

// MARK: - Goal Field

struct GoalField: View {
    let label: String
    let placeholder: String
    let max: Int
    @Binding var value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(DS.text)
            Spacer()
            TextField(placeholder, text: $value)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 90)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(DS.accent)
                .onChange(of: value) {
                    if let n = Int(value), n > max { value = "\(max)" }
                }
            Text("/ \(max)")
                .font(.system(size: 12))
                .foregroundColor(DS.text3)
        }
    }
}
