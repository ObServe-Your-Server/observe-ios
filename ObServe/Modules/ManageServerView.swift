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
    @State private var deleteBoolean: Bool = false

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

        // Debug logging
        if matchedType == nil {
            print("⚠️ ManageServerView: Could not find MachineType for", server.type)
            print("   Available types:", MachineType.allCases.map { $0.rawValue })
        } else {
            print("✅ ManageServerView: Successfully matched type", server.type, "to", matchedType!.rawValue)
        }
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
                } else {
                    saveButtonView
                }
            }
            .frame(maxWidth: 600, maxHeight: 700)
            .background(Color.black)
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
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 16) {
                        // Type label
                        infoLabel(label: "TYPE", value: selectedMachineType?.rawValue ?? "Unknown")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 16) {
                        // Name label
                        infoLabel(label: "NAME", value: name.isEmpty ? "My \(selectedMachineType?.rawValue ?? "Machine")" : name)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Server icon
                    VStack {
                        if let machineType = selectedMachineType {
                            Image(machineType.imageName(isSelected: true))
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 96, maxHeight: 96)
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

                        TextField("goofy-ahh-key", text: $apiKey)
                            .textFieldStyle(PlainTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
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

            VStack(spacing: 20) {
                SettingRow(
                    title: "DO YOU WANT TO DELETE THIS SERVER?",
                    binding: $deleteBoolean
                )
                RegularButton(Label: "DELETE", action: {
                    deleteServer()
                }, color: "ObServeRed", disabled: !deleteBoolean)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 15)
            .padding(.top, 20)

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
            RegularButton(Label: "SAVE CHANGES", action: {
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
