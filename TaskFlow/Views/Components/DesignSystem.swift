import SwiftUI

// MARK: - Design Tokens

enum DS {
    static let bg        = Color(hex: "#F9F9F8")
    static let bg2       = Color(hex: "#F2F1EE")
    static let card      = Color.white
    static let border    = Color(hex: "#E5E3DC")
    static let border2   = Color(hex: "#D1CEC4")
    static let text      = Color(hex: "#1A1915")
    static let text2     = Color(hex: "#4A4640")
    static let text3     = Color(hex: "#8C8880")
    static let accent    = Color(hex: "#A8977A")
    static let accentDk  = Color(hex: "#8C7D64")
    static let accentBg  = Color(hex: "#F5F0E8")
    static let green     = Color(hex: "#059669")
    static let greenBg   = Color(hex: "#D1FAE5")
    static let red       = Color(hex: "#DC2626")

    static let r6: CGFloat  = 6
    static let r8: CGFloat  = 8
    static let r12: CGFloat = 12

    static let sp4:  CGFloat = 4
    static let sp8:  CGFloat = 8
    static let sp12: CGFloat = 12
    static let sp16: CGFloat = 16
    static let sp20: CGFloat = 20
    static let sp24: CGFloat = 24
}

// MARK: - PriorityBadge

struct PriorityBadge: View {
    let priority: Priority
    var body: some View {
        Text(priority.label.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .tracking(0.4)
            .foregroundColor(priority.badgeFG)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(priority.badgeBG)
            .clipShape(RoundedRectangle(cornerRadius: 5))
    }
}

// MARK: - TagChip

struct TagChip: View {
    let tag: TFTag
    let subNames: [String]
    var body: some View {
        HStack(spacing: 3) {
            Text(tag.name)
                .font(.system(size: 11, weight: .semibold))
            ForEach(subNames, id: \.self) { s in
                Text("·").font(.system(size: 10))
                Text(s).font(.system(size: 10, weight: .medium))
            }
        }
        .foregroundColor(Color(hex: tag.colorHex))
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(Color(hex: tag.colorHex).opacity(0.12))
        .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color(hex: tag.colorHex).opacity(0.3), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 7))
    }
}

// MARK: - SectionHeader

struct SectionHeader: View {
    let title: String; let count: Int
    var body: some View {
        HStack(spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold)).tracking(0.8).foregroundColor(DS.text3)
            Rectangle().fill(DS.border).frame(height: 1)
            Text("\(count)")
                .font(.system(size: 10, weight: .semibold)).foregroundColor(DS.text3)
                .padding(.horizontal, 7).padding(.vertical, 2)
                .background(DS.bg2).clipShape(Capsule())
        }
    }
}

// MARK: - StatCard

struct StatCard: View {
    let value: String; let label: String; let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .foregroundColor(color)
            Text(label.uppercased())
                .font(.system(size: 10, weight: .medium)).tracking(0.6).foregroundColor(DS.text3)
        }
        .padding(DS.sp16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.card)
        .clipShape(RoundedRectangle(cornerRadius: DS.r8))
        .overlay(RoundedRectangle(cornerRadius: DS.r8).stroke(DS.border, lineWidth: 1))
    }
}

// MARK: - ProgressRow

struct ProgressRow: View {
    let label: String; let current: Int; let goal: Int; let color: Color
    var pct: Double { goal > 0 ? min(Double(current) / Double(goal), 1.0) : 0 }
    var hit: Bool { current >= goal && goal > 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(label)
                    .font(.system(size: 12, weight: .medium)).foregroundColor(DS.text3)
                Spacer()
                HStack(spacing: 2) {
                    Text("\(current)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(hit ? DS.green : color)
                    Text("/ \(goal) days")
                        .font(.system(size: 12)).foregroundColor(DS.text3)
                    if hit { Text("✓").font(.system(size: 11, weight: .semibold)).foregroundColor(DS.green) }
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(DS.bg2).frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color.opacity(0.75))
                        .frame(width: geo.size.width * pct, height: 6)
                        .animation(.spring(response: 0.5), value: pct)
                }
            }.frame(height: 6)
            Text("\(Int(pct * 100))%\(hit ? " — reached" : "")")
                .font(.system(size: 11)).foregroundColor(DS.text3)
        }
    }
}

// MARK: - HeatCell

struct HeatCell: View {
    let intensity: Double; let color: Color; let isToday: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color.opacity(intensity < 0.01 ? 0.07 : 0.12 + intensity * 0.78))
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(isToday ? color : .clear, lineWidth: 1.5))
        }.buttonStyle(.plain)
    }
}

// MARK: - EmptyState

struct EmptyState: View {
    let icon: String; let title: String; let subtitle: String
    var action: (() -> Void)? = nil; var actionLabel = ""
    var body: some View {
        VStack(spacing: DS.sp12) {
            Text(icon).font(.system(size: 38))
            Text(title).font(.system(size: 17, weight: .semibold)).foregroundColor(DS.text2)
            Text(subtitle).font(.system(size: 13)).foregroundColor(DS.text3)
                .multilineTextAlignment(.center).frame(maxWidth: 260)
            if let a = action {
                Button(actionLabel, action: a).buttonStyle(PrimaryBtn())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity).padding(DS.sp24)
    }
}

// MARK: - Button styles

struct PrimaryBtn: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
            .padding(.horizontal, DS.sp16).padding(.vertical, DS.sp8)
            .background(configuration.isPressed ? DS.accentDk : DS.accent)
            .clipShape(RoundedRectangle(cornerRadius: DS.r6))
    }
}

struct GhostBtn: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium)).foregroundColor(DS.text2)
            .padding(.horizontal, DS.sp16).padding(.vertical, DS.sp8)
            .background(configuration.isPressed ? DS.bg2 : DS.card)
            .clipShape(RoundedRectangle(cornerRadius: DS.r6))
            .overlay(RoundedRectangle(cornerRadius: DS.r6).stroke(DS.border, lineWidth: 1))
    }
}

// MARK: - FieldLabel

struct FieldLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .medium)).tracking(0.5).foregroundColor(DS.text3)
    }
}

// MARK: - Card modifier

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(DS.card)
            .clipShape(RoundedRectangle(cornerRadius: DS.r8))
            .overlay(RoundedRectangle(cornerRadius: DS.r8).stroke(DS.border, lineWidth: 1))
    }
}
extension View {
    func cardStyle() -> some View { modifier(CardStyle()) }
}
