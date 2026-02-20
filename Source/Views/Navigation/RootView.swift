//
//  RootView.swift
//  TaskLuid
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel

    var body: some View {
        ZStack {
            if authViewModel.isAuthenticated {
                DrawerShellView()
            } else {
                AuthenticationView()
            }
        }
        .appBackground()
    }
}
