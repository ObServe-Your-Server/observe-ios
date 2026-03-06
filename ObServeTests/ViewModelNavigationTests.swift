//
//  ViewModelNavigationTests.swift
//  ObServeTests
//
//  Tests for ViewModel pure navigation logic (no network calls).
//  Tests OnboardingViewModel and ManageServerViewModel state machines.
//

import Foundation
import Testing
@testable import ObServe

// MARK: - OnboardingViewModel Tests

@MainActor
struct OnboardingViewModelTests {

    // MARK: - Initial State

    @Test func initialState() {
        let vm = OnboardingViewModel()
        #expect(vm.currentStep == .machineType)
        #expect(vm.selectedMachineType == nil)
        #expect(vm.name == "")
        #expect(vm.creationStatus == .idle)
        #expect(vm.createdMachine == nil)
        #expect(vm.errorMessage == "")
    }

    // MARK: - canProceed

    @Test func cannotProceedWithoutMachineType() {
        let vm = OnboardingViewModel()
        #expect(vm.canProceed == false)
    }

    @Test func canProceedWithMachineType() {
        let vm = OnboardingViewModel()
        vm.selectedMachineType = .server
        #expect(vm.canProceed == true)
    }

    @Test func canProceedOnNamingStep() {
        let vm = OnboardingViewModel()
        vm.currentStep = .naming
        #expect(vm.canProceed == true)
    }

    @Test func cannotProceedOnCreatingStepWhenIdle() {
        let vm = OnboardingViewModel()
        vm.currentStep = .creating
        vm.creationStatus = .idle
        #expect(vm.canProceed == false)
    }

    @Test func canProceedOnCreatingStepWhenSuccess() {
        let vm = OnboardingViewModel()
        vm.currentStep = .creating
        vm.creationStatus = .success
        #expect(vm.canProceed == true)
    }

    @Test func canProceedOnConfirmationStep() {
        let vm = OnboardingViewModel()
        vm.currentStep = .confirmation
        #expect(vm.canProceed == true)
    }

    // MARK: - nextButtonLabel

    @Test func nextButtonLabels() {
        let vm = OnboardingViewModel()

        vm.currentStep = .machineType
        #expect(vm.nextButtonLabel == "NEXT")

        vm.currentStep = .naming
        #expect(vm.nextButtonLabel == "CREATE")

        vm.currentStep = .creating
        #expect(vm.nextButtonLabel == "NEXT")

        vm.currentStep = .confirmation
        #expect(vm.nextButtonLabel == "FINISH")
    }

    // MARK: - resolvedName

    @Test func resolvedNameUsesCustomName() {
        let vm = OnboardingViewModel()
        vm.selectedMachineType = .server
        vm.name = "My Custom Server"
        #expect(vm.resolvedName == "My Custom Server")
    }

    @Test func resolvedNameFallsBackToMachineType() {
        let vm = OnboardingViewModel()
        vm.selectedMachineType = .laptop
        vm.name = ""
        #expect(vm.resolvedName == "My LAPTOP")
    }

    @Test func resolvedNameFallsBackToMachineWhenNoType() {
        let vm = OnboardingViewModel()
        vm.name = ""
        #expect(vm.resolvedName == "My Machine")
    }

    // MARK: - Navigation: nextStep

    @Test func nextStepFromMachineTypeWithSelection() {
        let vm = OnboardingViewModel()
        vm.selectedMachineType = .server
        vm.nextStep(onComplete: { _, _ in })
        #expect(vm.currentStep == .naming)
    }

    @Test func nextStepFromMachineTypeWithoutSelection() {
        let vm = OnboardingViewModel()
        vm.nextStep(onComplete: { _, _ in })
        #expect(vm.currentStep == .machineType) // stays
    }

    @Test func nextStepFromNaming() {
        let vm = OnboardingViewModel()
        vm.currentStep = .naming
        vm.nextStep(onComplete: { _, _ in })
        #expect(vm.currentStep == .creating)
    }

