import SwiftUI

struct CategoryDetailView: View {
    @Environment(SweepModel.self) private var model
    @Environment(Localizer.self) private var loc
    let category: CleanupCategory

    private var items: [CleanupItem] { model.items(for: category.id) }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if !model.hasScanned {
                placeholder(text: loc(.runScanCategory))
            } else if items.isEmpty {
                placeholder(text: loc(.nothingToClean))
            } else {
                list
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: category.symbol)
                    .font(.title)
                    .foregroundStyle(Color.forCategory(category.id))
                VStack(alignment: .leading, spacing: 2) {
                    Text(loc.name(category)).font(.title2.weight(.semibold))
                    Text(loc.blurb(category)).font(.callout).foregroundStyle(.secondary)
                }
                Spacer()
            }
            if model.hasScanned && !items.isEmpty {
                HStack {
                    Text(loc.itemsAndSize(items.count, Format.size(model.categorySize(category.id))))
                        .font(.callout).foregroundStyle(.secondary)
                    Spacer()
                    Button(loc(.selectAll)) { model.setAll(in: category.id, selected: true) }
                        .buttonStyle(.link)
                    Button(loc(.deselectAll)) { model.setAll(in: category.id, selected: false) }
                        .buttonStyle(.link)
                }
            }
        }
        .padding(20)
    }

    private var list: some View {
        List {
            ForEach(items) { item in
                ItemRow(item: item)
            }
        }
        .listStyle(.inset)
        .safeAreaInset(edge: .bottom) {
            let selSize = items.filter(\.isSelected).reduce(Int64(0)) { $0 + $1.size }
            if selSize > 0 {
                HStack {
                    Text(loc.selectedAndSize(model.selectedCount(in: category.id), Format.size(selSize)))
                        .font(.callout).foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        model.requestClean()
                    } label: {
                        Label(loc(.cleanSelected), systemImage: "sparkles")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.isBusy)
                }
                .padding(12)
                .background(.bar)
            }
        }
    }

    private func placeholder(text: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text(text).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ItemRow: View {
    @Environment(SweepModel.self) private var model
    @Environment(Localizer.self) private var loc
    let item: CleanupItem

    var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: Binding(
                get: { item.isSelected },
                set: { _ in model.toggle(item) }
            ))
            .labelsHidden()
            .toggleStyle(.checkbox)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.displayName)
                    .lineLimit(1)
                    .truncationMode(.middle)
                HStack(spacing: 6) {
                    if item.clearsContentsOnly {
                        Text(loc(.clearsContents))
                            .font(.caption2)
                            .padding(.horizontal, 5).padding(.vertical, 1)
                            .background(.quaternary, in: Capsule())
                    }
                    Text(item.url.path)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            Spacer()

            Picker("", selection: Binding(
                get: { item.mode },
                set: { model.setMode($0, for: item) }
            )) {
                Text(loc(.modeTrash)).tag(RemovalMode.trash)
                Text(loc(.modeDelete)).tag(RemovalMode.delete)
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .fixedSize()

            Text(Format.size(item.size))
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .trailing)
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button(loc(.revealInFinder)) {
                NSWorkspace.shared.activateFileViewerSelecting([item.url])
            }
        }
    }
}
