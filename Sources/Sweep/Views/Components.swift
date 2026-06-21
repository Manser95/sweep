import SwiftUI

/// A circular progress ring used on the dashboard for the scan total.
struct ProgressRing: View {
    var progress: Double          // 0...1
    var lineWidth: CGFloat = 12
    var tint: Color = .accentColor

    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.4), value: progress)
        }
    }
}

/// A small stat tile (label + value).
struct StatTile: View {
    let title: String
    let value: String
    var systemImage: String? = nil
    var tint: Color = .secondary

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage).foregroundStyle(tint)
                }
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.title2.weight(.semibold))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }
}

/// Horizontal labeled meter (used for memory breakdown).
struct Meter: View {
    let label: String
    let value: Int64
    let total: Int64
    var tint: Color = .accentColor

    private var fraction: Double {
        total > 0 ? min(1, Double(value) / Double(total)) : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label).font(.callout)
                Spacer()
                Text(Format.size(value))
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(tint.opacity(0.15))
                    Capsule().fill(tint)
                        .frame(width: geo.size.width * fraction)
                        .animation(.easeInOut(duration: 0.4), value: fraction)
                }
            }
            .frame(height: 8)
        }
    }
}

extension Color {
    /// Stable color per category for a touch of visual identity.
    static func forCategory(_ id: String) -> Color {
        switch id {
        case "app-caches": return .blue
        case "logs":       return .orange
        case "trash":      return .red
        case "developer":  return .purple
        default:           return .teal
        }
    }
}
