import SwiftUI

struct DailyTasksView: View {
    @EnvironmentObject var store: AppStore
    @State private var showAdd = false
    @State private var editTask: TFTask? = nil

    var tasks:   [TFTask] { store.tasksFor(date: store.selectedDate) }
    var pending: [TFTask] { tasks.filter { !$0.isDone } }
    var done:    [TFTask] { tasks.filter {  $0.isDone } }
    var isToday: Bool     { store.selectedDate == .today() }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: DS.sp16) {

                // iOS-only date nav
                #if os(iOS)
                IOSDateNav()
                    .padding(.horizontal, DS.sp16)
                    .padding(.top, DS.sp8)
                #endif

                if tasks.isEmpty {
                    EmptyState(
                        icon: "📋",
                        title: isToday ? "No tasks today" : "Nothing for \(store.selectedDate.shortFormatted())",
                        subtitle: "Tap + to add a task.",
                        action: { showAdd = true },
                        actionLabel: "Add Task"
                    )
                    .frame(minHeight: 340)
                } else {
                    if !pending.isEmpty {
                        VStack(alignment: .leading, spacing: DS.sp8) {
                            SectionHeader(title: "Pending", count: pending.count)
                                .padding(.horizontal, DS.sp16)
                            ForEach(pending) { t in
                                TaskRow(task: t) { editTask = t }
                                    .padding(.horizontal, DS.sp16)
                            }
                        }
                    }
                    if !done.isEmpty {
                        VStack(alignment: .leading, spacing: DS.sp8) {
                            SectionHeader(title: "Completed", count: done.count)
                                .padding(.horizontal, DS.sp16)
                            ForEach(done) { t in
                                TaskRow(task: t) { editTask = t }
                                    .padding(.horizontal, DS.sp16)
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 80)
        }
        .background(DS.bg)
        .navigationTitle(isToday ? "Today" : store.selectedDate.shortFormatted())
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAdd = true } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(DS.accent)
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                Button { Task { await store.pullFromCloud() } } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13))
                        .foregroundColor(DS.text3)
                }
            }
        }
        .sheet(isPresented: $showAdd) { TaskFormView(mode: .add) }
        .sheet(item: $editTask) { TaskFormView(mode: .edit($0)) }
        .refreshable { await store.pullFromCloud() }
    }
}

// MARK: - iOS inline date nav

struct IOSDateNav: View {
    @EnvironmentObject var store: AppStore
    var body: some View {
        HStack(spacing: DS.sp12) {
            navBtn("chevron.left")  { store.selectedDate = store.selectedDate.addingDays(-1) }
            Spacer()
            VStack(spacing: 2) {
                Text(store.selectedDate.longFormatted())
                    .font(.system(size: 13, weight: .semibold)).foregroundColor(DS.text)
                    .lineLimit(1).minimumScaleFactor(0.8)
            }
            Spacer()
            navBtn("chevron.right") { store.selectedDate = store.selectedDate.addingDays(1) }
        }
    }

    @ViewBuilder
    func navBtn(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .frame(width: 32, height: 32)
                .background(DS.card)
                .clipShape(RoundedRectangle(cornerRadius: DS.r6))
                .overlay(RoundedRectangle(cornerRadius: DS.r6).stroke(DS.border, lineWidth: 1))
        }
        .buttonStyle(.plain).foregroundColor(DS.text2)
    }
}

// MARK: - Task Row

struct TaskRow: View {
    @EnvironmentObject var store: AppStore
    let task: TFTask
    let onEdit: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: DS.sp12) {

            // Checkbox
            Button { store.toggleDone(task) } label: {
                RoundedRectangle(cornerRadius: 4)
                    .fill(task.isDone ? DS.accent : DS.card)
                    .frame(width: 18, height: 18)
                    .overlay {
                        if task.isDone {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .bold)).foregroundColor(.white)
                        } else {
                            RoundedRectangle(cornerRadius: 4).stroke(DS.border2, lineWidth: 1.5)
                        }
                    }
            }
            .buttonStyle(.plain)
            .padding(.top, 1)

            VStack(alignment: .leading, spacing: 5) {
                // Title + badge
                HStack(spacing: 6) {
                    Text(task.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(task.isDone ? DS.text3 : DS.text)
                        .strikethrough(task.isDone, color: DS.text3)
                        .lineLimit(2)
                    PriorityBadge(priority: task.priority)
                    Spacer()
                }

                // Notes
                if !task.notes.isEmpty {
                    Text(task.notes)
                        .font(.system(size: 12)).foregroundColor(DS.text3).lineLimit(2)
                }

                // Meta row
                HStack(spacing: 6) {
                    if let t = task.displayTime {
                        HStack(spacing: 3) {
                            Image(systemName: "clock").font(.system(size: 10))
                            Text(t).font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(DS.text3)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(DS.bg2)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
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

            // Edit button
            Button(action: onEdit) {
                Image(systemName: "pencil").font(.system(size: 11))
                    .frame(width: 26, height: 26)
                    .background(DS.bg).clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .buttonStyle(.plain).foregroundColor(DS.text3)
        }
        .padding(DS.sp12)
        .cardStyle()
        .opacity(task.isDone ? 0.5 : 1)
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
