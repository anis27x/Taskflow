import SwiftUI
import UniformTypeIdentifiers

// MARK: - Backup data types
// Declared at file scope (not inside any @MainActor type) so Codable conformances
// are fully nonisolated and can be used by FileDocument without warnings.

struct BackupSnapshot: Codable {
    var tags:       [TFTag]
    var tasks:      [TFTask]
    var goals:      [TFGoal]
    var exportedAt: Date   = Date()
    var appVersion: String = "1.0"
}

struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var snapshot: BackupSnapshot

    init(snapshot: BackupSnapshot) {
        self.snapshot = snapshot
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.snapshot = try decoder.decode(BackupSnapshot.self, from: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.outputFormatting    = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(snapshot)
        return FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Backup View

struct BackupView: View {
    @EnvironmentObject var store: AppStore

    @State private var showExporter      = false
    @State private var showImporter      = false
    @State private var showImportConfirm = false
    @State private var pendingImport: BackupSnapshot? = nil
    @State private var exportSnapshot:  BackupSnapshot? = nil
    @State private var toast: ToastMessage? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: DS.sp16) {

                // Summary card
                VStack(alignment: .leading, spacing: DS.sp12) {
                    FieldLabel(text: "Your data")
                    HStack(spacing: 0) {
                        SummaryItem(value: "\(store.tags.count)",  label: "Tags")
                        Divider().frame(height: 36)
                        SummaryItem(value: "\(store.tasks.count)", label: "Tasks")
                        Divider().frame(height: 36)
                        SummaryItem(value: "\(store.goals.count)", label: "Goals")
                    }
                }
                .padding(DS.sp16)
                .background(DS.card)
                .clipShape(RoundedRectangle(cornerRadius: DS.r12))
                .overlay(RoundedRectangle(cornerRadius: DS.r12).stroke(DS.border, lineWidth: 1))

                // Export
                VStack(alignment: .leading, spacing: DS.sp12) {
                    FieldLabel(text: "Export")
                    VStack(alignment: .leading, spacing: DS.sp8) {
                        Text("Save a backup file")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(DS.text)
                        Text("Exports all your tags, tasks, and goals as a JSON file. Save it to Files, AirDrop it, or email it to yourself.")
                            .font(.system(size: 13))
                            .foregroundColor(DS.text3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Button {
                        // Capture data on main thread before FileDocument takes over
                        exportSnapshot = BackupSnapshot(
                            tags:  store.tags,
                            tasks: store.tasks,
                            goals: store.goals
                        )
                        showExporter = true
                    } label: {
                        HStack(spacing: DS.sp8) {
                            Image(systemName: "arrow.up.doc")
                                .font(.system(size: 14, weight: .medium))
                            Text("Export Backup")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DS.sp12)
                        .background(DS.accent)
                        .clipShape(RoundedRectangle(cornerRadius: DS.r8))
                    }
                    .buttonStyle(.plain)
                }
                .padding(DS.sp16)
                .background(DS.card)
                .clipShape(RoundedRectangle(cornerRadius: DS.r12))
                .overlay(RoundedRectangle(cornerRadius: DS.r12).stroke(DS.border, lineWidth: 1))

                // Import
                VStack(alignment: .leading, spacing: DS.sp12) {
                    FieldLabel(text: "Import")
                    VStack(alignment: .leading, spacing: DS.sp8) {
                        Text("Restore from a backup file")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(DS.text)
                        Text("Pick a previously exported TaskFlow JSON file. Your current data will be replaced.")
                            .font(.system(size: 13))
                            .foregroundColor(DS.text3)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: DS.sp8) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 11))
                                .foregroundColor(Color(hex: "#EA580C"))
                            Text("This will overwrite your current data.")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(hex: "#EA580C"))
                        }
                        .padding(.horizontal, DS.sp10)
                        .padding(.vertical, DS.sp8)
                        .background(Color(hex: "#EA580C").opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: DS.r6))
                    }
                    Button { showImporter = true } label: {
                        HStack(spacing: DS.sp8) {
                            Image(systemName: "arrow.down.doc")
                                .font(.system(size: 14, weight: .medium))
                            Text("Import Backup")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(DS.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DS.sp12)
                        .background(DS.accentBg)
                        .clipShape(RoundedRectangle(cornerRadius: DS.r8))
                        .overlay(RoundedRectangle(cornerRadius: DS.r8)
                            .stroke(DS.accent.opacity(0.3), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                .padding(DS.sp16)
                .background(DS.card)
                .clipShape(RoundedRectangle(cornerRadius: DS.r12))
                .overlay(RoundedRectangle(cornerRadius: DS.r12).stroke(DS.border, lineWidth: 1))

                // Tips
                VStack(alignment: .leading, spacing: DS.sp8) {
                    FieldLabel(text: "How to keep your data safe")
                    VStack(alignment: .leading, spacing: DS.sp10) {
                        TipRow(number: "1", text: "Tap Export Backup before updating or deleting the app.")
                        TipRow(number: "2", text: "Save the file to iCloud Drive or email it to yourself.")
                        TipRow(number: "3", text: "After reinstalling, tap Import Backup and pick the file.")
                    }
                }
                .padding(DS.sp16)
                .background(DS.bg2)
                .clipShape(RoundedRectangle(cornerRadius: DS.r12))
            }
            .padding(DS.sp16)
            .padding(.bottom, DS.sp24)
        }
        .background(DS.bg)
        .navigationTitle("Backup & Restore")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif

        // Toast
        .overlay(alignment: .bottom) {
            if let t = toast {
                ToastView(message: t)
                    .padding(.bottom, DS.sp24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4), value: toast?.id)

        // Export — uses plain .json, no custom UTType needed
        .fileExporter(
            isPresented: $showExporter,
            document: exportSnapshot.map { BackupDocument(snapshot: $0) },
            contentType: .json,
            defaultFilename: defaultFilename()
        ) { result in
            exportSnapshot = nil
            switch result {
            case .success:
                showToast(icon: "checkmark.circle.fill", message: "Backup saved successfully", color: DS.green)
            case .failure(let e):
                showToast(icon: "xmark.circle.fill", message: "Export failed: \(e.localizedDescription)", color: DS.red)
            }
        }

        // Import picker
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                loadImport(url: url)
            case .failure(let e):
                showToast(icon: "xmark.circle.fill", message: "Could not open file: \(e.localizedDescription)", color: DS.red)
            }
        }

        // Confirm before replacing
        .confirmationDialog(
            "Replace all data with this backup?",
            isPresented: $showImportConfirm,
            titleVisibility: .visible
        ) {
            Button("Replace Data", role: .destructive) {
                if let snap = pendingImport { applyImport(snap) }
            }
            Button("Cancel", role: .cancel) { pendingImport = nil }
        } message: {
            if let snap = pendingImport {
                Text("This will replace your \(store.tags.count) tags and \(store.tasks.count) tasks with \(snap.tags.count) tags and \(snap.tasks.count) tasks from the backup.")
            }
        }
    }

    // MARK: - Helpers

    private func defaultFilename() -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return "TaskFlow-backup-\(f.string(from: Date()))"
    }

    private func loadImport(url: URL) {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        do {
            let data    = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let snapshot = try decoder.decode(BackupSnapshot.self, from: data)
            pendingImport    = snapshot
            showImportConfirm = true
        } catch {
            showToast(icon: "xmark.circle.fill", message: "Invalid backup file", color: DS.red)
        }
    }

    private func applyImport(_ snap: BackupSnapshot) {
        store.tags  = snap.tags
        store.tasks = snap.tasks
        store.goals = snap.goals
        store.persist()
        pendingImport = nil
        showToast(icon: "checkmark.circle.fill", message: "Data restored successfully", color: DS.green)
    }

    private func showToast(icon: String, message: String, color: Color) {
        toast = ToastMessage(icon: icon, message: message, color: color)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { toast = nil }
    }
}

// MARK: - Supporting views

struct SummaryItem: View {
    let value: String; let label: String
    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(DS.text)
            Text(label.uppercased())
                .font(.system(size: 10, weight: .medium))
                .tracking(0.5)
                .foregroundColor(DS.text3)
        }
        .frame(maxWidth: .infinity)
    }
}

struct TipRow: View {
    let number: String; let text: String
    var body: some View {
        HStack(alignment: .top, spacing: DS.sp10) {
            Text(number)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(DS.accent)
                .frame(width: 18, height: 18)
                .background(DS.accentBg)
                .clipShape(Circle())
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(DS.text2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct ToastMessage: Identifiable, Equatable {
    let id      = UUID()
    let icon:    String
    let message: String
    let color:   Color
}

struct ToastView: View {
    let message: ToastMessage
    var body: some View {
        HStack(spacing: DS.sp10) {
            Image(systemName: message.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(message.color)
            Text(message.message)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(DS.text)
        }
        .padding(.horizontal, DS.sp16)
        .padding(.vertical, DS.sp12)
        .background(DS.card)
        .clipShape(RoundedRectangle(cornerRadius: DS.r10))
        .overlay(RoundedRectangle(cornerRadius: DS.r10).stroke(DS.border, lineWidth: 1))
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}
