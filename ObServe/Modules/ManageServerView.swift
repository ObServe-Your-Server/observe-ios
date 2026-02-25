//
//  ManageServerView.swift
//  ObServe
//
//  Created by Daniel Schatz on 14.10.25.
//

import SwiftUI

enum ManageStep {
    case overview
    case editMachineType
    case editNaming
}

struct ManageServerView: View {
    var server: ServerModuleItem
    var onDismiss: () -> Void
    var onSave: (ServerModuleItem) -> Void
    var onDelete: (() -> Void)? = nil

    @State private var currentStep: ManageStep = .overview
    @State private var selectedMachineType: MachineType?
    @State private var name: String = ""
    @State private var ip: String = ""
    @State private var port: String = ""
    @State private var apiKey: String = ""
    @State private var connectionStatus: ConnectionStatus = .idle
    @State private var contentHasScrolled = false
    @State private var dummyInterval: DetailAppBar.Interval = .s1
    @State private var isApiKeyEditable = false
    @State private var showResetApiKeyConfirmation = false
    @State private var showDeleteConfirmation: Bool = false

    init(server: ServerModuleItem, onDismiss: @escaping () -> Void, onSave: @escaping (ServerModuleItem) -> Void, onDelete: (() -> Void)? = nil) {
        self.server = server
        self.onDismiss = onDismiss
        self.onSave = onSave
        self.onDelete = onDelete

        // Initialize state with server data
        _name = State(initialValue: server.name)
        _ip = State(initialValue: server.ip)
        _port = State(initialValue: server.port)
        _apiKey = State(initialValue: server.apiKey)

        // Find matching machine type (case-insensitive)
        let matchedType = MachineType.allCases.first(where: { $0.rawValue.uppercased() == server.type.uppercased() })
        _selectedMachineType = State(initialValue: matchedType)
    }

