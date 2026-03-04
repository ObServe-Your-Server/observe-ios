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
    var onDismiss: () -> Void
    var onSave: (ServerModuleItem) -> Void
    var onDelete: (() -> Void)? = nil

    @StateObject private var viewModel: ManageServerViewModel
    @State private var contentHasScrolled = false

    init(server: ServerModuleItem, onDismiss: @escaping () -> Void, onSave: @escaping (ServerModuleItem) -> Void, onDelete: (() -> Void)? = nil) {
        self.onDismiss = onDismiss
        self.onSave = onSave
        self.onDelete = onDelete
        _viewModel = StateObject(wrappedValue: ManageServerViewModel(server: server))
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                AppBar(
                    serverName: viewModel.headerTitle,
                    contentHasScrolled: $contentHasScrolled,
                    onClose: {
                        if viewModel.currentStep != .overview {
                            viewModel.currentStep = .overview
                        } else {
                            onDismiss()
                        }
                    }
                )

                contentView

                if viewModel.currentStep != .overview {
                    navigationView
                }
            }
            .background(Color.black)
        }
        .confirmationDialog("Delete Server", isPresented: $viewModel.showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete \(viewModel.server.name)", role: .destructive) {
                viewModel.deleteServer(onDelete: onDelete, onDismiss: onDismiss)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \(viewModel.server.name)? This action cannot be undone.")
        }
        .confirmationDialog("Refresh API Key", isPresented: $viewModel.showRefreshApiKeyConfirmation, titleVisibility: .visible) {
            Button("Refresh API Key", role: .destructive) {
                Task { await viewModel.refreshApiKey() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will generate a new API key. The old key will stop working. You'll need to update the key on your machine agent.")
        }
    }

    // MARK: - Content Views
    private var contentView: some View {
        Group {
            switch viewModel.currentStep {
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

    // Overview - Main Management View
    private var overviewView: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 5)

            VStack(alignment: .leading, spacing: 16) {
                Spacer().frame(height: 5)

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 16) {
                        infoLabel(label: "NAME", value: viewModel.resolvedName)
                        infoLabel(label: "TYPE", value: viewModel.selectedMachineType?.rawValue ?? "Unknown")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack {
                        if let machineType = viewModel.selectedMachineType {
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
                    viewModel.currentStep = .editMachineType
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
                if let newKey = viewModel.refreshedApiKey {
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
            .padding(.vertical, viewModel.refreshedApiKey != nil ? 20 : 0)
            .background(
                Group {
                    if viewModel.refreshedApiKey != nil {
                        RoundedRectangle(cornerRadius: 0)
                            .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
                    }
                }
            )

            // UNSAFE ZONE Section
            VStack(spacing: 16) {
                RegularButton(Label: "REFRESH API KEY", action: {
                    viewModel.handleRefreshApiKeyTap()
                }, color: "ObServeGray")

                RegularButton(Label: "DELETE SERVER", action: {
                    if SettingsManager.shared.safeModeEnabled {
                        viewModel.showDeleteConfirmation = true
                    } else {
                        viewModel.deleteServer(onDelete: onDelete, onDismiss: onDismiss)
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
            HStack(spacing: 18) {
                RegularButton(Label: "SAVE", action: {
                    Task { await viewModel.saveChanges(onSave: onSave, onDismiss: onDismiss) }
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
            viewModel.selectedMachineType = type
        }) {
            let isSelected = viewModel.selectedMachineType == type

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
                    if let machineType = viewModel.selectedMachineType {
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

                    TextField("My \(viewModel.selectedMachineType?.rawValue ?? "Machine")", text: $viewModel.name)
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
                viewModel.navigateBack()
            }, color: "ObServeGray")

            RegularButton(Label: "NEXT", action: {
                viewModel.navigateNext()
            }, color: "ObServeBlue", disabled: !viewModel.canProceed)
        }
        .padding(20)
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
