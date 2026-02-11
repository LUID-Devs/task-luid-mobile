//
//  CreateAgentView.swift
//  TaskLuid
//

import SwiftUI

struct CreateAgentView: View {
    @State private var name = ""
    @State private var displayName = ""
    @State private var role = ""
    let onCreate: (String, String, String) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: LLSpacing.md) {
                SectionHeaderView("New Agent", subtitle: "Create an AI agent for your workspace.")
                LLTextField(title: "System name", placeholder: "e.g. mr-krabs", text: $name)
                LLTextField(title: "Display name", placeholder: "e.g. Mr Krabs", text: $displayName)
                LLTextField(title: "Role", placeholder: "e.g. squad-lead", text: $role)

                LLButton("Create Agent", style: .primary, fullWidth: true) {
                    onCreate(name, displayName, role)
                    dismiss()
                }

                Spacer()
            }
            .screenPadding()
            .navigationTitle("Create Agent")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
