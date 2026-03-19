import SwiftUI

struct TagsView: View {
    @EnvironmentObject var store: AppStore
    @State private var showForm = false
    @State private var editTag: TFTag? = nil
    @State private var addSubtagTo: TFTag? = nil
    @State private var newSubtagName = ""

    var body: some View {
        Group {
            if store.tags.isEmpty {
                EmptyState(icon: "🏷️", title: "No tags", subtitle: "Create tags to organise tasks.",
                           action: { showForm = true }, actionLabel: "New Tag")
            } else {
                List {
                    ForEach(store.tags) { tag in
                        TagRowView(tag: tag, onEdit: { editTag = tag }, onAddSubtag: { addSubtagTo = tag })
                    }
                    .onDelete { idx in
                        idx.forEach { store.deleteTag(store.tags[$0]) }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(DS.bg)
            }
        }
        .navigationTitle("Tags")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showForm = true } label: {
                    Image(systemName: "plus").foregroundColor(DS.accent)
                }
            }
        }
        .sheet(isPresented: $showForm) { TagFormView(mode: .add) }
        .sheet(item: $editTag)        { TagFormView(mode: .edit($0)) }
        .alert("New Subtag", isPresented: Binding(get: { addSubtagTo != nil }, set: { if !$0 { addSubtagTo = nil } })) {
            TextField("Name", text: $newSubtagName)
            Button("Add") {
                guard !newSubtagName.isEmpty, let tag = addSubtagTo else { return }
                store.addSubtag(TFSubtag(name: newSubtagName), to: tag.id)
                newSubtagName = ""
            }
            Button("Cancel", role: .cancel) { newSubtagName = ""; addSubtagTo = nil }
        } message: {
            Text("Enter a name for the subtag under "\(addSubtagTo?.name ?? "")"")
        }
    }
}

struct TagRowView: View {
    @EnvironmentObject var store: AppStore
    let tag: TFTag
    let onEdit: () -> Void
    let onAddSubtag: () -> Void

    var taskCount: Int { store.tasks.filter { $0.tagSelections.contains { $0.tagId == tag.id } }.count }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.sp8) {
            HStack(spacing: DS.sp12) {
                Circle().fill(Color(hex: tag.colorHex)).frame(width: 12, height: 12)
                Text(tag.name).font(.system(size: 15, weight: .semibold)).foregroundColor(DS.text)
                Spacer()
                Text("\(taskCount) task\(taskCount == 1 ? "" : "s")")
                    .font(.system(size: 12)).foregroundColor(DS.text3)
                Button(action: onEdit) {
                    Image(systemName: "pencil").font(.system(size: 12)).foregroundColor(DS.text3)
                }.buttonStyle(.plain)
            }
            if !tag.subtags.isEmpty {
                FlowLayout(spacing: 5) {
                    ForEach(tag.subtags) { sub in
                        SubtagPill(sub: sub, tagColor: tag.colorHex) {
                            store.deleteSubtag(subId: sub.id, tagId: tag.id)
                        }
                    }
                    Button(action: onAddSubtag) {
                        Text("+ subtag")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(DS.text3)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(DS.border2, style: StrokeStyle(lineWidth: 1.5, dash: [4])))
                    }.buttonStyle(.plain)
                }
            } else {
                Button(action: onAddSubtag) {
                    Text("+ Add subtag")
                        .font(.system(size: 12)).foregroundColor(DS.text3)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, DS.sp4)
    }
}

struct SubtagPill: View {
    let sub: TFSubtag; let tagColor: String; let onDelete: () -> Void
    var body: some View {
        HStack(spacing: 4) {
            Text(sub.name).font(.system(size: 11, weight: .medium))
            Button(action: onDelete) {
                Image(systemName: "xmark").font(.system(size: 8, weight: .bold))
            }.buttonStyle(.plain).opacity(0.5)
        }
        .foregroundColor(Color(hex: tagColor))
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(Color(hex: tagColor).opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Simple flow layout for subtag pills

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(subviews: subviews, in: proposal.replacingUnspecifiedDimensions().width)
        return result.size
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(subviews: subviews, in: bounds.width)
        for (idx, frame) in result.frames.enumerated() {
            subviews[idx].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                                proposal: .init(frame.size))
        }
    }
    private func layout(subviews: Subviews, in width: CGFloat) -> (size: CGSize, frames: [CGRect]) {
        var frames: [CGRect] = []; var row: CGFloat = 0; var col: CGFloat = 0; var maxH: CGFloat = 0
        for sv in subviews {
            let size = sv.sizeThatFits(.unspecified)
            if col + size.width > width && col > 0 { row += maxH + spacing; col = 0; maxH = 0 }
            frames.append(CGRect(origin: CGPoint(x: col, y: row), size: size))
            col += size.width + spacing
            maxH = max(maxH, size.height)
        }
        return (CGSize(width: width, height: row + maxH), frames)
    }
}
