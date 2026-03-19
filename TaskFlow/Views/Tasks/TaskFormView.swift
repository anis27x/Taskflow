import SwiftUI

enum TaskFormMode { case add; case edit(TFTask) }

struct TaskFormView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss

    let mode: TaskFormMode

    @State private var title    = ""
    @State private var notes    = ""
    @State private var date     = String.today()
    @State private var priority = Priority.medium
    @State private var isDone   = false
    @State private var selTags: [TaskTagSel] = []

    @State private var hasTime  = false
    @State private var startH   = 9;  @State private var startM = 0; @State private var startPM = false
    @State private var endH     = 10; @State private var endM   = 0; @State private var endPM   = false

    @FocusState private var titleFocused: Bool

    private var editing: TFTask? { if case .edit(let t) = mode { return t }; return nil }
    private var canSave: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.sp16) {

                    // Title card
                    VStack(alignment: .leading, spacing: DS.sp8) {
                        FieldLabel(text: "Task title")
                        TextField("What do you need to do?", text: $title, axis: .vertical)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(DS.text)
                            .lineLimit(1...3)
                            .focused($titleFocused)
                            .padding(DS.sp12)
                            .background(DS.bg2)
                            .clipShape(RoundedRectangle(cornerRadius: DS.r8))

                        TextField("Notes (optional)", text: $notes, axis: .vertical)
                            .font(.system(size: 14))
                            .foregroundColor(DS.text2)
                            .lineLimit(1...4)
                            .padding(DS.sp12)
                            .background(DS.bg2)
                            .clipShape(RoundedRectangle(cornerRadius: DS.r8))
                    }
                    .padding(DS.sp16)
                    .background(DS.card)
                    .clipShape(RoundedRectangle(cornerRadius: DS.r12))
                    .overlay(RoundedRectangle(cornerRadius: DS.r12).stroke(DS.border, lineWidth: 1))

                    // Date + Priority row
                    HStack(spacing: DS.sp12) {
                        // Date
                        VStack(alignment: .leading, spacing: DS.sp8) {
                            FieldLabel(text: "Date")
                            DatePicker("", selection: Binding(
                                get: { date.toDate() ?? Date() },
                                set: {
                                    let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
                                    date = f.string(from: $0)
                                }
                            ), displayedComponents: .date)
                            .labelsHidden()
                            .tint(DS.accent)
                        }
                        .padding(DS.sp12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(DS.card)
                        .clipShape(RoundedRectangle(cornerRadius: DS.r12))
                        .overlay(RoundedRectangle(cornerRadius: DS.r12).stroke(DS.border, lineWidth: 1))

                        // Priority
                        VStack(alignment: .leading, spacing: DS.sp8) {
                            FieldLabel(text: "Priority")
                            Menu {
                                ForEach(Priority.allCases, id: \.self) { p in
                                    Button {
                                        withAnimation { priority = p }
                                    } label: {
                                        Label(p.label, systemImage: priority == p ? "checkmark" : "")
                                    }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(priorityColor(priority))
                                        .frame(width: 8, height: 8)
                                    Text(priority.label)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(DS.text)
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 10))
                                        .foregroundColor(DS.text3)
                                }
                            }
                        }
                        .padding(DS.sp12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(DS.card)
                        .clipShape(RoundedRectangle(cornerRadius: DS.r12))
                        .overlay(RoundedRectangle(cornerRadius: DS.r12).stroke(DS.border, lineWidth: 1))
                    }

                    // Time range
                    VStack(alignment: .leading, spacing: DS.sp12) {
                        HStack {
                            FieldLabel(text: "Time range")
                            Spacer()
                            Toggle("", isOn: $hasTime.animation(.spring(response: 0.3)))
                                .tint(DS.accent)
                                .labelsHidden()
                        }
                        if hasTime {
                            Divider()
                            HStack(spacing: DS.sp12) {
                                CompactTimePicker(label: "Start", h: $startH, m: $startM, pm: $startPM)
                                Text("→")
                                    .font(.system(size: 16))
                                    .foregroundColor(DS.text3)
                                CompactTimePicker(label: "End", h: $endH, m: $endM, pm: $endPM)
                            }
                        }
                    }
                    .padding(DS.sp16)
                    .background(DS.card)
                    .clipShape(RoundedRectangle(cornerRadius: DS.r12))
                    .overlay(RoundedRectangle(cornerRadius: DS.r12).stroke(DS.border, lineWidth: 1))

                    // Tags
                    if !store.tags.isEmpty {
                        VStack(alignment: .leading, spacing: DS.sp12) {
                            FieldLabel(text: "Tags")
                            FlowTagPicker(tags: store.tags, selTags: $selTags)
                        }
                        .padding(DS.sp16)
                        .background(DS.card)
                        .clipShape(RoundedRectangle(cornerRadius: DS.r12))
                        .overlay(RoundedRectangle(cornerRadius: DS.r12).stroke(DS.border, lineWidth: 1))
                    }

                    // Done toggle (edit only)
                    if editing != nil {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Mark as done")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(DS.text)
                                Text("Task will move to completed")
                                    .font(.system(size: 12))
                                    .foregroundColor(DS.text3)
                            }
                            Spacer()
                            Toggle("", isOn: $isDone).tint(DS.accent).labelsHidden()
                        }
                        .padding(DS.sp16)
                        .background(DS.card)
                        .clipShape(RoundedRectangle(cornerRadius: DS.r12))
                        .overlay(RoundedRectangle(cornerRadius: DS.r12).stroke(DS.border, lineWidth: 1))
                    }
                }
                .padding(DS.sp16)
                .padding(.bottom, DS.sp24)
            }
            .background(DS.bg)
            .navigationTitle(editing == nil ? "New Task" : "Edit Task")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(DS.text3)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(canSave ? DS.accent : DS.text3)
                        .disabled(!canSave)
                }
            }
        }
        .onAppear {
            populate()
            if editing == nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    titleFocused = true
                }
            }
        }
    }

    // MARK: - Helpers

    private func priorityColor(_ p: Priority) -> Color {
        switch p {
        case .critical: return Color(hex: "#DC2626")
        case .high:     return Color(hex: "#EA580C")
        case .medium:   return DS.accent
        case .low:      return Color(hex: "#059669")
        }
    }

    private func populate() {
        guard let t = editing else { date = store.selectedDate; return }
        title    = t.title
        notes    = t.notes
        date     = t.date
        priority = t.priority
        isDone   = t.isDone
        selTags  = t.tagSelections
        if let s = t.timeStart {
            hasTime = true
            let (h, m, pm) = parse24(s)
            startH = h; startM = m; startPM = pm
        }
        if let e = t.timeEnd {
            let (h, m, pm) = parse24(e)
            endH = h; endM = m; endPM = pm
        }
    }

    private func parse24(_ s: String) -> (Int, Int, Bool) {
        let parts = s.split(separator: ":").compactMap { Int($0) }
        let h = parts.count > 0 ? parts[0] : 0
        let m = parts.count > 1 ? parts[1] : 0
        let pm = h >= 12
        let displayH = h == 0 ? 12 : (h > 12 ? h - 12 : h)
        return (displayH, m, pm)
    }

    private func to24(_ h: Int, _ m: Int, _ pm: Bool) -> String {
        var hh = h
        if !pm && h == 12 { hh = 0 }
        if  pm && h != 12 { hh = h + 12 }
        return String(format: "%02d:%02d", hh, m)
    }

    private func save() {
        let t = title.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        let ts = hasTime ? to24(startH, startM, startPM) : nil
        let te = hasTime ? to24(endH,   endM,   endPM)   : nil

        if var ex = editing {
            ex.title = t; ex.notes = notes; ex.date = date
            ex.priority = priority; ex.isDone = isDone
            ex.timeStart = ts; ex.timeEnd = te; ex.tagSelections = selTags
            store.updateTask(ex)
        } else {
            store.addTask(TFTask(title: t, notes: notes, date: date,
                                  timeStart: ts, timeEnd: te,
                                  priority: priority, tagSelections: selTags))
        }
        dismiss()
    }
}

