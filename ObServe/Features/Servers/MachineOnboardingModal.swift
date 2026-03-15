import SwiftUI

enum OnboardingStep: Int, CaseIterable {
    case machineType = 0
    case naming = 1
    case creating = 2
    case confirmation = 3

    var title: String {
        switch self {
        case .machineType: "MACHINE TYPE"
        case .naming: "MACHINE NAME"
        case .creating: "CREATING MACHINE"
        case .confirmation: "YOUR SETUP"
        }
    }
}

enum CreationStatus {
    case idle
    case creating
    case success
    case failed
}

struct MachineOnboardingModal: View {
    var onDismiss: () -> Void
    var onComplete: (ServerModuleItem, MachineType) -> Void

    @StateObject private var viewModel = OnboardingViewModel()
    @State private var contentHasScrolled = false

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                AppBar(
                    serverName: viewModel.currentStep.title,
                    contentHasScrolled: $contentHasScrolled,
                    currentStep: viewModel.currentStep.rawValue,
                    totalSteps: OnboardingStep.allCases.count,
                    onClose: { viewModel.cancelAndCleanup(onDismiss: onDismiss) }
                )

                // Content
                contentView

                // Navigation
                navigationView
            }
            .background(Color.black)
        }
    }

    // MARK: - Content Views

    private var contentView: some View {
        Group {
            switch viewModel.currentStep {
            case .machineType:
                machineTypeView
            case .naming:
                namingView
            case .creating:
                creatingView
            case .confirmation:
                confirmationView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
    }

    /// Step 1: Machine Type Selection
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
                    .font(.plexSans(size: 18))
                    .foregroundColor(isSelected ? .white : .gray)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(
                Color(red: 15 / 255, green: 15 / 255, blue: 15 / 255)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(isSelected ? Color.white.opacity(0.6) : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    /// Step 2: Naming
    private var namingView: some View {
        VStack(spacing: 32) {
            Spacer()
            VStack(spacing: 24) {
                // Selected machine type display
                VStack(spacing: 12) {
                    if let machineType = viewModel.selectedMachineType {
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
                        .font(.plexSans(size: 12))

                    TextField("My \(viewModel.selectedMachineType?.rawValue ?? "Machine")", text: $viewModel.name)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(12)
                        .background(Color(red: 15 / 255, green: 15 / 255, blue: 15 / 255))
                        .foregroundColor(.white)
                        .overlay(RoundedRectangle(cornerRadius: 0)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1))
                }
            }

            Spacer()
        }
    }

    /// Step 3: Creating machine on backend
    private var creatingView: some View {
        VStack(spacing: 24) {
            Spacer()

            switch viewModel.creationStatus {
            case .idle, .creating:
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                Text("CREATING MACHINE...")
                    .foregroundColor(.gray)
                    .font(.plexSans(size: 14))

            case .success:
                if let apiKey = viewModel.createdMachine?.apiKey, !apiKey.isEmpty {
                    VStack(spacing: 8) {
                        Text(apiKey)
                            .foregroundColor(.white)
                            .font(.plexSans(size: 12))
                            .padding(12)
                            .background(Color(red: 15 / 255, green: 15 / 255, blue: 15 / 255))
                            .overlay(RoundedRectangle(cornerRadius: 0)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1))
                            .textSelection(.enabled)

                        Text("Copy this key and configure it on your machine agent")
                            .foregroundColor(.gray)
                            .font(.plexSans(size: 10))
                    }
                }

            case .failed:
                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .frame(width: 48, height: 48)
                    .foregroundColor(.red)
                Text("CREATION FAILED")
                    .foregroundColor(.white)
                    .font(.plexSans(size: 14, weight: .medium))

                RegularButton(Label: "TRY AGAIN", action: {
                    Task { await viewModel.createMachineOnBackend() }
                }, color: "ObServeBlue")
            }

            Spacer()
        }
        .onAppear {
            if viewModel.creationStatus == .idle {
                Task { await viewModel.createMachineOnBackend() }
            }
        }
    }

    /// Step 4: Confirmation
    private var confirmationView: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 5)

            VStack(alignment: .leading, spacing: 16) {
                Spacer().frame(height: 5)

                // Server info and icon section
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 16) {
                        infoLabel(label: "TYPE", value: viewModel.selectedMachineType?.rawValue ?? "Unknown")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 16) {
                        infoLabel(label: "NAME", value: viewModel.resolvedName)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Server icon
                    VStack {
                        if let machineType = viewModel.selectedMachineType {
                            Image(machineType.imageName(isSelected: true))
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 96, maxHeight: 96)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                RegularButton(Label: "CHANGE", action: {
                    viewModel.resetToStart()
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
                        .font(.plexSans(size: 14, weight: .medium))
                }
                .padding(10)
                .background(Color.black)
                .padding(.top, -20)
                .padding(.leading, 10)
            }

            if let apiKey = viewModel.createdMachine?.apiKey, !apiKey.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 0) {
                        Text("API-KEY")
                            .foregroundColor(.gray)
                            .font(.plexSans(size: 12, weight: .medium))
                            .frame(width: 60, alignment: .leading)
                    }
                    Text(apiKey)
                        .foregroundColor(.white)
                        .font(.plexSans(size: 11))
                        .padding(12)
                        .background(Color(red: 15 / 255, green: 15 / 255, blue: 15 / 255))
                        .overlay(RoundedRectangle(cornerRadius: 0)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1))
                        .textSelection(.enabled)

                    HStack {
                        Image(systemName: "exclamationmark")
                            .foregroundColor(.white)
                        Text("configure this API key on your machine agent")
                            .foregroundColor(.gray)
                            .font(.plexSans(size: 10))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
                )
                .overlay(alignment: .topLeading) {
                    HStack {
                        Text("CONNECTION")
                            .foregroundColor(.white)
                            .font(.plexSans(size: 14, weight: .medium))
                    }
                    .padding(10)
                    .background(Color.black)
                    .padding(.top, -20)
                    .padding(.leading, 10)
                }
            }

            Spacer()
        }
    }

    private func infoLabel(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .foregroundColor(Color.gray)
                .font(.plexSans(size: 12, weight: .medium))
            Text(value)
                .foregroundColor(.white)
                .font(.plexSans(size: 14))
        }
    }

    // MARK: - Navigation

    private var navigationView: some View {
        HStack(spacing: 18) {
            RegularButton(Label: "BACK", action: { viewModel.previousStep() }, color: "ObServeGray")
            RegularButton(
                Label: viewModel.nextButtonLabel,
                action: { viewModel.nextStep(onComplete: onComplete) },
                color: "ObServeBlue",
                disabled: !viewModel.canProceed
            )
        }
        .padding(20)
    }
}

#Preview {
    MachineOnboardingModal(
        onDismiss: {},
        onComplete: { _, _ in }
    )
}
