import SwiftUI

struct DashboardView: View {
    @Environment(SweepModel.self) private var model
    @Environment(Localizer.self) private var loc

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                diskCard

                switch model.phase {
                case .idle:
                    emptyState
                case .scanning(let progress, let label):
                    scanningState(progress: progress, label: label)
                case .cleaning(let progress, let label):
                    cleaningState(progress: progress, label: label)
                case .scanned:
                    summary
                case .done(let deleted, let trashed, let failures):
                    doneState(deleted: deleted, trashed: trashed, failures: failures)
                    summary
                }
            }
            .padding(28)
            .frame(maxWidth: 760, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.largeTitle)
                    .foregroundStyle(.tint)
                Text("Sweep")
                    .font(.largeTitle.weight(.bold))
            }
            Text(loc(.appTagline))
                .foregroundStyle(.secondary)
        }
    }

    private var diskCard: some View {
        let d = model.disk
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(loc(.freeDisk), systemImage: "internaldrive")
                    .font(.callout).foregroundStyle(.secondary)
                Spacer()
                Text("\(Format.size(d.free)) \(loc(.ofTotal)) \(Format.size(d.total))")
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.tint.opacity(0.15))
                    Capsule().fill(.tint)
                        .frame(width: geo.size.width * d.usedFraction)
                }
            }
            .frame(height: 8)
        }
        .padding(14)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text(loc(.runScanPrompt))
                .foregroundStyle(.secondary)
            Button {
                model.scan()
            } label: {
                Label(loc(.scanNow), systemImage: "magnifyingglass")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private func scanningState(progress: Double, label: String) -> some View {
        VStack(spacing: 18) {
            ProgressRing(progress: progress)
                .frame(width: 120, height: 120)
                .overlay {
                    Text("\(Int(progress * 100))%")
                        .font(.title2.weight(.semibold).monospacedDigit())
                }
            Text(label.isEmpty ? loc(.scanning) : loc.scanningName(label))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func cleaningState(progress: Double, label: String) -> some View {
        VStack(spacing: 18) {
            ProgressRing(progress: progress, tint: .green)
                .frame(width: 120, height: 120)
                .overlay {
                    Image(systemName: "sparkles").font(.title)
                }
            Text(label.isEmpty ? loc(.clean) : loc.cleaningName(label))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func doneState(deleted: Int64, trashed: Int64, failures: Int) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title)
                .foregroundStyle(.green)
            VStack(alignment: .leading) {
                Text(loc.cleanedSummary(deleted: deleted, trashed: trashed))
                    .font(.title3.weight(.semibold))
                if failures > 0 {
                    Text(loc.failuresLine(failures))
                        .font(.callout)
                        .foregroundStyle(.orange)
                }
            }
            Spacer()
        }
        .padding(16)
        .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var summary: some View {
        let total = model.result.grandTotal
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                ProgressRing(progress: total > 0 ? 1 : 0)
                    .frame(width: 96, height: 96)
                    .overlay {
                        VStack(spacing: 0) {
                            Text(Format.size(total))
                                .font(.headline.monospacedDigit())
                            Text(loc(.found)).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                VStack(alignment: .leading, spacing: 8) {
                    StatTile(title: loc(.reclaimable),
                             value: Format.size(total),
                             systemImage: "internaldrive", tint: .blue)
                    StatTile(title: loc(.selected),
                             value: Format.size(model.selectedSize),
                             systemImage: "checkmark.circle", tint: .green)
                }
            }

            Text(loc(.byCategory))
                .font(.headline)

            ForEach(model.categories) { category in
                let size = model.categorySize(category.id)
                if size > 0 {
                    Meter(label: loc.name(category),
                          value: size,
                          total: max(total, 1),
                          tint: .forCategory(category.id))
                }
            }

            if model.selectedSize > 0 {
                Button {
                    model.requestClean()
                } label: {
                    Label(loc.cleanSize(Format.size(model.selectedSize)), systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(model.isBusy)
                .padding(.top, 8)
            }
        }
    }
}
