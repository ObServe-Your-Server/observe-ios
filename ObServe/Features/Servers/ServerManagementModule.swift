//
//  ServerManagementModule.swift
//  ObServe
//
//  Created by GitHub Copilot on 22.09.25.
//

import SwiftUI

struct ServerManagementModule: View {
    @Bindable var server: ServerModuleItem
    var onLogs: () -> Void
    var onManage: () -> Void

    @State private var osVersion = "Unknown"

    // Blinking animation state
    @State private var isBlinking = false
    @State private var lightOpacity: Double = 1.0
    @State private var showNoteEditor = false
    @State private var isExpanded = false

    @ObservedObject var metricsManager: MetricsManager

    init(server: ServerModuleItem, metricsManager: MetricsManager, onLogs: @escaping () -> Void, onManage: @escaping () -> Void) {
        self._server = Bindable(wrappedValue: server)
        self.metricsManager = metricsManager
        self.onLogs = onLogs
        self.onManage = onManage
    }

    private var storageHeaderText: String {
        let used = metricsManager.avgStorage
        let total = metricsManager.maxStorage
        if total >= 1000 {
            return String(format: "%.2f / %.2f TB", used / 1000, total / 1000)
        } else {
            return String(format: "%.2f / %.2f GB", used, total)
        }
    }

    /// Convert server type to proper image name
    private func getIconName(for serverType: String, isConnected: Bool) -> String {
        let suffix = isConnected ? "_on" : "_off"

        // Map server types to asset names
        switch serverType.uppercased() {
        case "SERVER":
            return "server" + suffix
        case "SINGLE_BOARD":
            return "singleBoard" + suffix
        case "CUBE":
            return "cube" + suffix
        case "DESKTOP":
            return "desktop" + suffix
        case "VM":
            return "vm" + suffix
        case "CONTAINER":
            return "container" + suffix
        case "LAPTOP":
            return "laptop" + suffix
        default:
            return "server" + suffix // fallback
        }
    }

    /// Start blinking animation on icon tap
    private func startBlinking() {
        guard !isBlinking else { return }  // Prevent multiple simultaneous animations

        isBlinking = true
        lightOpacity = 1.0

        // Animate opacity with repeating fade in/out
        withAnimation(.easeInOut(duration: 0.4).repeatCount(6, autoreverses: true)) {
            lightOpacity = 0.0
        }

        // Reset state after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            isBlinking = false
            lightOpacity = 1.0
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 20) {
                Spacer().frame(height: 5)
                
                // Server info and icon section
                HStack(spacing: 18) {
                    VStack(alignment: .leading, spacing: 16) {
                        // Top row: UPTIME aligned with OS-VERSION
                        UpdateLabel(label: "UPTIME", value: metricsManager.uptime, showDaysInUptime: true)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("STATUS")
                                .foregroundColor(Color.gray)
                                .font(.system(size: 12, weight: .medium))
                            Text(server.machineStatus.rawValue)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Server icon
                    VStack {
                        ZStack {
                            // Base layer: always show "off" state
                            Image(getIconName(for: server.type, isConnected: false))
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 96, maxHeight: 96)

                            // Overlay layer: "on" state with animated opacity
                            Image(getIconName(for: server.type, isConnected: true))
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 96, maxHeight: 96)
                                .opacity(isBlinking ? lightOpacity : (server.isConnected ? 1.0 : 0.0))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .overlay(RoundedRectangle(cornerRadius: 0)
                        .stroke(Color(red: 0x47/255, green: 0x47/255, blue: 0x4A/255)))
                    .overlay(
                        FocusCorners(color: Color.white, size: 8, thickness: 1)
                    )
                    .onTapGesture {
                        startBlinking()
                        Haptics.click()
                    }
                }
                .padding(.bottom, 4)
                
                if isExpanded {
                    VStack(spacing: 10) {
                        VStack(spacing: 2) {
                            HStack {
                                Text("MACHINE TYPE")
                                    .foregroundColor(Color.gray)
                                    .font(.system(size: 12, weight: .medium))
                                Spacer()
                                Text(server.type.uppercased())
                                    .foregroundColor(.white)
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 0).fill(Color(red: 0.102, green: 0.102, blue: 0.102)))
                            HStack {
                                Text("OS VERSION")
                                    .foregroundColor(Color.gray)
                                    .font(.system(size: 12, weight: .medium))
                                Spacer()
                                Text(metricsManager.osName ?? osVersion)
                                    .foregroundColor(.white)
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 0).fill(Color(red: 0.102, green: 0.102, blue: 0.102)))
                        }
                        .padding(.bottom, 12)

                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("STORAGE")
                                    .foregroundColor(Color.gray)
                                    .font(.system(size: 12, weight: .medium))
                                Spacer()
                                Text(storageHeaderText)
                                    .foregroundColor(.white)
                            }
                            VStack(spacing: 8) {
                                ForEach(Array(metricsManager.disks.enumerated()), id: \.offset) { index, disk in
                                    HStack(spacing: 12) {
                                        ZStack {
                                            CutCornerShape()
                                                .fill(Color(white: 0.25).opacity(0.25))
                                                .frame(width: 42, height: 26)
                                            CutCornerShape()
                                                .stroke(Color(white: 0.30), lineWidth: 1)
                                                .frame(width: 42, height: 26)
                                            Text("\(index + 1)")
                                                .foregroundColor(.white)
                                        }
                                        // TODO: Backend agent should send human-readable disk names instead of device paths
                                        Text((disk.name ?? "Unknown").replacingOccurrences(of: "/dev/", with: ""))
                                            .foregroundColor(.white)
                                        Spacer()
                                        DiskFillMeter(used: disk.used ?? 0, total: max(disk.total ?? 1, 1))
                                    }
                                }
                            }.padding(.bottom, 12)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("NOTE")
                                    .foregroundColor(Color.gray)
                                    .font(.system(size: 12, weight: .medium))
                                HStack {
                                    Text(server.machineDescription.isEmpty ? "Write a note..." : server.machineDescription)
                                        .foregroundColor(server.machineDescription.isEmpty ? Color.gray : .white)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Color.gray)
                                        .font(.system(size: 12))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 10)
                                .contentShape(Rectangle())
                                .overlay(RoundedRectangle(cornerRadius: 0).stroke(Color.white.opacity(0.3), lineWidth: 1))
                                .onTapGesture {
                                    showNoteEditor = true
                                    Haptics.click()
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                // Action buttons - matching ServerModule styling
                HStack(spacing: 18) {
                    RegularButtonWhite(Label: "LOGS", action: {
                        onLogs()
                        Haptics.click()
                    }, color: "ObServeGray")
                    .frame(maxWidth: .infinity)

                    RegularButtonWhite(Label: "MANAGE", action: {
                        onManage()
                    }, color: "ObServeGray")
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .background(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
            )
            .fullScreenCover(isPresented: $showNoteEditor) {
                NoteEditorView(note: $server.machineDescription, onDismiss: { showNoteEditor = false })
            }
            .overlay(alignment: .topLeading) {
                HStack {
                    Text("MACHINE")
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .medium))
                }
                .padding(10)
                .background(Color.black)
                .padding(.top, -20)
                .padding(.leading, 10)
            }
            .overlay(alignment: .bottomTrailing) {
                ExpandCornerIndicator()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
                Haptics.click()
            }
            Spacer().frame(height: 20)
            
