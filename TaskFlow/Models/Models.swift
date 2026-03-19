import Foundation
import SwiftUI

// MARK: - Tag

struct TFTag: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var name: String
    var colorHex: String
    var subtags: [TFSubtag] = []
    var createdAt: Date = Date()

    var swiftUIColor: Color { Color(hex: colorHex) }

    static let palette: [String] = [
        "#A8977A", "#DC2626", "#059669", "#2563EB",
        "#7C3AED", "#0891B2", "#EA580C", "#BE185D", "#4F46E5", "#0D9488"
    ]
}

struct TFSubtag: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var name: String
}

// MARK: - Priority

enum Priority: String, Codable, CaseIterable {
    case low, medium, high, critical

    var label: String {
        switch self {
        case .low:      return "Low"
        case .medium:   return "Medium"
        case .high:     return "High"
        case .critical: return "Critical"
        }
    }

    var sortOrder: Int {
        switch self {
        case .critical: return 0
        case .high:     return 1
        case .medium:   return 2
        case .low:      return 3
        }
    }

    var badgeFG: Color {
        switch self {
        case .critical: return Color(hex: "#DC2626")
        case .high:     return Color(hex: "#92400E")
        case .medium:   return Color(hex: "#4A4640")
        case .low:      return Color(hex: "#065F46")
        }
    }

    var badgeBG: Color {
        switch self {
        case .critical: return Color(hex: "#FEE2E2")
        case .high:     return Color(hex: "#FEF3C7")
        case .medium:   return Color(hex: "#F2F1EE")
        case .low:      return Color(hex: "#D1FAE5")
        }
    }
}

// MARK: - Task

struct TaskTagSel: Codable, Hashable {
    var tagId: String
    var subtagIds: [String] = []
}

struct TFTask: Identifiable, Codable {
    var id: String = UUID().uuidString
    var title: String
    var notes: String = ""
    var date: String           // "yyyy-MM-dd"
    var timeStart: String?     // "HH:mm" 24h
    var timeEnd: String?       // "HH:mm" 24h
    var priority: Priority = .medium
    var isDone: Bool = false
    var tagSelections: [TaskTagSel] = []
    var createdAt: Date = Date()

    var displayTime: String? {
        guard let s = timeStart, let e = timeEnd else { return nil }
        let f = DateFormatter(); f.dateFormat = "HH:mm"
        let d = DateFormatter(); d.dateFormat = "h:mm a"
        guard let sd = f.date(from: s), let ed = f.date(from: e) else { return nil }
        return "\(d.string(from: sd)) – \(d.string(from: ed))"
    }
}

// MARK: - Goal

struct TFGoal: Identifiable, Codable {
    var id: String = UUID().uuidString
    var tagId: String
    var weekly:  Int?
    var monthly: Int?
    var yearly:  Int?
    var hasAny: Bool { (weekly ?? 0) > 0 || (monthly ?? 0) > 0 || (yearly ?? 0) > 0 }
}

// MARK: - Color

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        self.init(
            red:   Double((int >> 16) & 0xFF) / 255,
            green: Double((int >> 8)  & 0xFF) / 255,
            blue:  Double( int        & 0xFF) / 255
        )
    }
}

// MARK: - Date helpers

extension String {
    static func today() -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: Date())
    }
    func addingDays(_ n: Int) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        guard let d = f.date(from: self) else { return self }
        return f.string(from: Calendar.current.date(byAdding: .day, value: n, to: d) ?? d)
    }
    func toDate() -> Date? {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.date(from: self)
    }
    func longFormatted() -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        guard let d = f.date(from: self) else { return self }
        let o = DateFormatter(); o.dateStyle = .full; return o.string(from: d)
    }
    func shortFormatted() -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        guard let d = f.date(from: self) else { return self }
        let o = DateFormatter(); o.dateFormat = "MMM d"; return o.string(from: d)
    }
}
