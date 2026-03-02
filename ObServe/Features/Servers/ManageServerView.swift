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
    @State private var contentHasScrolled = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var showRefreshApiKeyConfirmation = false
    @State private var refreshedApiKey: String?

    init(server: ServerModuleItem, onDismiss: @escaping () -> Void, onSave: @escaping (ServerModuleItem) -> Void, onDelete: (() -> Void)? = nil) {
        self.server = server
        self.onDismiss = onDismiss
        self.onSave = onSave
        self.onDelete = onDelete

        _name = State(initialValue: server.name)

        let matchedType = MachineType.allCases.first(where: { $0.rawValue.uppercased() == server.type.uppercased() })
        _selectedMachineType = State(initialValue: matchedType)
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                AppBar(
                    serverName: headerTitle,
                    contentHasScrolled: $contentHasScrolled,
                    onClose: {
                        if currentStep != .overview {
                            currentStep = .overview
                        } else {
                            onDismiss()
                        }
                    }
                )

                contentView

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
        .confirmationDialog("Refresh API Key", isPresented: $showRefreshApiKeyConfirmation, titleVisibility: .visible) {
            Button("Refresh API Key", role: .destructive) {
                refreshApiKey()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will generate a new API key. The old key will stop working. You'll need to update the key on your machine agent.")
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

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 16) {
                        infoLabel(label: "NAME", value: name.isEmpty ? "My \(selectedMachineType?.rawValue ?? "Machine")" : name)
                        infoLabel(label: "TYPE", value: selectedMachineType?.rawValue ?? "Unknown")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack {
                        if let machineType = selectedMachineType {
                            ZStack {
                                Image(machineType.imageName(isSelected: false))
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: 96, maxHeight: 96)

                                Image(machineType.imageName(isSelected: true))
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: 96, maxHeight: 96)
                                    .opacity(1.0)
                            }
                        } else {
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

            // API Key display
            VStack(alignment: .leading, spacing: 12) {
                if let newKey = refreshedApiKey {
                    HStack(spacing: 0) {
                        Text("NEW API-KEY")
                            .foregroundColor(.gray)
                            .font(.system(size: 12, weight: .medium))
                            .frame(width: 80, alignment: .leading)

                        Text(newKey)
                            .foregroundColor(.white)
                            .font(.system(size: 12, design: .monospaced))
                            .textSelection(.enabled)
                    }

                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.yellow)
                        Text("Update this key on your machine agent")
                            .foregroundColor(.gray)
                            .font(.system(size: 10))
                    }
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, refreshedApiKey != nil ? 20 : 0)
            .background(
                Group {
                    if refreshedApiKey != nil {
                        RoundedRectangle(cornerRadius: 0)
                            .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
                    }
                }
            )

            // UNSAFE ZONE Section
            VStack(spacing: 16) {
                RegularButton(Label: "REFRESH API KEY", action: {
                    if SettingsManager.shared.safeModeEnabled {
                        showRefreshApiKeyConfirmation = true
                    } else {
                        refreshApiKey()
                    }
                }, color: "ObServeGray")

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
                RegularButton(Label: "SAVE", action: {
                    saveChanges()
                }, color: "ObServeGreen")
                
                RegularButton(Label: "DISCARD", action: {
                    onDismiss()
                }, color: "ObServeGray")
            }

            Spacer()
        }
    }

    // Machine Type Selection
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

    // Naming
    private var namingView: some View {
        VStack(spacing: 32) {
            Spacer()
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    if let machineType = selectedMachineType {
                        Image(machineType.imageName(isSelected: false))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                }
                .frame(width: 150, height: 150)

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

    // MARK: - Actions
    private func saveChanges() {
        let updatedServer = server
        updatedServer.name = name
        updatedServer.type = selectedMachineType?.rawValue ?? server.type

        // Update on backend
        let request = UpdateMachineRequest(
            type: selectedMachineType?.backendType,
            name: name.isEmpty ? nil : name,
            description: nil,
            location: nil
        )

        WatchTowerAPI.shared.updateMachine(uuid: server.machineUUID, request: request) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("ManageServerView: Machine updated on backend")
                case .failure(let error):
                    print("ManageServerView: Failed to update on backend: \(error.localizedDescription)")
                }
            }
        }

        onSave(updatedServer)
        onDismiss()
    }

    private func deleteServer() {
        onDelete?()
        onDismiss()
    }

    private func refreshApiKey() {
        WatchTowerAPI.shared.refreshAPIKey(uuid: server.machineUUID) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let data):
                    // Try to decode the new API key from the response
                    if let response = try? JSONDecoder().decode(MachineEntityResponse.self, from: data) {
                        refreshedApiKey = response.apiKey
                        server.apiKey = response.apiKey ?? ""
                    } else if let rawString = String(data: data, encoding: .utf8) {
                        refreshedApiKey = rawString.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                    Haptics.notification(.success)
                case .failure(let error):
                    print("ManageServerView: Failed to refresh API key: \(error.localizedDescription)")
                    Haptics.notification(.error)
                }
            }
        }
    }
}

#Preview {
    ManageServerView(
        server: ServerModuleItem(
            machineUUID: UUID(),
            name: "Test Server",
            type: "SERVER"
        ),
        onDismiss: {},
        onSave: { _ in },
        onDelete: {
            print("Server deleted")
        }
    )
}
