import SwiftUI

enum TagFormMode { case add; case edit(TFTag) }

struct TagFormView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) var dismiss

    let mode: TagFormMode
    @State private var name = ""
    @State private var hex  = TFTag.palette[0]

    private var editing: TFTag? { if case .edit(let t) = mode { return t }; return nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Workout, Work, Health", text: $name)
                }
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 5), spacing: DS.sp12) {
                        ForEach(TFTag.palette, id: \.self) { c in
                            Circle()
                                .fill(Color(hex: c))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle().stroke(Color.white, lineWidth: hex == c ? 3 : 0)
                                        .shadow(color: .black.opacity(0.2), radius: 2)
                                )
                                .scaleEffect(hex == c ? 1.15 : 1)
                                .animation(.spring(response: 0.2), value: hex)
                                .onTapGesture { hex = c }
                        }
                    }
                    .padding(.vertical, DS.sp8)
                }

                // Preview
                Section("Preview") {
                    HStack(spacing: DS.sp12) {
                        Circle().fill(Color(hex: hex)).frame(width: 12, height: 12)
                        Text(name.isEmpty ? "Tag name" : name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(name.isEmpty ? DS.text3 : DS.text)
                        Spacer()
                        TagChip(tag: TFTag(name: name.isEmpty ? "Tag" : name, colorHex: hex), subNames: [])
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(DS.bg)
            .navigationTitle(editing == nil ? "New Tag" : "Edit Tag")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(DS.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(name.trimmingCharacters(in: .whitespaces).isEmpty ? DS.text3 : DS.accent)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .onAppear {
            if let t = editing { name = t.name; hex = t.colorHex }
        }
    }

    private func save() {
        let n = name.trimmingCharacters(in: .whitespaces); guard !n.isEmpty else { return }
        if var t = editing { t.name = n; t.colorHex = hex; store.updateTag(t) }
        else { store.addTag(TFTag(name: n, colorHex: hex)) }
        dismiss()
    }
}
