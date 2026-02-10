//
//  TabBarView.swift
//  TaskLuid
//

import SwiftUI

struct TabBarView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            ProjectsListView()
                .tabItem {
                    Label("Projects", systemImage: "folder")
                }

            TasksListView()
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