    private var censoredApiKey: String {
        guard apiKey.count > 3 else { return String(repeating: "*", count: apiKey.count) }
        let prefix = String(apiKey.prefix(3))
        let stars = String(repeating: "*", count: max(apiKey.count - 3, 8))
        return prefix + stars
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                DetailAppBar(
                    serverName: headerTitle,
                    contentHasScrolled: $contentHasScrolled,
                    selectedInterval: $dummyInterval,
                    showIntervalSelector: false,
                    showProgressIndicator: false,
                    currentStep: 0,
                    totalSteps: 1,
                    onClose: {
                        if currentStep != .overview {
                            currentStep = .overview
                        } else {
                            onDismiss()
                        }
                    }
                )

                // Content
                contentView

                // Navigation
                if currentStep != .overview {
                    navigationView
                }
            }
            .background(Color.black)
        }
        .confirmationDialog("Delete Server", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete \(server.name)", role: .destructive) {
                deleteServer()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \(server.name)? This action cannot be undone.")
        }
        .confirmationDialog("Reset API Key", isPresented: $showResetApiKeyConfirmation, titleVisibility: .visible) {
            Button("Reset API Key", role: .destructive) {
                resetApiKey()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will clear the current API key. You will need to enter a new one and save changes.")
        }
    }

    // MARK: - Content Views
    private var contentView: some View {
        Group {
            switch currentStep {
            case .overview:
                overviewView
            case .editMachineType:
                machineTypeView
            case .editNaming:
                namingView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
    }

    private var headerTitle: String {
        switch currentStep {
        case .overview:
            return "MANAGE \(server.name.uppercased())"
        case .editMachineType:
            return "MACHINE TYPE"
        case .editNaming:
            return "MACHINE NAME"
        }
    }

    // Overview - Main Management View
    private var overviewView: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 5)

            VStack(alignment: .leading, spacing: 16) {
                Spacer().frame(height: 5)

                // Server info and icon section
                HStack(spacing: 12) {
                    // LEFT COLUMN: NAME (top) and TYPE (bottom)
                    VStack(alignment: .leading, spacing: 16) {
                        infoLabel(label: "NAME", value: name.isEmpty ? "My \(selectedMachineType?.rawValue ?? "Machine")" : name)
                        infoLabel(label: "TYPE", value: selectedMachineType?.rawValue ?? "Unknown")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // RIGHT COLUMN: Icon with decorative elements
                    VStack {
                        if let machineType = selectedMachineType {
                            ZStack {
                                // Base layer: "off" state
                                Image(machineType.imageName(isSelected: false))
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: 96, maxHeight: 96)

                                // Overlay layer: "on" state (always visible since this is static)
                                Image(machineType.imageName(isSelected: true))
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: 96, maxHeight: 96)
                                    .opacity(1.0)
                            }
                        } else {
                            // Fallback icon if machine type is not found
                            Image(systemName: "server.rack")
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 96, maxHeight: 96)
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .overlay(RoundedRectangle(cornerRadius: 0)
                        .stroke(Color(red: 0x47/255, green: 0x47/255, blue: 0x4A/255)))
                    .overlay(FocusCorners(color: Color.white, size: 8, thickness: 1))
                }
                RegularButton(Label: "CHANGE", action: {
                    currentStep = .editMachineType
                }, color: "ObServeGray")
                .frame(maxWidth: .infinity)

            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .background(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
            )
            .overlay(alignment: .topLeading) {
                HStack {
                    Text("MACHINE INFO")
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .medium))
                }
                .padding(10)
                .background(Color.black)
                .padding(.top, -20)
                .padding(.leading, 10)
            }

            VStack(alignment: .center, spacing: 32) {
                VStack(spacing: 24) {
                    // IP Address row
                    HStack(spacing: 0) {
                        Text("IP")
                            .foregroundColor(.gray)
                            .font(.system(size: 12, weight: .medium))
                            .frame(width: 20, alignment: .leading)

                        Rectangle()
                            .fill(Color(red: 65/255, green: 65/255, blue: 65/255))
                            .frame(height: 1)
                            .frame(maxWidth: .infinity)

                        TextField("00.000.000.00", text: $ip)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(width: 120)
                            .background(Color.black)
                            .foregroundColor(.white)
                            .font(.system(size: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 0)
                                    .stroke(Color(red: 65/255, green: 65/255, blue: 65/255), lineWidth: 1)
                            )
                    }

                    // Port row
                    HStack(spacing: 0) {
                        Text("PORT")
                            .foregroundColor(.gray)
                            .font(.system(size: 12, weight: .medium))
                            .frame(width: 40, alignment: .leading)

                        Rectangle()
                            .fill(Color(red: 65/255, green: 65/255, blue: 65/255))
                            .frame(height: 1)
                            .frame(maxWidth: .infinity)

                        TextField("0000", text: $port)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(width: 80)
                            .background(Color.black)
                            .foregroundColor(.white)
                            .font(.system(size: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 0)
                                    .stroke(Color(red: 65/255, green: 65/255, blue: 65/255), lineWidth: 1)
                            )
                    }

                    HStack(spacing: 0) {
                        Text("API-KEY")
                            .foregroundColor(.gray)
                            .font(.system(size: 12, weight: .medium))
                            .frame(width: 60, alignment: .leading)

                        Rectangle()
                            .fill(Color(red: 65/255, green: 65/255, blue: 65/255))
                            .frame(height: 1)
                            .frame(maxWidth: .infinity)

                        Group {
                            if isApiKeyEditable || apiKey.isEmpty {
                                TextField("Enter new API key", text: $apiKey)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                            } else {
                                Text(censoredApiKey)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(width: 120, alignment: .leading)
                        .background(Color.black)
                        .foregroundColor(.white)
                        .font(.system(size: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 0)
                                .stroke(Color(red: 65/255, green: 65/255, blue: 65/255), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 15)

                VStack(alignment: .leading, spacing: 32) {
                        RegularButton(Label: connectionButtonText, action: {
                            testConnection()
                        }, color: connectionStatus == .success ? "ObServeGreen" : (connectionStatus == .failed ? "ObServeRed" : "ObServeBlue"))
                    }.padding(.horizontal, 15)
            }
            .padding(.vertical, 30)
            .background(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
            )
            .overlay(alignment: .topLeading) {
                HStack {
                    Text("CONNECTION")
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .medium))
                }
                .padding(10)
                .background(Color.black)
                .padding(.top, -20)
                .padding(.leading, 10)
            }

            // UNSAFE ZONE Section
            VStack(spacing: 16) {
                // Reset API Key Button
                RegularButton(Label: "RESET API KEY", action: {
                    if SettingsManager.shared.safeModeEnabled {
                        showResetApiKeyConfirmation = true
                    } else {
                        resetApiKey()
                    }
                }, color: "ObServeGray")

                // Delete Server Button
                RegularButton(Label: "DELETE SERVER", action: {
                    if SettingsManager.shared.safeModeEnabled {
                        showDeleteConfirmation = true
                    } else {
                        deleteServer()
                    }
                }, color: "ObServeRed")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
            )
            .overlay(alignment: .topLeading) {
                HStack {
                    Text("UNSAFE ZONE")
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .medium))
                }
                .padding(10)
                .background(Color.black)
                .padding(.top, -20)
                .padding(.leading, 10)
            }

            // Save and Discard Buttons
            HStack(spacing: 16) {
                RegularButton(Label: "DISCARD", action: {
                    onDismiss()
                }, color: "ObServeGray")

                RegularButton(Label: "SAVE", action: {
                    saveChanges()
                }, color: "ObServeGreen")
            }

            Spacer()
        }
    }

    // Step 1: Machine Type Selection
    private var machineTypeView: some View {
        VStack(spacing: 16) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                ForEach(MachineType.allCases, id: \.self) { type in
                    machineTypeCard(type: type)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func machineTypeCard(type: MachineType) -> some View {
        Button(action: {
            selectedMachineType = type
        }) {
            let isSelected = selectedMachineType == type

            VStack(spacing: 12) {
                ZStack {
                    Image(type.imageName(isSelected: false))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .opacity(isSelected ? 0.0 : 1.0)

                    Image(type.imageName(isSelected: true))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .opacity(isSelected ? 1.0 : 0.0)
                }
                .frame(width: 96, height: 96)

                Text(type.rawValue)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? .white : .gray)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(
                Color(red: 15/255, green: 15/255, blue: 15/255)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(isSelected ? Color.white.opacity(0.6) : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // Step 2: Naming
    private var namingView: some View {
        VStack(spacing: 32) {
            Spacer()
            VStack(spacing: 24) {
                // Selected machine type display
                VStack(spacing: 12) {
                    if let machineType = selectedMachineType {
                        Image(machineType.imageName(isSelected: false))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                }
                .frame(width: 150, height: 150)

                // Name input
                VStack(alignment: .leading, spacing: 4) {
                    Text("MACHINE NAME")
                        .foregroundColor(.gray)
                        .font(.system(size: 12))

                    TextField("My \(selectedMachineType?.rawValue ?? "Machine")", text: $name)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(12)
                        .background(Color(red: 15/255, green: 15/255, blue: 15/255))
                        .foregroundColor(.white)
                        .overlay(RoundedRectangle(cornerRadius: 0)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1))
                }
            }

            Spacer()
        }
    }

    // MARK: - Helper Views
    private func infoLabel(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .foregroundColor(Color.gray)
                .font(.system(size: 12, weight: .medium))
            Text(value)
                .foregroundColor(.white)
                .font(.system(size: 14))
        }
    }

    private func unsafeZoneOption(title: String, systemImage: String, isDestructive: Bool = false) -> some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 12))
                .foregroundColor(isDestructive ? Color("ObServeRed") : .gray)
                .frame(width: 16)

            Text(title)
                .font(.system(size: 11))
                .foregroundColor(isDestructive ? Color("ObServeRed") : .gray)
                .lineLimit(1)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    // MARK: - Navigation
    private var navigationView: some View {
        HStack(spacing: 16) {
            RegularButton(Label: "BACK", action: {
                switch currentStep {
                case .editMachineType:
                    currentStep = .overview
                case .editNaming:
                    currentStep = .editMachineType
                default:
                    break
                }
            }, color: "ObServeGray")

            RegularButton(Label: "NEXT", action: {
                switch currentStep {
                case .editMachineType:
                    if selectedMachineType != nil {
                        currentStep = .editNaming
                    }
                case .editNaming:
                    currentStep = .overview
                default:
                    break
                }
            }, color: "ObServeBlue", disabled: !canProceed)
        }
        .padding(20)
    }

    private var saveButtonView: some View {
        HStack(spacing: 16) {
            RegularButton(Label: "DISCARD", action: {
                onDismiss()
            }, color: "ObServeGray")

            RegularButton(Label: "SAVE", action: {
                saveChanges()
            }, color: "ObServeGreen")
        }
        .padding(20)
    }

    // MARK: - Computed Properties
    private var canProceed: Bool {
        switch currentStep {
        case .editMachineType:
            return selectedMachineType != nil
        case .editNaming:
            return true
        default:
            return true
        }
    }

    private var connectionButtonText: String {
        switch connectionStatus {
        case .idle: return "TEST CONNECTION"
        case .connecting: return "CONNECTING..."
        case .success: return "SUCCESS"
        case .failed: return "TRY AGAIN"
        }
    }

    // MARK: - Actions
    private func testConnection() {
        connectionStatus = .connecting

        let networkService = NetworkService(ip: ip, port: port, apiKey: apiKey)
        networkService.checkHealth { isHealthy in
            DispatchQueue.main.async {
                if isHealthy {
                    self.connectionStatus = .success
                } else {
                    self.connectionStatus = .failed
                }
            }
        }
    }

    private func saveChanges() {
        let updatedServer = server
        updatedServer.name = name
        updatedServer.ip = ip
        updatedServer.port = port
        updatedServer.apiKey = apiKey
        updatedServer.type = selectedMachineType?.rawValue ?? server.type

        if connectionStatus == .success {
            updatedServer.isConnected = true
            updatedServer.isHealthy = true
            updatedServer.lastConnected = Date()
        }

        onSave(updatedServer)
        onDismiss()
    }

    private func deleteServer() {
        onDelete?()
        onDismiss()
    }

    private func resetApiKey() {
        apiKey = ""
        isApiKeyEditable = true
        Haptics.notification(.success)
    }
}

#Preview {
    ManageServerView(
        server: ServerModuleItem(
            name: "Test Server",
            ip: "192.168.1.100",
            port: "42000",
            apiKey: "test-key",
            type: "SERVER"
        ),
        onDismiss: {},
        onSave: { _ in },
        onDelete: {
            print("Server deleted")
        }
    )
}
