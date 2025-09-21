//
//  MachineOnboardingModal.swift
//  ObServe
//
//  Created by Daniel Schatz on 19.07.25.
//

import SwiftUI

enum MachineType: String, CaseIterable {
    case server = "Server"
    case singleBoard = "Single Board"
    case cube = "Cube"
    case tower = "Tower"
    case vm = "VM"
    case laptop = "Laptop"
    
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
}

enum OnboardingStep: Int, CaseIterable {
    case machineType = 0
    case configuration = 1
    case confirmation = 2
    
    var title: String {
        switch self {
        case .machineType: return "MACHINE TYPE"
        case .configuration: return "CONFIGURATION"
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
    @State private var port = "42000"
    @State private var connectionStatus: ConnectionStatus = .idle
    @State private var connectionMessage = ""
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
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
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.white, lineWidth: 1)
            )
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Text("ADD NEW MACHINE")
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .bold))
            
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
            Text("What type of machine are you adding?")
                .foregroundColor(.gray)
                .font(.system(size: 14))
            
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
            VStack(spacing: 12) {
                Image(systemName: type.icon)
                    .font(.system(size: 32))
                    .foregroundColor(selectedMachineType == type ? .blue : .white)
                
                Text(type.rawValue)
                    .font(.system(size: 12))
                    .foregroundColor(selectedMachineType == type ? .blue : .gray)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(minHeight: 120)
            .background(
                selectedMachineType == type ?
                Color.blue.opacity(0.1) :
                Color(red: 15/255, green: 15/255, blue: 15/255)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(selectedMachineType == type ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Step 2: Configuration and Connection
    private var configurationView: some View {
        VStack(alignment: .leading, spacing: 25) {
            HStack {
                Spacer()
                Text("Configure your \(selectedMachineType?.rawValue.lowercased() ?? "machine")")
                    .foregroundColor(.gray)
                    .font(.system(size: 14))
                Spacer()
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("MACHINE NAME")
                    .foregroundColor(.gray)
                    .font(.system(size: 9))
                
                TextField("My \(selectedMachineType?.rawValue ?? "Machine")", text: $name)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(12)
                    .background(Color(red: 15/255, green: 15/255, blue: 15/255))
                    .foregroundColor(.white)
                    .overlay(RoundedRectangle(cornerRadius: 0)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1))
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("IP ADDRESS")
                        .foregroundColor(.gray)
                        .font(.system(size: 9))
                    
                    TextField("192.168.1.100", text: $ip)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(12)
                        .background(Color(red: 15/255, green: 15/255, blue: 15/255))
                        .foregroundColor(.white)
                        .overlay(RoundedRectangle(cornerRadius: 0)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("PORT")
                        .foregroundColor(.gray)
                        .font(.system(size: 9))
                    
                    TextField("42000", text: $port)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(12)
                        .background(Color(red: 15/255, green: 15/255, blue: 15/255))
                        .foregroundColor(.white)
                        .overlay(RoundedRectangle(cornerRadius: 0)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1))
                }
                .frame(maxWidth: 120)
            }
            
            // Connection Testing Section
            VStack(spacing: 16) {
                Button(action: testConnection) {
                    HStack {
                        if connectionStatus == .connecting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: connectionStatus == .success ? "checkmark" : "wifi")
                                .foregroundColor(.white)
                        }
                        
                        Text(connectionButtonText)
                            .foregroundColor(.white)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(connectionButtonColor)
                    .overlay(RoundedRectangle(cornerRadius: 0)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1))
                }
                .disabled(connectionStatus == .connecting || ip.isEmpty || port.isEmpty)
                
                if !connectionMessage.isEmpty {
                    HStack {
                        Image(systemName: connectionStatus == .success ? "checkmark.circle" : "exclamationmark.triangle")
                            .foregroundColor(connectionStatus == .success ? .green : .orange)
                        
                        Text(connectionMessage)
                            .foregroundColor(connectionStatus == .success ? .green : .orange)
                            .font(.system(size: 10))
                        
                        Spacer()
                    }
                }
            }
            
            if connectionStatus != .success {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("Connection Requirements")
                            .foregroundColor(.blue)
                            .font(.system(size: 10, weight: .medium))
                        Spacer()
                    }
                    
                    Text("• ObServe desktop software must be installed and running")
                        .foregroundColor(.gray)
                        .font(.system(size: 9))
                }
                .padding(12)
                .background(Color.blue.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1))
            }
            
            Spacer()
        }
    }
    

    
    // Step 3: Confirmation
    private var confirmationView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.green)
                
                Text("Machine Added Successfully!")
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .medium))
                
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
                .font(.system(size: 9))
                .frame(width: 60, alignment: .leading)
            
            Text(value)
                .foregroundColor(.white)
                .font(.system(size: 10))
            
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
        case .configuration: return "FINISH"
        case .confirmation: return "FINISH"
        }
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case .machineType:
            return selectedMachineType != nil
        case .configuration:
            return !ip.isEmpty && !port.isEmpty
        case .confirmation:
            return true
        }
    }
    
    private var connectionButtonText: String {
        switch connectionStatus {
        case .idle: return "TEST CONNECTION"
        case .connecting: return "CONNECTING..."
        case .success: return "CONNECTION SUCCESSFUL"
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
                currentStep = .configuration
            }
        case .configuration:
            currentStep = .confirmation
        case .confirmation:
            completeOnboarding()
        }
    }
    
    private func testConnection() {
        connectionStatus = .connecting
        connectionMessage = ""
        
        // Simulate connection test
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // This would be replaced with actual connection logic
            let success = Bool.random() // Simulate random success/failure for demo
            
            if success {
                connectionStatus = .success
                connectionMessage = "Successfully connected to \(name.isEmpty ? "machine" : name)"
            } else {
                connectionStatus = .failed
                connectionMessage = "Could not establish connection. Check network settings."
            }
        }
    }
    
    private func completeOnboarding() {
        guard let machineType = selectedMachineType else { return }
        
        let newServer = ServerModuleItem(
            name: name.isEmpty ? "My \(machineType.rawValue)" : name,
            ip: ip.isEmpty ? "192.168.1.100" : ip,
            port: port.isEmpty ? "42000" : port
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
