//
//  SettingsView.swift
//  TaskLuid
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            VStack(spacing: LLSpacing.md) {
                if let user = authViewModel.user {
                    LLCard(style: .standard) {
                        VStack(alignment: .leading, spacing: LLSpacing.xs) {
                            Text(user.username)
                                .h4()
                            Text(user.email ?? "No email")
                                .bodySmall()
                                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                        }
                    }
                }

                LLButton("Logout", style: .destructive, fullWidth: true) {
                    Task { await authViewModel.logout() }
                }

                Spacer()
            }
            .screenPadding()
            .background(LLColors.background.color(for: colorScheme))
            .navigationTitle("Settings")
        }
    }
}
