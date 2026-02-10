//
//  AuthenticationView.swift
//  TaskLuid
//

import SwiftUI

enum AuthMode: String, CaseIterable {
    case login = "Login"
    case register = "Register"
}

struct AuthenticationView: View {
    @State private var mode: AuthMode = .login
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            let content = VStack(spacing: LLSpacing.lg) {
                VStack(alignment: .leading, spacing: LLSpacing.sm) {
                    Text("TaskLuid")
                        .h1()
                    Text("Your projects, tasks, and teams in one place.")
                        .bodySmall()
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Picker("Mode", selection: $mode) {
                    ForEach(AuthMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.vertical, LLSpacing.sm)

                if mode == .login {
                    LoginView()
                } else {
                    RegisterView()
                }

                Spacer()
            }
            .screenPadding()
            .sheet(item: $authViewModel.challenge) { _ in
                ChallengeView()
            }
            #if os(iOS)
            content.navigationBarHidden(true)
            #else
            content
            #endif
        }
    }
}
