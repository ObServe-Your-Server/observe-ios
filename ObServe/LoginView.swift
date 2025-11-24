//
//  LoginView.swift
//  ObServe
//
//  Created by Daniel Schatz on 19.11.25.
//

import SwiftUI

struct LoginView : View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var username_or_email: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var rememberMe: Bool = false
    @State private var isPasswordVisible: Bool = false
    @State private var signUpPageOpen: Bool = false
    @State private var forgotPasswordPageOpen: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 80)
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image("AppIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ObServe")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                        Text("MONITOR YOUR MACHINES")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 30)
            Spacer().frame(height: 40)
            VStack(alignment: .leading, spacing: 30) {
                Spacer().frame(height: 0)
                if !forgotPasswordPageOpen {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(usernameLabel())
                            .foregroundColor(.gray)
                            .font(.system(size: 11, weight: .medium))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        TextField("", text: $username_or_email)
                            .textFieldStyle(PlainTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(Color.black)
                            .foregroundColor(.white)
                            .font(.system(size: 13))
                            .overlay(
                                RoundedRectangle(cornerRadius: 0)
                                    .stroke(Color(red: 65/255, green: 65/255, blue: 65/255), lineWidth: 1)
                            )
                    }
                }
                
                if signUpPageOpen || forgotPasswordPageOpen {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("EMAIL")
                            .foregroundColor(.gray)
                            .font(.system(size: 11, weight: .medium))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        TextField("", text: $email)
                            .textFieldStyle(PlainTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(Color.black)
                            .foregroundColor(.white)
                            .font(.system(size: 13))
                            .overlay(
                                RoundedRectangle(cornerRadius: 0)
                                    .stroke(Color(red: 65/255, green: 65/255, blue: 65/255), lineWidth: 1)
                            )
                    }
                }
                
                if !forgotPasswordPageOpen {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("PASSWORD")
                            .foregroundColor(.gray)
                            .font(.system(size: 11, weight: .medium))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack {
                            if isPasswordVisible {
                                TextField("", text: $password)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .foregroundColor(.white)
                                    .font(.system(size: 13))
                            } else {
                                SecureField("", text: $password)
                                    .foregroundColor(.white)
                                    .font(.system(size: 13))
                            }
                            
                            Button(action: {
                                isPasswordVisible.toggle()
                            }) {
                                // custom später später
                                Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                                    .foregroundColor(.gray)
                                    .frame(width: 20, height: 20)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color.black)
                        .overlay(
                            RoundedRectangle(cornerRadius: 0)
                                .stroke(Color(red: 65/255, green: 65/255, blue: 65/255), lineWidth: 1)
                        )
                        
                        Button(action: {
                            signUpPageOpen = false
                            forgotPasswordPageOpen = true
                        }) {
                            Text("FORGOT PASSWORD?")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .underline(color: .gray)
                        }
                        .padding(.top, 2)
                    }
                    
                    
                    HStack() {
                        Text("REMEMBER ME")
                            .foregroundColor(.gray)
                            .font(.system(size: 11, weight: .medium))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Spacer()
                        Button(action: {
                            rememberMe.toggle()
                        }) {
                            if rememberMe {
                                HStack {
                                    RoundedRectangle(cornerRadius: 0)
                                        .fill(Color(red: 65/255, green: 65/255, blue: 65/255))
                                }
                                .frame(width: 14, height: 14)
                                .frame(width: 20, height: 20)
                                .overlay(RoundedRectangle(cornerRadius: 0).stroke(Color(red: 65/255, green: 65/255, blue: 65/255), lineWidth: 1))
                            } else {
                                RoundedRectangle(cornerRadius: 0)
                                    .stroke(Color(red: 65/255, green: 65/255, blue: 65/255), lineWidth: 1)
                                    .frame(width: 20, height: 20)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.trailing, 12)
                    .padding(.top, 4)
                }
                HStack(spacing: 12) {
                    RegularButton(Label: "LOGIN", action: {
                        if signUpPageOpen {
                            signUpPageOpen = false
                        } else if forgotPasswordPageOpen {
                            forgotPasswordPageOpen = false
                        } else {
                            authManager.login(username_or_email: username_or_email, password: password, rememberMe: rememberMe)
                        }
                    }, color: "ObServeBlue")
                    RegularButton(Label: "SIGN UP", action: {
                        if !signUpPageOpen {
                            signUpPageOpen = true
                        } else if forgotPasswordPageOpen{
                            forgotPasswordPageOpen = false
                        }
                            else {
                            authManager.register(username: username_or_email, email: email, password: password, rememberMe: rememberMe)
                        }
                        
                    }, color: "ObServeGray")
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .background(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
            )
            .overlay(alignment: .topLeading) {
                HStack {
                    Text("ACCOUNT")
                        .foregroundColor(.white)
                        .font(.system(size: 11, weight: .medium))
                }
                .padding(10)
                .background(Color.black)
                .padding(.top, -20)
                .padding(.leading, 10)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)

            Spacer()
            
        }
    }
    
    private func usernameLabel() -> String {
        if signUpPageOpen {
            return "USERNAME"
        } else {
            return "USERNAME/MAIL"
        }
    }
    
                
}

#Preview {
    LoginView()
        .padding()
        .background(Color.black)
}
