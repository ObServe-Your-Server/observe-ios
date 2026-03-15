import SwiftUI

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .machineType
    @Published var selectedMachineType: MachineType?
    @Published var name = ""
    @Published var creationStatus: CreationStatus = .idle
    @Published var createdMachine: MachineEntityResponse?
    @Published var errorMessage = ""

    // MARK: - Computed Properties

    var nextButtonLabel: String {
        switch currentStep {
        case .machineType: "NEXT"
        case .naming: "CREATE"
        case .creating: "NEXT"
        case .confirmation: "FINISH"
        }
    }

    var canProceed: Bool {
        switch currentStep {
        case .machineType:
            selectedMachineType != nil
        case .naming:
            true
        case .creating:
            creationStatus == .success
        case .confirmation:
            true
        }
    }

    var resolvedName: String {
        name.isEmpty ? "My \(selectedMachineType?.rawValue ?? "Machine")" : name
    }

    // MARK: - Navigation

    func previousStep() {
        if currentStep.rawValue > 0 {
            currentStep = OnboardingStep(rawValue: currentStep.rawValue - 1) ?? .machineType
        }
    }

    func nextStep(onComplete: (ServerModuleItem, MachineType) -> Void) {
        switch currentStep {
        case .machineType:
            if selectedMachineType != nil {
                currentStep = .naming
            }
        case .naming:
            currentStep = .creating
        case .creating:
            if creationStatus == .success {
                currentStep = .confirmation
            }
        case .confirmation:
            if let result = buildCompletedServer() {
                onComplete(result.0, result.1)
            }
        }
    }

    func resetToStart() {
        deleteCreatedMachineIfNeeded()
        currentStep = .machineType
        creationStatus = .idle
        createdMachine = nil
    }

    func cancelAndCleanup(onDismiss: () -> Void) {
        deleteCreatedMachineIfNeeded()
        onDismiss()
    }

    // MARK: - Private

    private func deleteCreatedMachineIfNeeded() {
        guard let created = createdMachine,
              let uuid = UUID(uuidString: created.uuid) else { return }
        Task {
            try? await WatchTowerAPI.shared.deleteMachine(uuid: uuid)
        }
    }

    // MARK: - Backend

    func createMachineOnBackend() async {
        guard let machineType = selectedMachineType else { return }

        creationStatus = .creating
        errorMessage = ""

        let request = CreateMachineRequest(
            type: machineType.rawValue,
            name: resolvedName,
            description: nil,
            location: nil
        )

        do {
            let machine = try await WatchTowerAPI.shared.createMachine(request: request)
            createdMachine = machine
            creationStatus = .success
        } catch {
            errorMessage = error.localizedDescription
            creationStatus = .failed
        }
    }

    // MARK: - Helpers

    private static func parseISO8601(_ string: String) -> Date? {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        for format in ["yyyy-MM-dd'T'HH:mm:ss.SSSSSS", "yyyy-MM-dd'T'HH:mm:ss.SSS", "yyyy-MM-dd'T'HH:mm:ss"] {
            f.dateFormat = format
            if let date = f.date(from: string) { return date }
        }
        return ISO8601DateFormatter().date(from: string)
    }

    // MARK: - Private

    private func buildCompletedServer() -> (ServerModuleItem, MachineType)? {
        guard let machineType = selectedMachineType,
              let created = createdMachine,
              let uuid = UUID(uuidString: created.uuid) else { return nil }

        let newServer = ServerModuleItem(
            machineUUID: uuid,
            name: resolvedName,
            type: machineType.rawValue,
            apiKey: created.apiKey ?? ""
        )

        newServer.isConnected = false
        newServer.isHealthy = false
        if let createdAtStr = created.createdAt {
            newServer.createdAt = Self.parseISO8601(createdAtStr)
        }

        return (newServer, machineType)
    }
}
