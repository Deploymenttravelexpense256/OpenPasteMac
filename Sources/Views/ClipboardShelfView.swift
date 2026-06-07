import SwiftUI

struct ClipboardShelfView: View {
    @ObservedObject var store: ClipboardStore
    var onPaste: (ClipboardItem) -> Void
    var onDismiss: () -> Void

    @State private var showAddPinboard = false
    @FocusState private var searchFocused: Bool

    var body: some View {
        ZStack(alignment: .top) {
            // Blurred background
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()
                .colorScheme(.dark)

            VStack(spacing: 0) {
                PinboardTabBar(
                    store: store,
                    isSearching: $store.isSearching,
                    showAddPinboard: $showAddPinboard
                )
                .padding(.top, 4)

                // Inline search field
                if store.isSearching {
                    searchField
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                Divider().background(Color.white.opacity(0.1))

                // Card scroll
                cardScroll
            }
        }
        .overlay(
            // Top rounded corners border line
            VStack {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                    .frame(height: 300)
                Spacer()
            }
        )
        .sheet(isPresented: $showAddPinboard) {
            AddPinboardSheet(store: store, isPresented: $showAddPinboard)
                .background(Color(red: 0.13, green: 0.16, blue: 0.24))
        }
        .onChange(of: store.triggerFocus) { v in
            if v { searchFocused = true; store.triggerFocus = false }
        }
    }

    // MARK: - Search

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.4))
            TextField("Search clipboard...", text: $store.searchQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundColor(.white)
                .focused($searchFocused)
                .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { searchFocused = true } }
            if !store.searchQuery.isEmpty {
                Button { store.searchQuery = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.06))
    }

    // MARK: - Card Scroll

    private var cardScroll: some View {
        Group {
            if store.filteredItems.isEmpty {
                emptyState
            } else {
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 8) {
                            ForEach(Array(store.filteredItems.enumerated()), id: \.element.id) { idx, item in
                                ClipboardCardView(
                                    item: item,
                                    index: idx,
                                    isSelected: store.selectedIndex == idx,
                                    onPaste: { onPaste(item) },
                                    onPin: { store.togglePin(item: item) },
                                    onDelete: { store.delete(item: item) },
                                    onAddToPinboard: { board in store.addItem(item, toPinboard: board.id) },
                                    pinboards: store.pinboards
                                )
                                .id(item.id)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                    }
                    .onChange(of: store.selectedIndex) { idx in
                        if let item = store.filteredItems[safe: idx] {
                            withAnimation(.easeOut(duration: 0.18)) {
                                proxy.scrollTo(item.id, anchor: .center)
                            }
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 28))
                .foregroundColor(.white.opacity(0.2))
            Text(store.searchQuery.isEmpty ? "Nothing copied yet" : "No results")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.3))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
