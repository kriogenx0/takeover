//
//  Repository.swift
//  TakeoverCLI
//
//  Created by Alex Vaos on 1/20/26.
//

import Foundation
import Yams

struct RepositoryStructure: Codable {
    let name: String
    let from: String
    let to: String?
    let after: [String]?
}

class Repository {

    static let filePath = "repository.yml"

    static func load() throws -> [RepositoryStructure] {
        let fileURL = URL(fileURLWithPath: filePath)
        let data = try Data(contentsOf: fileURL)
        let repositories: [RepositoryStructure] = try YAMLDecoder().decode([RepositoryStructure].self, from: data)
        return repositories
    }

    static func save(_ repositories: [RepositoryStructure]) throws {
        let fileURL = URL(fileURLWithPath: filePath)
        let yamlData = try YAMLEncoder().encode(repositories)
        try yamlData.write(to: fileURL, atomically: true, encoding: .utf8)
    }
}
