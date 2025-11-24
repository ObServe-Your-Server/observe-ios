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
        case .confirmation: return "YOUR SETUP"
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
    @State private var contentHasScrolled = false
    @State private var dummyInterval: DetailAppBar.Interval = .s1
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                DetailAppBar(
                    serverName: currentStep.title,
                    contentHasScrolled: $contentHasScrolled,
                    selectedInterval: $dummyInterval,
                    showIntervalSelector: false,
                    showProgressIndicator: true,
                    currentStep: currentStep.rawValue,
                    totalSteps: OnboardingStep.allCases.count,
                    onClose: onDismiss
                )
                
                // Content
                contentView
                
                // Navigation
                navigationView
            }
            .frame(maxWidth: 600, maxHeight: 700)
            .background(Color.black)
        }
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
        VStack(alignment: .center, spacing: 32) {
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
            
            VStack(alignment: .leading, spacing: 32) {
                    HStack {
                        Image(systemName: "exclamationmark")
                            .foregroundColor(.white)
                        Text("connection only possible if the software is correctly setup on desktop")
                            .foregroundColor(.gray).font(.system(size: 10))
                    }
                    RegularButton(Label: connectionButtonText, action: {
                        testConnection()
                    }, color: connectionStatus == .success ? "ObServeGreen" : (connectionStatus == .failed ? "ObServeRed" : "ObServeBlue"))
                }.padding(.horizontal, 15)
        }
        .padding(.vertical, 30)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
        )
    }
    
    // Step 4: Confirmation
    private var confirmationView: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 5)

            VStack(alignment: .leading, spacing: 16) {
                Spacer().frame(height: 5)

                // Server info and icon section
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 16) {
                        // Type label
                        infoLabel(label: "TYPE", value: selectedMachineType?.rawValue ?? "Unknown")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 16) {
                        // Name label
                        infoLabel(label: "NAME", value: name.isEmpty ? "My \(selectedMachineType?.rawValue ?? "Machine")" : name)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Server icon
                    VStack {
                        if let machineType = selectedMachineType {
                            Image(machineType.imageName(isSelected: true))
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 96, maxHeight: 96)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                RegularButton(Label: "CHANGE", action: {
                    currentStep = .machineType
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

            VStack(alignment: .center, spacing: 32) {
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
                
                VStack(alignment: .leading, spacing: 32) {
                        RegularButton(Label: connectionButtonText, action: {
                            testConnection()
                        }, color: connectionStatus == .success ? "ObServeGreen" : (connectionStatus == .failed ? "ObServeRed" : "ObServeBlue"))
                    }.padding(.horizontal, 15)
            }
            .padding(.vertical, 30)
            .background(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
            )
            .overlay(alignment: .topLeading) {
                HStack {
                    Text("CONNECTION")
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .medium))
                }
                .padding(10)
                .background(Color.black)
                .padding(.top, -20)
                .padding(.leading, 10)
            }

            Spacer()
        }
    }

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
        HStack(spacing: 16) {
            RegularButton(Label: "BACK", action: previousStep, color: "ObServeGray")
            RegularButton(Label: nextButtonLabel, action: nextStep, color: "ObServeBlue", disabled: !canProceed)
        }
        .padding(20)
    }
    
    // MARK: - Computed Properties
    private var nextButtonLabel: String {
        switch currentStep {
        case .machineType: return "NEXT"
        case .naming: return "NEXT"
        case .configuration: return "NEXT"
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
        case .idle: return "TEST CONNECTION"
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

        // If connection was successful, automatically mark as connected
        if connectionStatus == .success {
            newServer.isConnected = true
            newServer.isHealthy = true
            newServer.lastConnected = Date()
        }

        onComplete(newServer, machineType)
    }
}

#Preview {
    MachineOnboardingModal(
        onDismiss: {},
        onComplete: { _, _ in }
    )
}
