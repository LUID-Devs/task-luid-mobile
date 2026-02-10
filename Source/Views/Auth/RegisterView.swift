//
//  RegisterView.swift
//  TaskLuid
//

import SwiftUI

struct RegisterView: View {
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var showConfirm = false
    @State private var confirmUsername = ""

    @EnvironmentObject private var authViewModel: AuthViewModel

    var body: some View {
        VStack(spacing: LLSpacing.md) {
            LLTextField(title: "Username", placeholder: "Choose a username", text: $username)
            LLTextField(title: "Email", placeholder: "you@example.com", text: $email)
            LLTextField(title: "Password", placeholder: "Create a password", text: $password, isSecure: true)

            if let error = authViewModel.errorMessage {
                InlineErrorView(message: error)
            }

            LLButton("Create Account", style: .primary, isLoading: authViewModel.isLoading, fullWidth: true) {
                Task {
                    if let response = await authViewModel.register(username: username, email: email, password: password),
                       response.needsConfirmation == true {
                        confirmUsername = username
                        showConfirm = true
                    }
                }
            }
        }
        .navigationDestination(isPresented: $showConfirm) {
            ConfirmSignUpView(username: confirmUsername)
        }
    }
}
