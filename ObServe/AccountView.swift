//
//  AccountView.swift
//  ObServe
//
//  Created by Daniel Schatz on 21.11.25.
//

import SwiftUI

struct AccountView: View {
    @State private var contentHasScrolled = false
    @State private var showBurgerMenu = false
    @Environment(\.dismiss) private var dismiss
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var lastLoginInfo: String = ""
    @State private var show2FASettings: Bool = false
    @State private var showSessionManagement: Bool = false
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?
    @State private var showError: Bool = false
    @State private var showDeleteConfirmation: Bool = false
    @State private var deletePassword: String = ""
    @State private var showChangeInfoSheet: Bool = false

    @EnvironmentObject private var authManager: AuthenticationManager

    @Binding var serverRoute: ServerRoute?
    @Binding var alertsRoute: AlertsRoute?
    @Binding var settingsRoute: SettingsRoute?
    
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                AccountAppBar(
                    contentHasScrolled: $contentHasScrolled,
                    showBurgerMenu: $showBurgerMenu,
                    usernameText: "\(username.uppercased())",
                )
                
                ScrollView {
                    scrollDetection
                    
                    VStack(spacing: 35) {
                        VStack(alignment: .leading, spacing: 20) {
                            sectionHeader("INFORMATION")
                            
                            HStack(spacing: 10) {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("USERNAME")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 12, weight: .medium))
                                        .frame(width: 100, alignment: .leading)
                                    
                                    TextField("USER", text: $username)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .frame(width: 120)
                                        .background(Color.black)
                                        .foregroundColor(.white)
                                        .font(.system(size: 16))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 0)
                                                .stroke(Color(red: 65/255, green: 65/255, blue: 65/255), lineWidth: 1)
                                        )
                                        .disabled(true)
                                }
                                
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("EMAIL")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 12, weight: .medium))
                                        .frame(width: 100, alignment: .leading)
                                    
                                    TextField("", text: $email)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.black)
                                        .foregroundColor(.white)
                                        .font(.system(size: 16))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 0)
                                                .stroke(Color(red: 65/255, green: 65/255, blue: 65/255), lineWidth: 1)
                                        )
                                    
                                        .disabled(true)
                                }
                            }
                            ButtonWhiteAccount(Label: "CHANGE INFORMATION", action: {
                                showChangeInfoSheet = true
                            }, color: "ObServeGray")
                        }
                        VStack(alignment: .leading, spacing: 20) {
                            sectionHeader("SECURITY")
                            VStack(alignment: .leading, spacing: 20) {
                                HStack {
                                    Button (action: {
                                        show2FASettings.toggle()
                                    }) {
                                        HStack {
                                            Text("2FA")
                                                .foregroundColor(.white)
                                                .font(.system(size: 16, weight: .medium))
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 16))
                                                .foregroundColor(.gray)
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 0)
                                                .stroke(Color(red: 65/255, green: 65/255, blue: 65/255), lineWidth: 1)
                                        )
                                    }
                                    Button (action: {
                                        showSessionManagement.toggle()
                                    }) {
                                        HStack {
                                            Text("SESSIONS")
                                                .foregroundColor(.white)
                                                .font(.system(size: 16, weight: .medium))
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 16))
                                                .foregroundColor(.gray)
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 0)
                                                .stroke(Color(red: 65/255, green: 65/255, blue: 65/255), lineWidth: 1)
                                        )
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("LAST LOGIN INFORMATION")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 12, weight: .medium))
                                        .frame(width: 200, alignment: .leading)
                                    
                                    TextField("", text: $lastLoginInfo)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.black)
                                        .foregroundColor(.white)
                                        .font(.system(size: 16))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 0)
                                                .stroke(Color(red: 65/255, green: 65/255, blue: 65/255), lineWidth: 1)
                                        )
                                        .disabled(true)
                                }
                                

                                
                            }

                        }
                        VStack(alignment: .leading, spacing: 20) {
                            sectionHeader("MANAGE")
                            RegularButtonAccount(Label: "DELETE ACCOUNT", action: {
                                showDeleteConfirmation = true
                            }, color: "ObServeRed")
                            RegularButtonAccount(Label: "LOGOUT", action: {authManager.logout()}, color: "ObServeBlue")
                                

                        }
                        
                    }
                        
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 10)
                .background(Color.black)
                .overlay(alignment: .bottom) {
                    if contentHasScrolled {
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 1)
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.2), value: contentHasScrolled)
                    }
                }
            }
            .background(Color.black.ignoresSafeArea())
            .offset(x: showBurgerMenu ? -240 : 0)
            .animation(.spring(response: 0.28, dampingFraction: 0.9), value: showBurgerMenu)

            if showBurgerMenu {
                BurgerMenu(
                    onDismiss: { showBurgerMenu = false },
                    onDashboard: { dismiss() },
                    onServer: {
                        showBurgerMenu = false
                        serverRoute = .init()
                    },
                    onAlerts: {
                        showBurgerMenu = false
                        alertsRoute = .init()
                    },
                    onAccount: { showBurgerMenu = false },
                    onSettings: {
                        showBurgerMenu = false
                        settingsRoute = .init()
                    },
                    onLogout: {
                        showBurgerMenu = false
                        authManager.logout()
                    },
                    selectedSection: .account
                )
            }
        }
        .onAppear {
            fetchCurrentUser()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
        .alert("Delete Account", isPresented: $showDeleteConfirmation) {
            SecureField("Enter your password", text: $deletePassword)
            Button("Delete", role: .destructive) {
                handleDeleteAccount()
            }
            Button("Cancel", role: .cancel) {
                deletePassword = ""
            }
        } message: {
            Text("This action cannot be undone. Please enter your password to confirm.")
        }
        .sheet(isPresented: $showChangeInfoSheet) {
            ChangeInfoSheet(
                username: username,
                email: email,
                onSave: { newUsername, newEmail, newPassword, currentPassword in
                    handleUpdateUser(username: newUsername, email: newEmail, password: newPassword, currentPassword: currentPassword)
                }
            )
        }
    }

    // MARK: - Helper Functions

    private func fetchCurrentUser() {
        isLoading = true
        authManager.getCurrentUser { result in
            isLoading = false
            switch result {
            case .success(let user):
                username = user.username
                email = user.email
                lastLoginInfo = formatDate(user.updated_at)
            case .failure(let error):
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func formatDate(_ isoString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let date = isoFormatter.date(from: isoString) else {
            return isoString
        }

        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .short

        return displayFormatter.string(from: date)
    }

    private func handleUpdateUser(username: String?, email: String?, password: String?, currentPassword: String?) {
        let usernameChanged = username != nil && username != self.username
        let emailChanged = email != nil && email != self.email
        let passwordChanged = password != nil && !password!.isEmpty

        let updateRequest = UpdateUserRequest(
            username: usernameChanged ? username : nil,
            email: emailChanged ? email : nil,
            password: passwordChanged ? password : nil,
            currentPassword: passwordChanged ? currentPassword : nil
        )

        authManager.updateCurrentUser(updateRequest: updateRequest) { result in
            switch result {
            case .success(let response):
                self.username = response.user.username
                self.email = response.user.email
                showChangeInfoSheet = false
            case .failure(let error):
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func handleDeleteAccount() {
        guard !deletePassword.isEmpty else {
            errorMessage = "Password is required"
            showError = true
            return
        }

        authManager.deleteCurrentUser(password: deletePassword) { result in
            deletePassword = ""
            switch result {
            case .success(let message):
                print(message)
            case .failure(let error):
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    // MARK: - Scroll Detection (steuert die Linie in der AppBar)
    private var scrollDetection: some View {
        GeometryReader { proxy in
            let offset = proxy.frame(in: .named("scroll")).minY
            Color.clear.preference(key: AccountScrollPreferenceKey.self, value: offset)
        }
        .frame(height: 0)
        .onPreferenceChange(AccountScrollPreferenceKey.self) { value in
            withAnimation(.easeInOut(duration: 0.12)) {
                contentHasScrolled = value < -0.5
            }
        }
    }
    
    // MARK: - Helper Views
    @ViewBuilder
    private func sectionHeader(_ text: String) -> some View {
        HStack {
            Text(text)
                .foregroundColor(.white)
            Rectangle()
                .fill(Color.white.opacity(0.25))
                .frame(height: 1)
        }
    }
}

private struct AccountScrollPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

// MARK: - Change Info Sheet
struct ChangeInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var newUsername: String
    @State private var newEmail: String
    @State private var newPassword: String = ""
    @State private var currentPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var showPasswordMismatchError: Bool = false

    var onSave: (String?, String?, String?, String?) -> Void

    init(username: String, email: String, onSave: @escaping (String?, String?, String?, String?) -> Void) {
        _newUsername = State(initialValue: username)
        _newEmail = State(initialValue: email)
        self.onSave = onSave
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("USERNAME")
                                .foregroundColor(.gray)
                                .font(.system(size: 12, weight: .medium))

                            TextField("", text: $newUsername)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(Color.black)
                                .foregroundColor(.white)
                                .font(.system(size: 16))
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 0)
                                        .stroke(Color(red: 65/255, green: 65/255, blue: 65/255), lineWidth: 1)
                                )
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("EMAIL")
                                .foregroundColor(.gray)
                                .font(.system(size: 12, weight: .medium))

                            TextField("", text: $newEmail)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(Color.black)
                                .foregroundColor(.white)
                                .font(.system(size: 16))
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 0)
                                        .stroke(Color(red: 65/255, green: 65/255, blue: 65/255), lineWidth: 1)
                                )
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("NEW PASSWORD (LEAVE BLANK TO KEEP CURRENT)")
                                .foregroundColor(.gray)
                                .font(.system(size: 12, weight: .medium))

                            SecureField("", text: $newPassword)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(Color.black)
                                .foregroundColor(.white)
                                .font(.system(size: 16))
                                .textInputAutocapitalization(.never)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 0)
                                        .stroke(Color(red: 65/255, green: 65/255, blue: 65/255), lineWidth: 1)
                                )
                        }

                        if !newPassword.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("CONFIRM NEW PASSWORD")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 12, weight: .medium))

                                SecureField("", text: $confirmPassword)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(Color.black)
                                    .foregroundColor(.white)
                                    .font(.system(size: 16))
                                    .textInputAutocapitalization(.never)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 0)
                                            .stroke(showPasswordMismatchError ? Color.red : Color(red: 65/255, green: 65/255, blue: 65/255), lineWidth: 1)
                                    )

                                if showPasswordMismatchError {
                                    Text("Passwords do not match")
                                        .foregroundColor(.red)
                                        .font(.system(size: 11))
                                }
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("CURRENT PASSWORD (REQUIRED)")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 12, weight: .medium))

                                SecureField("", text: $currentPassword)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(Color.black)
                                    .foregroundColor(.white)
                                    .font(.system(size: 16))
                                    .textInputAutocapitalization(.never)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 0)
                                            .stroke(Color(red: 65/255, green: 65/255, blue: 65/255), lineWidth: 1)
                                    )
                            }
                        }

                        HStack(spacing: 12) {
                            ButtonWhiteAccount(Label: "CANCEL", action: {
                                dismiss()
                            }, color: "ObServeGray")

                            ButtonWhiteAccount(Label: "SAVE", action: {
                                handleSave()
                            }, color: "ObServeBlue")
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                .background(Color.black)
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Change Information")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func handleSave() {
        // Validate password match if changing password
        if !newPassword.isEmpty {
            if newPassword != confirmPassword {
                showPasswordMismatchError = true
                return
            }

            if currentPassword.isEmpty {
                return
            }
        }

        // Determine what changed
        let usernameChanged = !newUsername.isEmpty
        let emailChanged = !newEmail.isEmpty
        let passwordChanged = !newPassword.isEmpty

        onSave(
            usernameChanged ? newUsername : nil,
            emailChanged ? newEmail : nil,
            passwordChanged ? newPassword : nil,
            passwordChanged ? currentPassword : nil
        )
    }
}

