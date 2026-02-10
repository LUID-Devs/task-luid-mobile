//
//  ChallengeView.swift
//  TaskLuid
//

import SwiftUI

struct ChallengeView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var code = ""
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            let content = VStack(spacing: LLSpacing.md) {
                Text("Verification Required")
                    .h3()
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Enter the verification code to continue.")
                    .bodySmall()
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                    .frame(maxWidth: .infinity, alignment: .leading)

                LLTextField(title: "Code", placeholder: "123456", text: $code)

                if let error = authViewModel.errorMessage {
                    InlineErrorView(message: error)
                }

                LLButton("Submit", style: .primary, isLoading: authViewModel.isLoading, fullWidth: true) {
                    Task {
                        await authViewModel.respondToChallenge(code: code)
                        if authViewModel.challenge == nil {
                            dismiss()
                        }
                    }
                }

                LLButton("Cancel", style: .ghost, fullWidth: true) {
                    authViewModel.challenge = nil
                    dismiss()
                }
            }
            .screenPadding()
            #if os(iOS)
            content.navigationBarTitleDisplayMode(.inline)
            #else
            content
            #endif
        }
    }
}
