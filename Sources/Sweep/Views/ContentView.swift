import SwiftUI

enum SidebarItem: Hashable {
    case dashboard
    case category(String)
    case memory
}

struct ContentView: View {
    @Environment(SweepModel.self) private var model
    @Environment(Localizer.self) private var loc
    @State private var selection: SidebarItem? = .dashboard

    var body: some View {
        @Bindable var model = model

        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 280)
        } detail: {
            detail
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .toolbar { toolbarContent }
        .task {
            model.refreshMemory()
            model.refreshDisk()
        }
        .confirmationDialog(
            loc(.confirmTitle),
            isPresented: $model.confirmCleanPresented,
            titleVisibility: .visible
        ) {
            Button(loc.cleanSize(Format.size(model.selectedSize)), role: .destructive) {
                model.clean()
            }
            Button(loc(.cancel), role: .cancel) {}
        } message: {
            Text(confirmMessage)
        }
    }

    private var confirmMessage: String {
        var msg = loc.confirmMessage(count: model.selectedItems.count,
                                     size: Format.size(model.selectedSize))
        if model.selectionHasPermanentDelete {
            msg += "\n\n⚠️ " + loc(.confirmPermanentWarning)
        }
        return msg
    }

    // MARK: Sidebar

    private var sidebar: some View {
        List(selection: $selection) {
            Section {
                Label(loc(.dashboard), systemImage: "gauge.with.dots.needle.67percent")
                    .tag(SidebarItem.dashboard)
            }

            Section(loc(.sectionCleanup)) {
                ForEach(model.categories) { category in
                    HStack {
                        Label(loc.name(category), systemImage: category.symbol)
                        Spacer()
                        if model.hasScanned {
                            let size = model.categorySize(category.id)
                            if size > 0 {
                                Text(Format.size(size))
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .tag(SidebarItem.category(category.id))
                }
            }

            Section(loc(.sectionSystem)) {
                Label(loc(.memoryRAM), systemImage: "memorychip")
                    .tag(SidebarItem.memory)
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            if model.hasScanned && model.selectedSize > 0 {
                cleanBar
            }
        }
    }

    private var cleanBar: some View {
        VStack(spacing: 8) {
            Divider()
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(loc(.selected)).font(.caption).foregroundStyle(.secondary)
                    Text(Format.size(model.selectedSize))
                        .font(.headline.monospacedDigit())
                }
                Spacer()
                Button {
                    model.requestClean()
                } label: {
                    Label(loc(.clean), systemImage: "sparkles")
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.isBusy || model.selectedItems.isEmpty)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
        }
        .background(.bar)
    }

    // MARK: Detail

    @ViewBuilder
    private var detail: some View {
        switch selection {
        case .dashboard, .none:
            DashboardView()
        case .category(let id):
            if let category = model.categories.first(where: { $0.id == id }) {
                CategoryDetailView(category: category)
            } else {
                DashboardView()
            }
        case .memory:
            MemoryView()
        }
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                model.scan()
            } label: {
                if case .scanning = model.phase {
                    Label(loc(.scanning), systemImage: "stop.circle")
                } else {
                    Label(loc(.scan), systemImage: "magnifyingglass")
                }
            }
            .disabled(model.isBusy)
        }

        ToolbarItem(placement: .automatic) {
            Menu {
                Picker(loc(.language), selection: Binding(
                    get: { loc.language },
                    set: { loc.language = $0 }
                )) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text(lang.nativeName).tag(lang)
                    }
                }
                .pickerStyle(.inline)
            } label: {
                Label(loc(.language), systemImage: "globe")
            }
        }
    }
}
