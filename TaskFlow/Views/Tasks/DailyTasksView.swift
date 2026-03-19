import SwiftUI

// MARK: - Daily Tasks View

struct DailyTasksView: View {
    @EnvironmentObject var store: AppStore
    @State private var showAdd        = false
    @State private var editTask: TFTask? = nil
    @State private var showDatePicker = false

    var tasks:   [TFTask] { store.tasksFor(date: store.selectedDate) }
    var pending: [TFTask] { tasks.filter { !$0.isDone } }
    var done:    [TFTask] { tasks.filter {  $0.isDone } }
    var isToday: Bool     { store.selectedDate == .today() }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {

                    #if os(iOS)
                    WeekStrip()
                        .padding(.top, DS.sp8)
                        .padding(.bottom, DS.sp16)
                    #endif

                    if tasks.isEmpty {
                        EmptyState(
                            icon: "checklist",
                            title: isToday ? "No tasks today" : "Nothing for \(store.selectedDate.shortFormatted())",
                            subtitle: "Tap + to add your first task.",
                            action: { showAdd = true },
                            actionLabel: "Add Task"
                        )
                        .frame(minHeight: 300)
                    } else {
                        if !pending.isEmpty {
                            VStack(alignment: .leading, spacing: DS.sp8) {
                                SectionHeader(title: "Pending", count: pending.count)
                                    .padding(.horizontal, DS.sp16)
                                    .padding(.bottom, 2)
                                ForEach(pending) { t in
                                    ImprovedTaskRow(task: t) { editTask = t }
                                        .padding(.horizontal, DS.sp16)
                                        .padding(.bottom, DS.sp8)
                                }
                            }
                            .padding(.top, DS.sp4)
                        }
                        if !done.isEmpty {
                            VStack(alignment: .leading, spacing: DS.sp8) {
                                SectionHeader(title: "Completed", count: done.count)
                                    .padding(.horizontal, DS.sp16)
                                    .padding(.bottom, 2)
                                ForEach(done) { t in
                                    ImprovedTaskRow(task: t) { editTask = t }
                                        .padding(.horizontal, DS.sp16)
                                        .padding(.bottom, DS.sp8)
                                }
                            }
                            .padding(.top, DS.sp8)
                        }
                    }
                }
                .padding(.bottom, 100)
            }
            .background(DS.bg)

            // Floating add button
            Button { showAdd = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(DS.accent)
                    .clipShape(Circle())
                    .shadow(color: DS.accent.opacity(0.35), radius: 12, x: 0, y: 4)
            }
            .padding(.trailing, DS.sp20)
            .padding(.bottom, DS.sp24)
        }
        .navigationTitle(isToday ? "Today" : store.selectedDate.shortFormatted())
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if !isToday {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            store.selectedDate = .today()
                        }
                    } label: {
                        Text("Today")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(DS.accent)
                    }
                }
                Button { showDatePicker = true } label: {
                    Image(systemName: "calendar")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(DS.accent)
                }
            }
        }
        .sheet(isPresented: $showAdd)        { TaskFormView(mode: .add) }
        .sheet(item: $editTask)              { TaskFormView(mode: .edit($0)) }
        .sheet(isPresented: $showDatePicker) { DatePickerSheet() }
    }
}

// MARK: - Date Picker Sheet

struct DatePickerSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss
    @State private var picked: Date = Date()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DatePicker("", selection: $picked, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(DS.accent)
                    .padding(DS.sp16)

                Divider()

                let dateStr = dateString(picked)
                let count   = store.taskCount(for: dateStr)
                if count > 0 {
                    HStack(spacing: DS.sp8) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 13))
                            .foregroundColor(DS.accent)
                        Text("\(count) task\(count == 1 ? "" : "s") on this day")
                            .font(.system(size: 13))
                            .foregroundColor(DS.text2)
                        Spacer()
                    }
                    .padding(.horizontal, DS.sp20)
                    .padding(.vertical, DS.sp12)
                }
                Spacer()
            }
            .background(DS.bg)
            .navigationTitle("Go to Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(DS.text3)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Go") {
                        withAnimation(.spring(response: 0.3)) {
                            store.selectedDate = dateString(picked)
                        }
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(DS.accent)
                }
            }
        }
        .onAppear { picked = store.selectedDate.toDate() ?? Date() }
    }

    private func dateString(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: d)
    }
}

// MARK: - Week Strip

struct WeekStrip: View {
    @EnvironmentObject var store: AppStore

    private var days: [String] {
        let today = String.today()
        return (-21...7).map { today.addingDays($0) }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(days, id: \.self) { day in
                        DayCell(day: day, isSelected: store.selectedDate == day) {
                            withAnimation(.spring(response: 0.3)) {
                                store.selectedDate = day
                            }
                        }
                        .id(day)
                    }
                }
                .padding(.horizontal, DS.sp16)
            }
            .onAppear {
                proxy.scrollTo(store.selectedDate, anchor: .center)
            }
            .onChange(of: store.selectedDate) {
                withAnimation { proxy.scrollTo(store.selectedDate, anchor: .center) }
            }
        }
    }
}

struct DayCell: View {
    @EnvironmentObject var store: AppStore
    let day: String
    let isSelected: Bool
    let onTap: () -> Void

