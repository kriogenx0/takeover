//
//  Repository.swift
//  Takeover
//
//  Created by Alex Vaos on 11/7/25.
//

import Foundation

struct RepositoryResponse: Decodable {
    let os_recipies: [OSRecipe]?
    let apps: [AppConfig]

    enum CodingKeys: String, CodingKey {
        case os_recipies
        case apps
    }
}

struct OSRecipe: Decodable, Identifiable {
    let id = UUID()
    let name: String
    let defaults: String

    enum CodingKeys: String, CodingKey {
        case name
        case defaults
    }
}

struct AppConfig: Decodable, Identifiable {
    let id = UUID()
    let name: String
    let files: [FileConfig]
    let defaults: [String]?

    enum CodingKeys: String, CodingKey {
        case name
        case files
        case defaults
    }
}

struct FileConfig: Decodable {
    let path: String

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let pathString = try? container.decode(String.self) {
            // Handle string format: "/Library/Audio/Plug-Ins"
            self.path = pathString
        } else {
            // Handle object format: {"path": "~/.ssh"}
            let fileObject = try decoder.container(keyedBy: CodingKeys.self)
            self.path = try fileObject.decode(String.self, forKey: .path)
        }
    }

    enum CodingKeys: String, CodingKey {
        case path
    }
}

struct Repository {
    let fileName = "Repository"

    func fetch(completion: @escaping (Result<RepositoryResponse, Error>) -> Void) {
        // Load local file
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            completion(.failure(NSError(domain: "Repository", code: 404, userInfo: [NSLocalizedDescriptionKey: "Failed to find \(fileName) in bundle."])))
            return
        }
        do {
            let data = try Data(contentsOf: url)
            if let response = parseJson(data) {
                completion(.success(response))
            } else {
                completion(.failure(NSError(domain: "Repository", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to parse JSON"])))
            }
        } catch {
            completion(.failure(error))
        }
    }

    func parseJson(_ data: Data) -> RepositoryResponse? {
        return try? JSONDecoder().decode(RepositoryResponse.self, from: data)
    }
}
