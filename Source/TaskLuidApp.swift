//
//  TaskLuidApp.swift
//  TaskLuid
//

import SwiftUI

@main
struct TaskLuidApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
        }
    }
}
