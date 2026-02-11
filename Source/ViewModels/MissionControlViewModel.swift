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

    private let service = MissionControlService.shared
    private let keychain = KeychainManager.shared

    func loadMissionControl() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let orgId = Int(keychain.getActiveOrganizationId() ?? "")

        do {
            async let agentsTask = service.getAgents(organizationId: orgId)
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
}
