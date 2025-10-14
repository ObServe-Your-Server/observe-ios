//
//  MachineOnboardingModal.swift
//  ObServe
//
//  Created by Daniel Schatz on 19.07.25.
//

import SwiftUI

enum MachineType: String, CaseIterable {
    case server = "SERVER"
    case singleBoard = "SINGLE BOARD"
    case cube = "CUBE"
    case tower = "TOWER"
    case vm = "VM"
    case laptop = "LAPTOP"

    var icon: String {
        switch self {
        case .server: return "server.rack"
        case .singleBoard: return "cpu"
        case .cube: return "cube"
        case .tower: return "desktopcomputer"
        case .vm: return "square.3.layers.3d"
        case .laptop: return "laptopcomputer"
        }
    }

    func imageName(isSelected: Bool) -> String {
        let suffix = isSelected ? "_on" : "_off"
        switch self {
        case .server: return "server" + suffix
        case .singleBoard: return "singleBoard" + suffix
        case .cube: return "cube" + suffix
        case .tower: return "tower" + suffix
        case .vm: return "vm" + suffix
        case .laptop: return "laptop" + suffix
        }
    }
}

enum OnboardingStep: Int, CaseIterable {
    case machineType = 0
    case naming = 1
    case configuration = 2
    case confirmation = 3
    
    var title: String {
        switch self {
        case .machineType: return "MACHINE TYPE"
        case .naming: return "MACHINE NAME"
        case .configuration: return "CONNECTION DETAILS"
        case .confirmation: return "CONFIRMATION"
        }
    }
}

enum ConnectionStatus {
    case idle
    case connecting
    case success
    case failed
}

struct MachineOnboardingModal: View {
    var onDismiss: () -> Void
    var onComplete: (ServerModuleItem, MachineType) -> Void
    
    @State private var currentStep: OnboardingStep = .machineType
    @State private var selectedMachineType: MachineType?
    @State private var name = ""
    @State private var ip = ""
    @State private var port = ""
    @State private var apiKey = ""
    @State private var connectionStatus: ConnectionStatus = .idle
    @State private var connectionMessage = ""
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Progress Indicator
                progressIndicator
                
                // Content
                contentView
                
