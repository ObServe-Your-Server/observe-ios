import SwiftUI

/// A drag-to-reorder wrapper for server cards.
/// Cards visually reorder in real-time as you drag; on release the final order is persisted.
/// The parent must have `.coordinateSpace(name: "reorderContainer")` on the container VStack
/// and render the floating card overlay using the exposed bindings.
struct ReorderableServerList: View {
    let servers: [ServerModuleItem]
    let refreshTrigger: Int
    let onDelete: (ServerModuleItem) -> Void
    /// Pass nil to disable reordering (e.g. when a filter is active).
    let onReorder: ((Int, Int) -> Void)?

    // Exposed so the parent can render the floating card above AddMachineButton
    @Binding var draggingServer: ServerModuleItem?
    @Binding var floatOffsetY: CGFloat

    /// Live order shown during drag; synced from `servers` when not dragging
    @State private var liveOrder: [ServerModuleItem] = []

    // Drag state
    @State private var longPressedID: ServerModuleItem.ID? = nil
    @State private var draggingID: ServerModuleItem.ID? = nil
    @State private var dragOriginIndex: Int? = nil // index in `servers` at drag start

    @State private var cardOrigins: [ServerModuleItem.ID: CGFloat] = [:]
    @State private var cardHeights: [ServerModuleItem.ID: CGFloat] = [:]

    private let hapticMedium = UIImpactFeedbackGenerator(style: .medium)
    private let hapticLight = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(liveOrder.enumerated()), id: \.element.id) { liveIndex, server in
                cardSlot(server: server, liveIndex: liveIndex)
            }
        }
        .onAppear { liveOrder = servers }
        .onChange(of: servers) { _, newValue in
            if draggingID == nil { liveOrder = newValue }
        }
    }

    // MARK: - Card Slot

    @ViewBuilder
    private func cardSlot(server: ServerModuleItem, liveIndex: Int) -> some View {
        let id = server.id
        let isDragging = draggingID == id
        let anyDragging = draggingID != nil

        ZStack(alignment: .top) {
            // Snap line at the top of the invisible slot — shows where card will land
            if isDragging {
                snapLine
                    .padding(.top, -1)
                    .zIndex(10)
            }

            ServerModule(
                server: server,
                refreshTrigger: refreshTrigger,
                onDelete: { onDelete(server) }
            )
            .background(Color.black)
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            let frame = geo.frame(in: .named("reorderContainer"))
                            cardHeights[id] = frame.height
                            cardOrigins[id] = frame.minY
                        }
                        .onChange(of: geo.frame(in: .named("reorderContainer")).minY) { _, y in
                            cardOrigins[id] = y
                        }
                        .onChange(of: geo.frame(in: .named("reorderContainer")).height) { _, h in
                            cardHeights[id] = h
                        }
                }
            )
            .opacity(isDragging ? 0 : (anyDragging ? 0.55 : 1.0))
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: liveIndex)
            .animation(.easeInOut(duration: 0.15), value: anyDragging)
        }
        // Long press — simultaneous so scroll is not blocked
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.4)
                .onEnded { _ in
                    guard onReorder != nil else { return }
                    longPressedID = id
                }
        )
        // Drag — only activates after long press confirmed
        .simultaneousGesture(
            DragGesture(minimumDistance: 4, coordinateSpace: .named("reorderContainer"))
                .onChanged { drag in
                    guard onReorder != nil, longPressedID == id else { return }
                    if draggingID == nil {
                        hapticMedium.impactOccurred()
                        draggingID = id
                        dragOriginIndex = servers.firstIndex(where: { $0.id == id })
                        floatOffsetY = drag.startLocation.y - (cardHeights[id] ?? 160) / 2
                        draggingServer = server
                    }
                    guard draggingID == id else { return }
                    floatOffsetY = drag.location.y - (cardHeights[id] ?? 160) / 2

                    let centreY = drag.location.y
                    let newTarget = targetLiveIndex(for: centreY)
                    let currentIndex = liveOrder.firstIndex(where: { $0.id == id }) ?? 0

                    if newTarget != currentIndex {
                        hapticLight.impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            var reordered = liveOrder
                            let item = reordered.remove(at: currentIndex)
                            reordered.insert(item, at: newTarget)
                            liveOrder = reordered
                        }
                    }
                }
                .onEnded { _ in
                    let finalIndex = liveOrder.firstIndex(where: { $0.id == id })
                    let origin = dragOriginIndex

                    longPressedID = nil
                    draggingID = nil
                    dragOriginIndex = nil
                    draggingServer = nil
                    floatOffsetY = 0

                    if let origin, let finalIndex, origin != finalIndex {
                        hapticMedium.impactOccurred()
                        onReorder?(origin, finalIndex)
                    }
                }
        )
    }

    // MARK: - Snap Line

    private var snapLine: some View {
        Capsule()
            .fill(Color("ObServeGray"))
            .frame(height: 2)
            .shadow(color: Color("ObServeGray").opacity(0.8), radius: 6)
            .padding(.horizontal, 4)
            .transition(.opacity)
    }

    // MARK: - Index Calculation

    private func targetLiveIndex(for centreY: CGFloat) -> Int {
        for i in 0 ..< liveOrder.count {
            let id = liveOrder[i].id
            let origin = cardOrigins[id] ?? 0
            let h = cardHeights[id] ?? 160.0
            if centreY < origin + h / 2 {
                return i
            }
        }
        return max(0, liveOrder.count - 1)
    }
}
