//
//  ManageServerViewModel.swift
//  ObServe
//

import SwiftUI

@MainActor
class ManageServerViewModel: ObservableObject {

    @Published var currentStep: ManageStep = .overview
    @Published var selectedMachineType: MachineType?
    @Published var name: String = ""
    @Published var refreshedApiKey: String?
    @Published var showDeleteConfirmation = false
    @Published var showRefreshApiKeyConfirmation = false

    let server: ServerModuleItem

    init(server: ServerModuleItem) {
        self.server = server
        self.name = server.name
        self.selectedMachineType = MachineType.allCases.first(where: {
            $0.rawValue.uppercased() == server.type.uppercased()
        })
    }

    // MARK: - Computed Properties

    var headerTitle: String {
        switch currentStep {
        case .overview:
            return "MANAGE \(server.name.uppercased())"
        case .editMachineType:
            return "MACHINE TYPE"
        case .editNaming:
            return "MACHINE NAME"
        }
    }

    var resolvedName: String {
        name.isEmpty ? "My \(selectedMachineType?.rawValue ?? "Machine")" : name
    }

    var canProceed: Bool {
        switch currentStep {
        case .editMachineType:
            return selectedMachineType != nil
        case .editNaming:
            return true
        default:
            return true
        }
    }

    // MARK: - Navigation

    func navigateBack() {
        switch currentStep {
        case .editMachineType:
            currentStep = .overview
        case .editNaming:
            currentStep = .editMachineType
        default:
            break
        }
    }

    func navigateNext() {
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
    }

    // MARK: - Actions

    func saveChanges(onSave: (ServerModuleItem) -> Void, onDismiss: () -> Void) async {
        let updatedServer = server
        updatedServer.name = name
        updatedServer.type = selectedMachineType?.rawValue ?? server.type

        let request = UpdateMachineRequest(
            type: selectedMachineType?.rawValue,
            name: name.isEmpty ? nil : name,
            description: nil,
            location: nil
        )

        do {
            _ = try await WatchTowerAPI.shared.updateMachine(uuid: server.machineUUID, request: request)
            print("ManageServerViewModel: Machine updated on backend")
        } catch {
            print("ManageServerViewModel: Failed to update on backend: \(error.localizedDescription)")
        }

        onSave(updatedServer)
        onDismiss()
    }

    func deleteServer(onDelete: (() -> Void)?, onDismiss: () -> Void) {
        onDelete?()
        onDismiss()
    }

    func refreshApiKey() async {
        do {
            let data = try await WatchTowerAPI.shared.refreshAPIKey(uuid: server.machineUUID)
            if let response = try? JSONDecoder().decode(MachineEntityResponse.self, from: data) {
                refreshedApiKey = response.apiKey
                server.apiKey = response.apiKey ?? ""
            } else if let rawString = String(data: data, encoding: .utf8) {
                refreshedApiKey = rawString.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            Haptics.notification(.success)
        } catch {
            print("ManageServerViewModel: Failed to refresh API key: \(error.localizedDescription)")
            Haptics.notification(.error)
        }
    }

    // MARK: - Safe Mode Helpers

    func handleRefreshApiKeyTap() {
        if SettingsManager.shared.safeModeEnabled {
            showRefreshApiKeyConfirmation = true
        } else {
            Task { await refreshApiKey() }
        }
    }

    func handleDeleteTap() {
        if SettingsManager.shared.safeModeEnabled {
            showDeleteConfirmation = true
        } else {
            // Caller must handle via onDelete
        }
    }
}
