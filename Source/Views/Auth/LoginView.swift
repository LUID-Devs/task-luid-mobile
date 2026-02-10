//
//  LoginView.swift
//  TaskLuid
//

import SwiftUI

struct LoginView: View {
    @State private var username = ""
    @State private var password = ""
    @EnvironmentObject private var authViewModel: AuthViewModel

    var body: some View {
        VStack(spacing: LLSpacing.md) {
            LLTextField(title: "Username", placeholder: "Enter your username", text: $username)
            LLTextField(title: "Password", placeholder: "Enter your password", text: $password, isSecure: true)

            if let error = authViewModel.errorMessage {
                InlineErrorView(message: error)
            }

            LLButton("Login", style: .primary, isLoading: authViewModel.isLoading, fullWidth: true) {
                Task { await authViewModel.login(username: username, password: password) }
            }
        }
    }
}
