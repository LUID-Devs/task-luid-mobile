//
//  Attachment.swift
//  TaskLuid
//

import Foundation

struct AttachmentUser: Codable {
    let userId: Int
    let username: String
    let email: String?
}

struct Attachment: Codable, Identifiable {
    let id: Int
    let fileURL: String
    let fileName: String?
    let taskId: Int
    let uploadedById: Int
    let uploadedBy: AttachmentUser
}
