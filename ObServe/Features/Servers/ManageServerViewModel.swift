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
        name = server.name
        selectedMachineType = MachineType.allCases.first(where: {
            $0.rawValue.uppercased() == server.type.uppercased()
        })
    }

    // MARK: - Computed Properties

    var headerTitle: String {
        switch currentStep {
        case .overview:
            "MANAGE \(server.name.uppercased())"
        case .editMachineType:
            "MACHINE TYPE"
        case .editNaming:
            "MACHINE NAME"
        }
    }

    var resolvedName: String {
        name.isEmpty ? "My \(selectedMachineType?.rawValue ?? "Machine")" : name
    }

    var shareSummary: String {
        var lines = [
            "ObServe",
            "Name: \(resolvedName)",
            "Type: \(selectedMachineType?.rawValue ?? server.type)",
            "Status: \(server.machineStatus.rawValue.capitalized)",
        ]
        if !server.location.isEmpty {
            lines.append("Location: \(server.location)")
        }
        if !server.machineDescription.isEmpty {
            lines.append("Description: \(server.machineDescription)")
        }
        return lines.joined(separator: "\n")
    }

    var creationDateText: String {
        guard let date = server.createdAt else { return "—" }
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: date)
    }

    var observedForText: String {
        guard let date = server.createdAt else { return "—" }
        let diff = max(0, Int(Date().timeIntervalSince(date)))
        let days = diff / 86400
        let hours = (diff % 86400) / 3600
        let minutes = (diff % 3600) / 60
        let seconds = diff % 60
        return String(format: "%02d:%02d:%02d:%02d", days, hours, minutes, seconds)
    }

    var canProceed: Bool {
        switch currentStep {
        case .editMachineType:
            selectedMachineType != nil
        case .editNaming:
            true
        default:
            true
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
