//
//  TabBarView.swift
//  TaskLuid
//

import SwiftUI

struct TabBarView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var tasksViewModel = TasksViewModel()
    @StateObject private var usersViewModel = UsersViewModel()
    @StateObject private var projectsViewModel = ProjectsViewModel()

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            ProjectsListView(viewModel: projectsViewModel)
                .tabItem {
                    Label("Projects", systemImage: "folder")
                }

            TasksListView(viewModel: tasksViewModel, usersViewModel: usersViewModel)
                .tabItem {
                    Label("Tasks", systemImage: "checklist")
                }

            TeamsView()
                .tabItem {
                    Label("Teams", systemImage: "person.3")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .tint(LLColors.primary.color(for: colorScheme))
    }
}
