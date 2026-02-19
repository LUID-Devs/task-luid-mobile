//
//  MissionControlViewModel.swift
//  TaskLuid
//

import Foundation

@MainActor
class MissionControlViewModel: ObservableObject {
    @Published var agents: [Agent] = []
    @Published var activity: [ActivityLog] = []
    @Published var agentTasks: [AgentTaskAssignment] = []
    @Published var isLoading = false
    @Published var isLoadingTasks = false
    @Published var errorMessage: String? = nil
    @Published var isCreatingAgent = false
    @Published var canManageAgents = false

    private let service = MissionControlService.shared
    private let keychain = KeychainManager.shared
    private let organizationService = OrganizationService.shared
    private var isRefreshingAgents = false
    private var isRefreshingActivity = false
    private var isRefreshingAgentTasks = false

    func loadMissionControl() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let orgId = Int(keychain.getActiveOrganizationId() ?? "")

        do {
            async let agentsTask = service.getAgents(organizationId: orgId)
            let orgs = (try? await organizationService.getOrganizations()) ?? []
            if let orgId, let activeOrg = orgs.first(where: { $0.id == orgId }) {
                canManageAgents = activeOrg.role == "admin" || activeOrg.role == "owner"
            } else {
                canManageAgents = false
            }

            if let orgId {
                async let activityTask = service.getActivityFeed(organizationId: orgId, limit: 25)
                agents = try await agentsTask
                activity = try await activityTask
            } else {
                agents = try await agentsTask
                activity = []
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadAgentTasks() async {
        guard !isLoadingTasks else { return }
        isLoadingTasks = true
        errorMessage = nil
        defer { isLoadingTasks = false }

        do {
            if agents.isEmpty {
                let orgId = Int(keychain.getActiveOrganizationId() ?? "")
                agents = try await service.getAgents(organizationId: orgId)
            }

            var allTasks: [AgentTaskAssignment] = []
            try await withThrowingTaskGroup(of: [AgentTaskAssignment].self) { group in
                for agent in agents {
                    group.addTask {
                        try await self.service.getAgentTasks(agentId: agent.id)
                    }
                }

                for try await tasks in group {
                    allTasks.append(contentsOf: tasks)
                }
            }
            agentTasks = allTasks
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createAgent(name: String, displayName: String, role: String) async {
        isCreatingAgent = true
        errorMessage = nil
        defer { isCreatingAgent = false }

        do {
            _ = try await service.createAgent(name: name, displayName: displayName, role: role)
            await loadMissionControl()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteAgent(agentId: Int) async {
        do {
            _ = try await service.deleteAgent(agentId: agentId)
            agents.removeAll { $0.id == agentId }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshAgents() async {
        guard !isRefreshingAgents else { return }
        isRefreshingAgents = true
        defer { isRefreshingAgents = false }

        do {
            let orgId = resolveOrganizationId()
            agents = try await service.getAgents(organizationId: orgId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshActivity() async {
        guard !isRefreshingActivity else { return }
        isRefreshingActivity = true
        defer { isRefreshingActivity = false }

        do {
            if let orgId = resolveOrganizationId() {
                activity = try await service.getActivityFeed(organizationId: orgId, limit: 25)
            } else {
                activity = []
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshAgentTasks() async {
        guard !isRefreshingAgentTasks else { return }
        isRefreshingAgentTasks = true
        defer { isRefreshingAgentTasks = false }

        do {
            if agents.isEmpty {
                let orgId = resolveOrganizationId()
                agents = try await service.getAgents(organizationId: orgId)
            }

            var allTasks: [AgentTaskAssignment] = []
            try await withThrowingTaskGroup(of: [AgentTaskAssignment].self) { group in
                for agent in agents {
                    group.addTask {
                        try await self.service.getAgentTasks(agentId: agent.id)
                    }
                }

                for try await tasks in group {
                    allTasks.append(contentsOf: tasks)
                }
            }
            agentTasks = allTasks
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func resolveOrganizationId() -> Int? {
        keychain.getActiveOrganizationId().flatMap { Int($0) }
    }
}
