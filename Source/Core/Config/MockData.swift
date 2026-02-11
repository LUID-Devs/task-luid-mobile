//
//  MockData.swift
//  TaskLuid
//

import Foundation

enum MockData {
    static let users: [User] = [
        User(userId: 1, username: "test", email: "test@example.com", profilePictureUrl: nil, cognitoId: nil, teamId: 1, role: "admin"),
        User(userId: 2, username: "jasmine", email: "jasmine@example.com", profilePictureUrl: nil, cognitoId: nil, teamId: 1, role: "member"),
        User(userId: 3, username: "sam", email: "sam@example.com", profilePictureUrl: nil, cognitoId: nil, teamId: 2, role: "project_manager")
    ]

    static let projects: [Project] = [
        Project(
            id: 101,
            name: "Website Refresh",
            description: "Revamp the landing pages and onboarding flow.",
            startDate: nil,
            endDate: nil,
            archived: false,
            archivedAt: nil,
            isFavorited: true,
            statistics: ProjectStatistics(
                totalTasks: 12,
                completedTasks: 5,
                inProgressTasks: 4,
                todoTasks: 3,
                progress: 0.42,
                memberCount: 4,
                status: "Active"
            ),
            teamMembers: [
                ProjectMember(userId: 1, username: "test", profilePictureUrl: nil),
                ProjectMember(userId: 2, username: "jasmine", profilePictureUrl: nil),
                ProjectMember(userId: 3, username: "sam", profilePictureUrl: nil)
            ],
            taskCount: 12
        ),
        Project(
            id: 102,
            name: "Mobile Sprint",
            description: "Finish authentication and core task flows.",
            startDate: nil,
            endDate: nil,
            archived: false,
            archivedAt: nil,
            isFavorited: false,
            statistics: ProjectStatistics(
                totalTasks: 8,
                completedTasks: 2,
                inProgressTasks: 3,
                todoTasks: 3,
                progress: 0.25,
                memberCount: 3,
                status: "Active"
            ),
            teamMembers: [
                ProjectMember(userId: 1, username: "test", profilePictureUrl: nil),
                ProjectMember(userId: 2, username: "jasmine", profilePictureUrl: nil)
            ],
            taskCount: 8
        )
    ]

    static let tasks: [TaskItem] = [
        TaskItem(
            id: 201,
            title: "Finalize hero layout",
            description: "Align typography and CTA spacing for the top fold.",
            descriptionImageUrl: nil,
            status: .workInProgress,
            priority: .high,
            taskType: .feature,
            tags: "ui,homepage",
            startDate: nil,
            dueDate: "2026-02-12",
            points: 5,
            projectId: 101,
            authorUserId: 1,
            assignedUserId: 2,
            author: users[0],
            assignee: users[1],
            comments: [
                Comment(id: 1, text: "Spacing looks better with 24pt padding.", imageUrl: nil, taskId: 201, userId: 2, createdAt: "", updatedAt: "", user: CommentUser(userId: 2, username: "jasmine", email: "jasmine@example.com", profilePictureUrl: nil))
            ],
            attachments: [
                Attachment(id: 1, fileURL: "https://example.com/mock.pdf", fileName: "layout-specs.pdf", presignedUrl: nil, taskId: 201, uploadedById: 1, uploadedBy: AttachmentUser(userId: 1, username: "test", email: "test@example.com"))
            ]
        ),
        TaskItem(
            id: 202,
            title: "Setup push notification copy",
            description: "Draft onboarding push notifications.",
            descriptionImageUrl: nil,
            status: .toDo,
            priority: .medium,
            taskType: .chore,
            tags: "content",
            startDate: nil,
            dueDate: "2026-02-15",
            points: 3,
            projectId: 102,
            authorUserId: 1,
            assignedUserId: 3,
            author: users[0],
            assignee: users[2],
            comments: [],
            attachments: []
        )
    ]

    static let teams: [Team] = [
        Team(
            teamId: 1,
            teamName: "Product",
            productOwnerUserId: 1,
            projectManagerUserId: 3,
            productOwnerUsername: "test",
            projectManagerUsername: "sam"
        ),
        Team(
            teamId: 2,
            teamName: "Design",
            productOwnerUserId: 2,
            projectManagerUserId: 1,
            productOwnerUsername: "jasmine",
            projectManagerUsername: "test"
        )
    ]
}