// MARK: - Compact Time Picker

struct CompactTimePicker: View {
    let label: String
    @Binding var h: Int
    @Binding var m: Int
    @Binding var pm: Bool

    let hours   = Array(1...12)
    let minutes = stride(from: 0, to: 60, by: 5).map { $0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(DS.text3)
            HStack(spacing: 0) {
                Picker("", selection: $h) {
                    ForEach(hours, id: \.self) { Text("\($0)").tag($0) }
                }.pickerStyle(.wheel).frame(width: 50, height: 80).clipped()

                Text(":").font(.system(size: 16, weight: .semibold))
                    .foregroundColor(DS.text2)

                Picker("", selection: $m) {
                    ForEach(minutes, id: \.self) { Text(String(format: "%02d", $0)).tag($0) }
                }.pickerStyle(.wheel).frame(width: 54, height: 80).clipped()

                Picker("", selection: $pm) {
                    Text("AM").tag(false)
                    Text("PM").tag(true)
                }.pickerStyle(.wheel).frame(width: 54, height: 80).clipped()
            }
            .background(DS.bg2)
            .clipShape(RoundedRectangle(cornerRadius: DS.r8))
        }
    }
}

// MARK: - Flow Tag Picker (replaces per-row toggles)

struct FlowTagPicker: View {
    @EnvironmentObject var store: AppStore
    let tags: [TFTag]
    @Binding var selTags: [TaskTagSel]

