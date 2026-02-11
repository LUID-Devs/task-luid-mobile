//
//  TaskCreateView.swift
//  TaskLuid
//

import SwiftUI

struct TaskCreateView: View {
    let projectId: Int
    let onCreate: (String, String?, TaskPriority?, TaskStatus?) async -> String?

    @State private var title = ""
    @State private var description = ""
    @State private var priority: TaskPriority? = .medium
    @State private var status: TaskStatus? = .toDo
    @State private var errorMessage: String? = nil
    @State private var isSubmitting = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: LLSpacing.md) {
                LLTextField(title: "Title", placeholder: "Task title", text: $title)
                LLTextField(title: "Description", placeholder: "Optional description", text: $description)

                Picker("Priority", selection: $priority) {
                    Text("None").tag(TaskPriority?.none)
                    ForEach(TaskPriority.allCases) { priority in
                        Text(priority.rawValue).tag(TaskPriority?.some(priority))
                    }
                }
                .pickerStyle(.menu)

                Picker("Status", selection: $status) {
                    Text("None").tag(TaskStatus?.none)
                    ForEach(TaskStatus.allCases) { status in
                        Text(status.rawValue).tag(TaskStatus?.some(status))
                    }
                }
                .pickerStyle(.menu)

                if let errorMessage {
                    InlineErrorView(message: errorMessage)
                }

                LLButton("Create Task", style: .primary, isLoading: isSubmitting, fullWidth: true) {
                    Task {
                        isSubmitting = true
                        errorMessage = await onCreate(
                            title,
                            description.isEmpty ? nil : description,
                            priority,
                            status
                        )
                        isSubmitting = false
                        if errorMessage == nil {
                            dismiss()
                        }
                    }
                }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .screenPadding()
            .navigationTitle("New Task")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
