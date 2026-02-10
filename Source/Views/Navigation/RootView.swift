//
//  RootView.swift
//  TaskLuid
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            if authViewModel.isAuthenticated {
                TabBarView()
            } else {
                AuthenticationView()
            }
        }
        .background(LLColors.background.color(for: colorScheme))
    }
}
