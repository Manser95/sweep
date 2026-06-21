import SwiftUI

struct MemoryView: View {
    @Environment(SweepModel.self) private var model
    @Environment(Localizer.self) private var loc
    @State private var ticker = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header

                let m = model.memory

                HStack(spacing: 16) {
                    ProgressRing(progress: m.pressure,
                                 tint: pressureColor(m.pressure))
                        .frame(width: 120, height: 120)
                        .overlay {
                            VStack(spacing: 0) {
                                Text("\(Int(m.pressure * 100))%")
                                    .font(.title.weight(.semibold).monospacedDigit())
                                Text(loc(.used)).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    VStack(alignment: .leading, spacing: 10) {
                        StatTile(title: loc(.totalRAM), value: Format.size(m.total),
                                 systemImage: "memorychip", tint: .secondary)
                        StatTile(title: loc(.free), value: Format.size(m.free),
                                 systemImage: "checkmark.circle", tint: .green)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text(loc(.breakdown)).font(.headline)
                    Meter(label: loc(.appMemory), value: m.appMemory, total: m.total, tint: .blue)
                    Meter(label: loc(.wired), value: m.wired, total: m.total, tint: .orange)
                    Meter(label: loc(.compressed), value: m.compressed, total: m.total, tint: .purple)
                }
                .padding(16)
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 10) {
                    Text(loc(.freeInactiveTitle)).font(.headline)
                    Text(loc(.freeInactiveDesc))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    HStack {
                        Button {
                            model.purgeMemory()
                        } label: {
                            Label(loc(.purgeButton), systemImage: "wind")
                        }
                        .buttonStyle(.bordered)
                        if let msg = model.purgeMessage {
                            Text(msg).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(16)
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(28)
            .frame(maxWidth: 760, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .onReceive(ticker) { _ in model.refreshMemory() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                Image(systemName: "memorychip").font(.largeTitle).foregroundStyle(.tint)
                Text(loc(.memory)).font(.largeTitle.weight(.bold))
            }
            Text(loc(.memoryLiveUsage))
                .foregroundStyle(.secondary)
        }
    }

    private func pressureColor(_ p: Double) -> Color {
        switch p {
        case ..<0.6: return .green
        case ..<0.85: return .orange
        default: return .red
        }
    }
}