    private var isToday: Bool { day == .today() }
    private var taskCount: Int { store.taskCount(for: day) }
    private var doneCount: Int { store.tasks.filter { $0.date == day && $0.isDone }.count }

    private var dayNum: String {
        let f = DateFormatter(); f.dateFormat = "d"
        return day.toDate().map { f.string(from: $0) } ?? ""
    }
    private var dayName: String {
        let f = DateFormatter(); f.dateFormat = "EEE"
        return day.toDate().map { f.string(from: $0) } ?? ""
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(dayName.uppercased())
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? DS.accent : DS.text3)

                ZStack {
                    RoundedRectangle(cornerRadius: DS.r8)
                        .fill(isSelected ? DS.accent : (isToday ? DS.accentBg : DS.card))
                        .frame(width: 40, height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.r8)
                                .stroke(isToday && !isSelected ? DS.accent.opacity(0.4) : Color.clear, lineWidth: 1.5)
                        )
                    Text(dayNum)
                        .font(.system(size: 16, weight: isSelected || isToday ? .semibold : .regular))
                        .foregroundColor(isSelected ? .white : (isToday ? DS.accent : DS.text))
                }

                if taskCount > 0 {
                    HStack(spacing: 2) {
                        ForEach(0..<min(taskCount, 3), id: \.self) { i in
                            Circle()
                                .fill(i < doneCount
                                    ? (isSelected ? Color.white.opacity(0.6) : DS.green.opacity(0.7))
                                    : (isSelected ? Color.white.opacity(0.9) : DS.accent.opacity(0.7)))
                                .frame(width: 4, height: 4)
                        }
                    }
                } else {
                    Color.clear.frame(height: 4)
                }
            }
            .frame(width: 44)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Improved Task Row

struct ImprovedTaskRow: View {
    @EnvironmentObject var store: AppStore
    let task: TFTask
    let onEdit: () -> Void

    private var priorityColor: Color {
        switch task.priority {
        case .critical: return Color(hex: "#DC2626")
        case .high:     return Color(hex: "#EA580C")
        case .medium:   return DS.accent
        case .low:      return Color(hex: "#059669")
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {

            RoundedRectangle(cornerRadius: 2)
                .fill(task.isDone ? DS.border : priorityColor)
                .frame(width: 3)
                .padding(.vertical, DS.sp12)
                .padding(.leading, DS.sp10)

            Button { store.toggleDone(task) } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(task.isDone ? DS.accentBg : Color.clear)
                        .frame(width: 24, height: 24)
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(task.isDone ? DS.accent : DS.border2, lineWidth: 1.5)
                        .frame(width: 24, height: 24)
                    if task.isDone {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(DS.accent)
                    }
                }
            }
            .buttonStyle(.plain)
            .padding(.leading, DS.sp10)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(task.isDone ? DS.text3 : DS.text)
                    .strikethrough(task.isDone, color: DS.text3)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if !task.notes.isEmpty && !task.isDone {
                    Text(task.notes)
                        .font(.system(size: 12))
                        .foregroundColor(DS.text3)
                        .lineLimit(1)
                }

                if task.displayTime != nil || !task.tagSelections.isEmpty {
                    HStack(spacing: 6) {
                        if let t = task.displayTime {
                            HStack(spacing: 3) {
                                Image(systemName: "clock").font(.system(size: 10))
                                Text(t).font(.system(size: 11, weight: .medium))
                            }
                            .foregroundColor(DS.text3)
                        }
                        ForEach(task.tagSelections, id: \.tagId) { sel in
                            if let tag = store.tags.first(where: { $0.id == sel.tagId }) {
                                let subs = sel.subtagIds.compactMap { id in
                                    tag.subtags.first { $0.id == id }?.name
                                }
                                TagChip(tag: tag, subNames: subs)
                            }
                        }
                    }
                }
            }
            .padding(.leading, DS.sp10)
            .padding(.vertical, DS.sp12)

            Spacer(minLength: 4)

            Button(action: onEdit) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(DS.border2)
                    .padding(.trailing, DS.sp12)
            }
            .buttonStyle(.plain)
        }
        .background(DS.card)
        .clipShape(RoundedRectangle(cornerRadius: DS.r10))
        .overlay(RoundedRectangle(cornerRadius: DS.r10).stroke(DS.border, lineWidth: 1))
        .opacity(task.isDone ? 0.6 : 1)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) { store.deleteTask(task) } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button { store.toggleDone(task) } label: {
                Label(task.isDone ? "Undo" : "Done",
                      systemImage: task.isDone ? "arrow.uturn.left" : "checkmark")
            }
            .tint(DS.accent)
        }
        .contextMenu {
            Button { store.toggleDone(task) } label: {
                Label(task.isDone ? "Mark pending" : "Mark done",
                      systemImage: task.isDone ? "circle" : "checkmark.circle")
            }
            Button { onEdit() } label: { Label("Edit", systemImage: "pencil") }
            Divider()
            Button(role: .destructive) { store.deleteTask(task) } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Legacy shims

struct TaskRow: View {
    @EnvironmentObject var store: AppStore
    let task: TFTask
    let onEdit: () -> Void
    var body: some View { ImprovedTaskRow(task: task, onEdit: onEdit) }
}

struct IOSDateNav: View {
    @EnvironmentObject var store: AppStore
    var body: some View { WeekStrip() }
}
