//
//  DrawerShellView.swift
//  TaskLuid
//

import SwiftUI

enum DrawerTab: String, CaseIterable, Identifiable {
    case dashboard
    case tasks
    case projects
    case teams

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .tasks: return "My Tasks"
        case .projects: return "Projects"
        case .teams: return "Teams"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: return "house"
        case .tasks: return "checklist"
        case .projects: return "folder"
        case .teams: return "person.3"
        }
    }
}

struct DrawerShellView: View {
    @State private var selection: DrawerTab = .dashboard
    @State private var isMenuOpen = false
    @State private var showSettings = false
    @State private var showMissionControl = false
    @State private var showPriority = false
    @State private var showTimeline = false
    @State private var showUsers = false
    @StateObject private var tasksViewModel = TasksViewModel()
    @StateObject private var usersViewModel = UsersViewModel()
    @StateObject private var projectsViewModel = ProjectsViewModel()
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ZStack(alignment: .leading) {
                TabView(selection: $selection) {
                    DashboardView()
                        .tag(DrawerTab.dashboard)
                        .tabItem {
                            Label("Home", systemImage: "house")
                        }

                    TasksListView(viewModel: tasksViewModel, usersViewModel: usersViewModel)
                        .tag(DrawerTab.tasks)
                        .tabItem {
                            Label("Tasks", systemImage: "checklist")
                        }

                    ProjectsListView(viewModel: projectsViewModel)
                        .tag(DrawerTab.projects)
                        .tabItem {
                            Label("Projects", systemImage: "folder")
                        }

                    TeamsView()
                        .tag(DrawerTab.teams)
                        .tabItem {
                            Label("Teams", systemImage: "person.3")
                        }
                }
                .tint(LLColors.primary.color(for: colorScheme))
                .appBackground()

                if isMenuOpen {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                        .onTapGesture { isMenuOpen = false }

                    drawerMenu
                        .transition(.move(edge: .leading))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isMenuOpen)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        isMenuOpen.toggle()
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(LLColors.foreground.color(for: colorScheme))
                    }
                }

                ToolbarItem(placement: .principal) {
                    HStack(spacing: LLSpacing.xs) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(LLColors.primary.color(for: colorScheme))
                            .frame(width: 26, height: 26)
                            .overlay(
                                Text("LU")
                                    .font(LLTypography.bodySmall())
                                    .foregroundColor(LLColors.primaryForeground.color(for: colorScheme))
                            )
                        Text("LUID")
                            .h4()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: LLSpacing.md) {
                        Button {
                            // Hook up search later.
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                        }

                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                                .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                        }
                    }
                }
            }
            .toolbarBackground(LLColors.background.color(for: colorScheme), for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showSettings) {
                NavigationStack {
                    SettingsView()
                        .navigationTitle("Settings")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
            .sheet(isPresented: $showMissionControl) {
                NavigationStack {
                    MissionControlView()
                        .navigationTitle("Mission Control")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
            .sheet(isPresented: $showPriority) {
                NavigationStack {
                    PriorityView()
                        .navigationTitle("Priority")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
            .sheet(isPresented: $showTimeline) {
                NavigationStack {
                    TimelineView()
                        .navigationTitle("Timeline")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
            .sheet(isPresented: $showUsers) {
                NavigationStack {
                    UsersView()
                        .navigationTitle("Users")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
    }

    private var drawerMenu: some View {
        GeometryReader { proxy in
            VStack(alignment: .leading, spacing: LLSpacing.lg) {
                VStack(alignment: .leading, spacing: LLSpacing.xs) {
                    Text("TaskLuid")
                        .h3()
                    Text("Project workspace")
                        .bodySmall()
                        .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))
                }

                Text("MY WORK")
                    .captionText()
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                VStack(alignment: .leading, spacing: LLSpacing.xs) {
                    ForEach(DrawerTab.allCases) { item in
                        Button {
                            selection = item
                            isMenuOpen = false
                        } label: {
                            HStack(spacing: LLSpacing.sm) {
                                Image(systemName: item.systemImage)
                                    .frame(width: 20)
                                Text(item.title)
                                    .bodyText()
                                Spacer()
                            }
                            .padding(.vertical, LLSpacing.sm)
                            .padding(.horizontal, LLSpacing.md)
                            .background(selection == item ? LLColors.muted.color(for: colorScheme) : Color.clear)
                            .cornerRadius(14)
                            .foregroundColor(LLColors.foreground.color(for: colorScheme))
                        }
                    }
                }

                Divider()
                    .background(LLColors.border.color(for: colorScheme))

                Text("TOOLS")
                    .captionText()
                    .foregroundColor(LLColors.mutedForeground.color(for: colorScheme))

                VStack(alignment: .leading, spacing: LLSpacing.xs) {
                    drawerButton(title: "Mission Control", icon: "sparkles") {
                        showMissionControl = true
                    }
                    drawerButton(title: "Priority", icon: "flag") {
                        showPriority = true
                    }
                    drawerButton(title: "Timeline", icon: "calendar") {
                        showTimeline = true
                    }
                    drawerButton(title: "Users", icon: "person.2") {
                        showUsers = true
                    }
                }

                Divider()
                    .background(LLColors.border.color(for: colorScheme))

                Button {
                    showSettings = true
                    isMenuOpen = false
                } label: {
                    HStack(spacing: LLSpacing.sm) {
                        Image(systemName: "gearshape")
                            .frame(width: 20)
                        Text("Settings")
                            .bodyText()
                        Spacer()
                    }
                    .padding(.vertical, LLSpacing.sm)
                    .padding(.horizontal, LLSpacing.md)
                    .foregroundColor(LLColors.foreground.color(for: colorScheme))
                }

                Spacer()
            }
            .padding(.top, (proxy.safeAreaInsets.top * 0.4) + LLSpacing.sm)
            .padding(.horizontal, LLSpacing.lg)
            .frame(maxWidth: 280, maxHeight: .infinity, alignment: .topLeading)
            .background(LLColors.card.color(for: colorScheme))
            .shadow(color: Color.black.opacity(0.12), radius: 16, x: 6, y: 0)
            .ignoresSafeArea(edges: .bottom)
        }
    }

    private func drawerButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
            isMenuOpen = false
        } label: {
            HStack(spacing: LLSpacing.sm) {
                Image(systemName: icon)
                    .frame(width: 20)
                Text(title)
                    .bodyText()
                Spacer()
            }
            .padding(.vertical, LLSpacing.sm)
            .padding(.horizontal, LLSpacing.md)
            .foregroundColor(LLColors.foreground.color(for: colorScheme))
        }
    }
}