    @State private var expandedTag: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: DS.sp10) {
            // Tag chips row
            FlowLayout(spacing: 8) {
                ForEach(tags) { tag in
                    let isOn = selTags.contains { $0.tagId == tag.id }
                    Button {
                        withAnimation(.spring(response: 0.25)) {
                            if isOn {
                                selTags.removeAll { $0.tagId == tag.id }
                                if expandedTag == tag.id { expandedTag = nil }
                            } else {
                                selTags.append(TaskTagSel(tagId: tag.id))
                                if !tag.subtags.isEmpty { expandedTag = tag.id }
                            }
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(isOn ? Color(hex: tag.colorHex) : DS.border2)
                                .frame(width: 7, height: 7)
                            Text(tag.name)
                                .font(.system(size: 13, weight: isOn ? .semibold : .regular))
                                .foregroundColor(isOn ? Color(hex: tag.colorHex) : DS.text2)
                        }
                        .padding(.horizontal, DS.sp10)
                        .padding(.vertical, 7)
                        .background(isOn ? Color(hex: tag.colorHex).opacity(0.1) : DS.bg2)
                        .clipShape(RoundedRectangle(cornerRadius: DS.r6))
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.r6)
                                .stroke(isOn ? Color(hex: tag.colorHex).opacity(0.4) : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Subtag picker for expanded tag
            ForEach(tags) { tag in
                let isOn = selTags.contains { $0.tagId == tag.id }
                if isOn && !tag.subtags.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Subtags for \(tag.name)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(DS.text3)
                        FlowLayout(spacing: 6) {
                            ForEach(tag.subtags) { sub in
                                let picked = selTags.first(where: { $0.tagId == tag.id })?.subtagIds.contains(sub.id) ?? false
                                Button {
                                    guard let i = selTags.firstIndex(where: { $0.tagId == tag.id }) else { return }
                                    if picked { selTags[i].subtagIds.removeAll { $0 == sub.id } }
                                    else      { selTags[i].subtagIds.append(sub.id) }
                                } label: {
                                    Text(sub.name)
                                        .font(.system(size: 12, weight: picked ? .semibold : .regular))
                                        .foregroundColor(picked ? Color(hex: tag.colorHex) : DS.text3)
                                        .padding(.horizontal, 9).padding(.vertical, 5)
                                        .background(picked ? Color(hex: tag.colorHex).opacity(0.1) : DS.bg2)
                                        .clipShape(RoundedRectangle(cornerRadius: DS.r6))
                                        .overlay(RoundedRectangle(cornerRadius: DS.r6)
                                            .stroke(picked ? Color(hex: tag.colorHex).opacity(0.3) : Color.clear, lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
    }
}

// MARK: - Legacy shims

struct WheelTimePicker: View {
    let label: String
    @Binding var h: Int
    @Binding var m: Int
    @Binding var pm: Bool
    var body: some View { CompactTimePicker(label: label, h: $h, m: $m, pm: $pm) }
}

struct TagToggleRow: View {
    @EnvironmentObject var store: AppStore
    let tag: TFTag
    @Binding var selTags: [TaskTagSel]
    var body: some View { EmptyView() }
}
