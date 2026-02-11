//
//  ProjectCreateView.swift
//  TaskLuid
//

import SwiftUI

struct ProjectCreateView: View {
    @State private var name = ""
    @State private var description = ""
    @State private var errorMessage: String? = nil
    @State private var isSubmitting = false
    let onCreate: (String, String?) async -> String?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: LLSpacing.md) {
                LLTextField(title: "Project name", placeholder: "Project name", text: $name)
                LLTextField(title: "Description", placeholder: "Optional description", text: $description)

                if let errorMessage {
                    InlineErrorView(message: errorMessage)
                }

                LLButton("Create Project", style: .primary, isLoading: isSubmitting, fullWidth: true) {
                    Task {
                        isSubmitting = true
                        errorMessage = await onCreate(name, description.isEmpty ? nil : description)
                        isSubmitting = false
                        if errorMessage == nil {
                            dismiss()
                        }
                    }
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
