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

    @State private var hasTime   = false
    @State private var startH    = 9;  @State private var startM = 0; @State private var startPM = false
    @State private var endH      = 10; @State private var endM   = 0; @State private var endPM   = false

    private var editing: TFTask? { if case .edit(let t) = mode { return t }; return nil }

    var body: some View {
        NavigationStack {
            Form {
                // Basic info
                Section("Task") {
                    TextField("Title *", text: $title)
                        .font(.system(size: 15, weight: .semibold))
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }

                // Date + priority
                Section("Schedule") {
                    DatePicker("Date", selection: Binding(
                        get: { date.toDate() ?? Date() },
                        set: {
                            let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
                            date = f.string(from: $0)
                        }
                    ), displayedComponents: .date)
                    .tint(DS.accent)

                    Picker("Priority", selection: $priority) {
                        ForEach(Priority.allCases, id: \.self) { Text($0.label).tag($0) }
                    }
                }

                // Time range
                Section {
                    Toggle("Set time range", isOn: $hasTime.animation())
                        .tint(DS.accent)
                    if hasTime {
                        WheelTimePicker(label: "Start", h: $startH, m: $startM, pm: $startPM)
                        WheelTimePicker(label: "End",   h: $endH,   m: $endM,   pm: $endPM)
                    }
                } header: { Text("Time") }

                // Tags
                Section("Tags") {
                    if store.tags.isEmpty {
                        Text("No tags — create some in the Tags tab.")
                            .foregroundColor(DS.text3).font(.system(size: 13))
                    }
                    ForEach(store.tags) { tag in
                        TagToggleRow(tag: tag, selTags: $selTags)
                    }
                }

                // Done toggle (edit only)
                if editing != nil {
                    Section {
                        Toggle("Mark as done", isOn: $isDone).tint(DS.accent)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(DS.bg)
            .navigationTitle(editing == nil ? "New Task" : "Edit Task")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(DS.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(title.trimmingCharacters(in: .whitespaces).isEmpty ? DS.text3 : DS.accent)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .onAppear(perform: populate)
    }

    // MARK: - Populate from existing

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

// MARK: - Wheel time picker

struct WheelTimePicker: View {
    let label: String
    @Binding var h: Int
    @Binding var m: Int
    @Binding var pm: Bool

    let hours   = Array(1...12)
    let minutes = stride(from: 0, to: 60, by: 5).map { $0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .medium)).tracking(0.6).foregroundColor(DS.text3)
            HStack(spacing: 0) {
                Picker("", selection: $h) {
                    ForEach(hours, id: \.self) { Text("\($0)").tag($0) }
                }.pickerStyle(.wheel).frame(width: 58, height: 96).clipped()

                Text(":").font(.system(size: 18, weight: .semibold))
                    .foregroundColor(DS.text2).padding(.horizontal, 2)

                Picker("", selection: $m) {
                    ForEach(minutes, id: \.self) { Text(String(format: "%02d", $0)).tag($0) }
                }.pickerStyle(.wheel).frame(width: 62, height: 96).clipped()

                Picker("", selection: $pm) {
                    Text("AM").tag(false)
                    Text("PM").tag(true)
                }.pickerStyle(.wheel).frame(width: 62, height: 96).clipped()
            }
            .background(DS.bg2).clipShape(RoundedRectangle(cornerRadius: DS.r8))
        }
    }
}

// MARK: - Tag toggle row

struct TagToggleRow: View {
    @EnvironmentObject var store: AppStore
    let tag: TFTag
    @Binding var selTags: [TaskTagSel]

    @State private var expanded = false

    var selIdx: Int? { selTags.firstIndex { $0.tagId == tag.id } }
    var isOn:   Bool { selIdx != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle().fill(Color(hex: tag.colorHex)).frame(width: 10, height: 10)
                Text(tag.name).font(.system(size: 14)).foregroundColor(DS.text)
                Spacer()
                if isOn && !tag.subtags.isEmpty {
                    Button(expanded ? "Less" : "Subtags") { withAnimation { expanded.toggle() } }
                        .font(.system(size: 12)).foregroundColor(DS.accent)
                }
                Toggle("", isOn: Binding(
                    get: { isOn },
                    set: { on in
                        if on { selTags.append(TaskTagSel(tagId: tag.id)) }
                        else  { selTags.removeAll { $0.tagId == tag.id }; expanded = false }
                    }
                )).tint(DS.accent).labelsHidden()
            }
            if isOn && expanded && !tag.subtags.isEmpty {
                ForEach(tag.subtags) { sub in
                    let picked = selIdx.map { selTags[$0].subtagIds.contains(sub.id) } ?? false
                    HStack {
                        Text(sub.name)
                            .font(.system(size: 13))
                            .foregroundColor(picked ? Color(hex: tag.colorHex) : DS.text3)
                            .padding(.leading, 20)
                        Spacer()
                        if picked {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color(hex: tag.colorHex))
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard let i = selIdx else { return }
                        if picked { selTags[i].subtagIds.removeAll { $0 == sub.id } }
                        else      { selTags[i].subtagIds.append(sub.id) }
                    }
                }
            }
        }
    }
}