                // Navigation
                navigationView
            }
            .frame(maxWidth: 600, maxHeight: 700)
            .background(Color.black)
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Text(currentStep.title)
                .foregroundColor(.white)
                .font(.system(size: 18))
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
                    .font(.system(size: 14))
            }
        }
        .padding(20)
    }
    
    // MARK: - Progress Indicator
    private var progressIndicator: some View {
        HStack(spacing: 0) {
            // Left Arrow
            Button(action: {
                if currentStep.rawValue > 0 {
                    previousStep()
                }
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(currentStep.rawValue > 0 ? .white : .gray.opacity(0.3))
                    .font(.system(size: 16))
            }
            .disabled(currentStep.rawValue == 0)
            .frame(width: 40)
            
            // Progress Line with Sections and Indicators
            HStack(spacing: 0) {
                ForEach(0..<OnboardingStep.allCases.count, id: \.self) { index in
                    // Step indicator (vertical rectangle)
                    Rectangle()
                        .fill(currentStep.rawValue == index ? Color.white : Color.gray.opacity(0.3))
                        .frame(width: currentStep.rawValue == index ? 8 : 1, height: 8)
                    
                    // Line segment (only add if not the last step)
                    if index < OnboardingStep.allCases.count - 1 {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            
            // Right Arrow
            Button(action: {
                if canProceed && currentStep != .confirmation {
                    nextStep()
                }
            }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(canProceed && currentStep != .confirmation ? .white : .gray.opacity(0.3))
                    .font(.system(size: 16))
            }
            .disabled(!canProceed || currentStep == .confirmation)
            .frame(width: 40)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
    }
    
    // MARK: - Content Views
    private var contentView: some View {
        Group {
            switch currentStep {
            case .machineType:
                machineTypeView
            case .naming:
                namingView
            case .configuration:
                configurationView
            case .confirmation:
                confirmationView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
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
    
    // Step 3: Configuration and Connection
    private var configurationView: some View {
        VStack(spacing: 32) {
            Spacer()
            
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
            
                HStack {
                    Image(systemName: "exclamationmark")
                        .foregroundColor(.white)
                    Text("connection only possible if the software is correctly setup on desktop")
                        .foregroundColor(.gray).font(.system(size: 10))
                    RegularButton(Label: connectionButtonText, action: {
                        testConnection()
                    }, color: "Blue").frame(maxWidth: 110)
                }.padding(.horizontal, 15)
            
            Spacer()
        }
    }
    
    // Step 4: Confirmation
    private var confirmationView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16))
                        .foregroundColor(Color("Green"))
                    
                    Text("SUCCESS!")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .medium))
                }
                Text("\(name.isEmpty ? "Machine" : name) is now connected and ready to monitor")
                    .foregroundColor(.gray)
                    .font(.system(size: 12))
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                machineDetailRow("Type", selectedMachineType?.rawValue ?? "Unknown")
                machineDetailRow("Name", name.isEmpty ? "My \(selectedMachineType?.rawValue ?? "Machine")" : name)
                machineDetailRow("Address", "\(ip.isEmpty ? "192.168.1.100" : ip):\(port)")
                machineDetailRow("Status", connectionStatus == .success ? "Connected" : "Configured")
            }
            .padding(16)
            .background(Color(red: 15/255, green: 15/255, blue: 15/255))
            .overlay(RoundedRectangle(cornerRadius: 0)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1))
            
            Spacer()
        }
    }
    
    private func machineDetailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label.uppercased())
                .foregroundColor(.gray)
                .font(.system(size: 12))
                .frame(width: 60, alignment: .leading)
            
            Text(value)
                .foregroundColor(.white)
                .font(.system(size: 12))
            
            Spacer()
        }
    }
    
    // MARK: - Navigation
    private var navigationView: some View {
        HStack {
            Spacer()
            
            if currentStep == .confirmation {
                RegularButton(Label: "FINISH", action: completeOnboarding, color: "Blue")
                    .frame(maxWidth: 100)
            }
        }
        .padding(20)
    }
    
    // MARK: - Computed Properties
    private var nextButtonLabel: String {
        switch currentStep {
        case .machineType: return "NEXT"
        case .naming: return "NEXT"
        case .configuration: return "FINISH"
        case .confirmation: return "FINISH"
        }
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case .machineType:
            return selectedMachineType != nil
        case .naming:
            return true // Name can be empty, will use default
        case .configuration:
            return !ip.isEmpty && !port.isEmpty && !apiKey.isEmpty && connectionStatus == .success
        case .confirmation:
            return true
        }
    }
    
    private var connectionButtonText: String {
        switch connectionStatus {
        case .idle: return "TEST CONNECT"
        case .connecting: return "CONNECTING..."
        case .success: return "SUCCESS"
        case .failed: return "TRY AGAIN"
        }
    }
    
    private var connectionButtonColor: Color {
        switch connectionStatus {
        case .success: return .green.opacity(0.2)
        case .failed: return .red.opacity(0.2)
        default: return Color.blue.opacity(0.2)
        }
    }
    
    // MARK: - Actions
    private func previousStep() {
        if currentStep.rawValue > 0 {
            currentStep = OnboardingStep(rawValue: currentStep.rawValue - 1) ?? .machineType
        }
    }
    
    private func nextStep() {
        switch currentStep {
        case .machineType:
            if selectedMachineType != nil {
                currentStep = .naming
            }
        case .naming:
            currentStep = .configuration
        case .configuration:
            currentStep = .confirmation
        case .confirmation:
            completeOnboarding()
        }
    }
    
    private func testConnection() {
        connectionStatus = .connecting
        connectionMessage = ""

        // Use actual NetworkService to test connection
        let networkService = NetworkService(ip: ip, port: port, apiKey: apiKey)
        networkService.checkHealth { isHealthy in
            DispatchQueue.main.async {
                if isHealthy {
                    self.connectionStatus = .success
                    self.connectionMessage = "Successfully connected to \(self.name.isEmpty ? "machine" : self.name)"
                } else {
                    self.connectionStatus = .failed
                    self.connectionMessage = "Could not establish connection. Check network settings."
                }
            }
        }
    }
    
    private func completeOnboarding() {
        guard let machineType = selectedMachineType else { return }

        let newServer = ServerModuleItem(
            name: name.isEmpty ? "My \(machineType.rawValue)" : name,
            ip: ip.isEmpty ? "192.168.1.100" : ip,
            port: port.isEmpty ? "42000" : port,
            apiKey: apiKey,
            type: machineType.rawValue
        )

        onComplete(newServer, machineType)
    }
}

#Preview {
    MachineOnboardingModal(
        onDismiss: {},
        onComplete: { _, _ in }
    )
}