    @Test func nextStepFromCreatingWhenNotSuccess() {
        let vm = OnboardingViewModel()
        vm.currentStep = .creating
        vm.creationStatus = .idle
        vm.nextStep(onComplete: { _, _ in })
        #expect(vm.currentStep == .creating) // stays
    }

    @Test func nextStepFromCreatingWhenSuccess() {
        let vm = OnboardingViewModel()
        vm.currentStep = .creating
        vm.creationStatus = .success
        vm.nextStep(onComplete: { _, _ in })
        #expect(vm.currentStep == .confirmation)
    }

    // MARK: - Navigation: previousStep

    @Test func previousStepFromNaming() {
        let vm = OnboardingViewModel()
        vm.currentStep = .naming
        vm.previousStep()
        #expect(vm.currentStep == .machineType)
    }

    @Test func previousStepFromMachineTypeStays() {
        let vm = OnboardingViewModel()
        vm.currentStep = .machineType
        vm.previousStep()
        #expect(vm.currentStep == .machineType)
    }

    @Test func previousStepFromCreating() {
        let vm = OnboardingViewModel()
        vm.currentStep = .creating
        vm.previousStep()
        #expect(vm.currentStep == .naming)
    }

    // MARK: - Reset

    @Test func resetToStart() {
        let vm = OnboardingViewModel()
        vm.currentStep = .confirmation
        vm.creationStatus = .success
        vm.selectedMachineType = .server

        vm.resetToStart()

        #expect(vm.currentStep == .machineType)
        #expect(vm.creationStatus == .idle)
        #expect(vm.createdMachine == nil)
        // selectedMachineType is NOT reset by resetToStart
    }
}

// MARK: - ManageServerViewModel Tests

@MainActor
struct ManageServerViewModelTests {

    private func makeServer(name: String = "Test Server", type: String = "SERVER") -> ServerModuleItem {
        ServerModuleItem(machineUUID: UUID(), name: name, type: type)
    }

    // MARK: - Initial State

    @Test func initialStateMatchesServer() {
        let server = makeServer(name: "My Box", type: "LAPTOP")
        let vm = ManageServerViewModel(server: server)

        #expect(vm.currentStep == .overview)
        #expect(vm.name == "My Box")
        #expect(vm.selectedMachineType == .laptop)
        #expect(vm.refreshedApiKey == nil)
        #expect(vm.showDeleteConfirmation == false)
        #expect(vm.showRefreshApiKeyConfirmation == false)
    }

    @Test func initialStateMatchesMachineType() {
        let server = makeServer(type: "VM")
        let vm = ManageServerViewModel(server: server)
        #expect(vm.selectedMachineType == .vm)
    }

    @Test func initialStateUnknownTypeIsNil() {
        let server = makeServer(type: "UNKNOWN_TYPE")
        let vm = ManageServerViewModel(server: server)
        #expect(vm.selectedMachineType == nil)
    }

    // MARK: - headerTitle

    @Test func headerTitleOverview() {
        let server = makeServer(name: "MyServer")
        let vm = ManageServerViewModel(server: server)
        vm.currentStep = .overview
        #expect(vm.headerTitle == "MANAGE MYSERVER")
    }

    @Test func headerTitleEditMachineType() {
        let server = makeServer()
        let vm = ManageServerViewModel(server: server)
        vm.currentStep = .editMachineType
        #expect(vm.headerTitle == "MACHINE TYPE")
    }

    @Test func headerTitleEditNaming() {
        let server = makeServer()
        let vm = ManageServerViewModel(server: server)
        vm.currentStep = .editNaming
        #expect(vm.headerTitle == "MACHINE NAME")
    }

    // MARK: - resolvedName

    @Test func resolvedNameUsesCustomName() {
        let server = makeServer()
        let vm = ManageServerViewModel(server: server)
        vm.name = "Custom Name"
        #expect(vm.resolvedName == "Custom Name")
    }

