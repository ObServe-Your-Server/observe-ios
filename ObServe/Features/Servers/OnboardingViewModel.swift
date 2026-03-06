//
//  OnboardingViewModel.swift
//  ObServe
//

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
        case .machineType: return "NEXT"
        case .naming: return "CREATE"
        case .creating: return "NEXT"
        case .confirmation: return "FINISH"
        }
    }

    var canProceed: Bool {
        switch currentStep {
        case .machineType:
            return selectedMachineType != nil
        case .naming:
            return true
        case .creating:
            return creationStatus == .success
        case .confirmation:
            return true
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
        currentStep = .machineType
        creationStatus = .idle
        createdMachine = nil
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

        newServer.isConnected = true
        newServer.isHealthy = true
        newServer.lastConnected = Date()

        return (newServer, machineType)
    }
}