            // CPU and RAM expandable metric boxes
            VStack(spacing: 20) {
                ExpandableMetricBox(
                    title: "CPU",
                    currentValue: metricsManager.avgCPU * 100,
                    maximum: 100.0,
                    unit: "%",
                    decimalPlaces: 2,
                    showPercent: false,
                    serverId: server.id,
                    metricType: "CPU",
                    headerRows: [
                        (label: "NAME", value: metricsManager.cpuName ?? "Unknown"),
                        (label: "CORES", value: metricsManager.cpuCount.map { "\($0)" } ?? "Unknown")
                    ],
                    cpuTemperature: metricsManager.cpuTemperature
                )

                ExpandableMetricBox(
                    title: "RAM",
                    currentValue: metricsManager.maxRAM > 0 ? (metricsManager.avgRAM / metricsManager.maxRAM) * 100 : 0,
                    maximum: 100.0,
                    unit: "%",
                    decimalPlaces: 2,
                    showPercent: false,
                    serverId: server.id,
                    metricType: "RAM",
                    headerRows: [
                        // TODO: Backend should send RAM chip name
                        (label: "NAME", value: "TODO"),
                        (label: "MAX", value: metricsManager.maxRAM > 0
                            ? String(format: "%.1f GB", metricsManager.maxRAM)
                            : "Unknown")
                    ]
                )
            }
            // Network metrics view below the server management module
            NetworkMetricsView(metricsManager: metricsManager)
            
        }
    }
}

private struct CutCornerShape: Shape {
    var cornerSize: CGFloat = 6

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - cornerSize, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + cornerSize))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct DiskFillMeter: View {
    let used: Int64
    let total: Int64

    var body: some View {
        let fraction = total > 0 ? Double(used) / Double(total) : 0
        let filledCount = Int((fraction * 10).rounded())
        HStack(spacing: 2) {
            ForEach(0..<10, id: \.self) { i in
                Rectangle()
                    .fill(i < filledCount ? Color.white : Color(red: 0.102, green: 0.102, blue: 0.102))
                    .frame(width: 8, height: 28)
            }
        }
    }
}

private struct NoteEditorView: View {
    @Binding var note: String
    var onDismiss: () -> Void
    @State private var draftNote: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                Text("NOTE")
                    .foregroundColor(.white)
                    .font(.system(size: 14, weight: .medium))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 20)
                    .padding(.bottom, 16)

                TextEditor(text: $draftNote)
                    .foregroundColor(.white)
                    .font(.system(size: 14))
                    .scrollContentBackground(.hidden)
                    .background(Color.black)
                    .padding(.horizontal, 16)
                    .focused($isFocused)
                    .overlay(alignment: .topLeading) {
                        if draftNote.isEmpty {
                            Text("Write a note...")
                                .foregroundColor(Color.gray)
                                .font(.system(size: 14))
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                                .allowsHitTesting(false)
                        }
                    }

                Spacer()

                HStack(spacing: 12) {
                    RegularButton(Label: "DISCARD", action: {
                        onDismiss()
                    }, color: "ObServeGray")
                    .frame(maxWidth: .infinity)

                    RegularButton(Label: "SAVE", action: {
                        note = draftNote
                        onDismiss()
                    }, color: "ObServeBlue")
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            draftNote = note
            isFocused = true
        }
    }
}

#Preview {
    let server = ServerModuleItem(machineUUID: UUID(), name: "Test Server", type: "Cube")
    ServerManagementModule(
        server: server,
        metricsManager: MetricsManager(server: server),
        onLogs: {},
        onManage: { print("Manage tapped") }
    )
    .background(Color.black)
}