    @Test func resolvedNameFallsBackToType() {
        let server = makeServer()
        let vm = ManageServerViewModel(server: server)
        vm.name = ""
        vm.selectedMachineType = .tower
        #expect(vm.resolvedName == "My TOWER")
    }

    // MARK: - canProceed

    @Test func canProceedOnOverview() {
        let server = makeServer()
        let vm = ManageServerViewModel(server: server)
        vm.currentStep = .overview
        #expect(vm.canProceed == true)
    }

    @Test func canProceedOnEditMachineTypeWithSelection() {
        let server = makeServer()
        let vm = ManageServerViewModel(server: server)
        vm.currentStep = .editMachineType
        vm.selectedMachineType = .cube
        #expect(vm.canProceed == true)
    }

    @Test func cannotProceedOnEditMachineTypeWithoutSelection() {
        let server = makeServer()
        let vm = ManageServerViewModel(server: server)
        vm.currentStep = .editMachineType
        vm.selectedMachineType = nil
        #expect(vm.canProceed == false)
    }

    @Test func canProceedOnEditNaming() {
        let server = makeServer()
        let vm = ManageServerViewModel(server: server)
        vm.currentStep = .editNaming
        #expect(vm.canProceed == true)
    }

    // MARK: - Navigation

    @Test func navigateBackFromEditMachineType() {
        let server = makeServer()
        let vm = ManageServerViewModel(server: server)
        vm.currentStep = .editMachineType
        vm.navigateBack()
        #expect(vm.currentStep == .overview)
    }

    @Test func navigateBackFromEditNaming() {
        let server = makeServer()
        let vm = ManageServerViewModel(server: server)
        vm.currentStep = .editNaming
        vm.navigateBack()
        #expect(vm.currentStep == .editMachineType)
    }

    @Test func navigateBackFromOverviewDoesNothing() {
        let server = makeServer()
        let vm = ManageServerViewModel(server: server)
        vm.currentStep = .overview
        vm.navigateBack()
        #expect(vm.currentStep == .overview)
    }

    @Test func navigateNextFromEditMachineTypeWithSelection() {
        let server = makeServer()
        let vm = ManageServerViewModel(server: server)
        vm.currentStep = .editMachineType
        vm.selectedMachineType = .server
        vm.navigateNext()
        #expect(vm.currentStep == .editNaming)
    }

    @Test func navigateNextFromEditMachineTypeWithoutSelection() {
        let server = makeServer()
        let vm = ManageServerViewModel(server: server)
        vm.currentStep = .editMachineType
        vm.selectedMachineType = nil
        vm.navigateNext()
        #expect(vm.currentStep == .editMachineType) // stays
    }

    @Test func navigateNextFromEditNaming() {
        let server = makeServer()
        let vm = ManageServerViewModel(server: server)
        vm.currentStep = .editNaming
        vm.navigateNext()
        #expect(vm.currentStep == .overview)
    }

    @Test func navigateNextFromOverviewDoesNothing() {
        let server = makeServer()
        let vm = ManageServerViewModel(server: server)
        vm.currentStep = .overview
        vm.navigateNext()
        #expect(vm.currentStep == .overview)
    }

    // MARK: - deleteServer

    @Test func deleteServerCallsCallbacks() {
        let server = makeServer()
        let vm = ManageServerViewModel(server: server)
        var deleteCalled = false
        var dismissCalled = false

        vm.deleteServer(
            onDelete: { deleteCalled = true },
            onDismiss: { dismissCalled = true }
        )

        #expect(deleteCalled)
        #expect(dismissCalled)
    }

    @Test func deleteServerNilOnDelete() {
        let server = makeServer()
        let vm = ManageServerViewModel(server: server)
        var dismissCalled = false

        vm.deleteServer(
            onDelete: nil,
            onDismiss: { dismissCalled = true }
        )

        #expect(dismissCalled)
    }
}
