//
//  ConfirmSignUpView.swift
//  TaskLuid
//

import SwiftUI

struct ConfirmSignUpView: View {
    let username: String
    @State private var code = ""
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: LLSpacing.md) {
            Text("Confirm your email")
                .h3()
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Enter the verification code sent to your email.")
                .bodySmall()
                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                .frame(maxWidth: .infinity, alignment: .leading)

            LLTextField(title: "Code", placeholder: "123456", text: $code)

            if let error = authViewModel.errorMessage {
                InlineErrorView(message: error)
            }

            LLButton("Verify", style: .primary, isLoading: authViewModel.isLoading, fullWidth: true) {
                Task {
                    if await authViewModel.confirmSignUp(username: username, code: code) {
                        dismiss()
                    }
                }
            }
        }
        .screenPadding()
    }
}
