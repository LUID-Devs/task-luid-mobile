//
//  ProjectCreateView.swift
//  TaskLuid
//

import SwiftUI

struct ProjectCreateView: View {
    @State private var name = ""
    @State private var description = ""
    let onCreate: (String, String?) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: LLSpacing.md) {
                LLTextField(title: "Project name", placeholder: "Project name", text: $name)
                LLTextField(title: "Description", placeholder: "Optional description", text: $description)

                LLButton("Create Project", style: .primary, fullWidth: true) {
                    onCreate(name, description.isEmpty ? nil : description)
                    dismiss()
                }
            }
            .screenPadding()
            .navigationTitle("New Project")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
