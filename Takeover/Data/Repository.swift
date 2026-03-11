//
//  Repository.swift
//  Takeover
//
//  Created by Alex Vaos on 11/7/25.
//

import Foundation
import Observation

struct RepositoryResponse: Decodable {
    let version: Int
    let os_recipies: [OSRecipe]?
    let apps: [AppConfig]

    enum CodingKeys: String, CodingKey {
        case version
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

@Observable
class Repository {
    static let shared = Repository()

    private(set) var response: RepositoryResponse?
    private(set) var isLoading = false
    private(set) var error: Error?

    private let remoteURL = URL(string: "https://raw.githubusercontent.com/kriogenx0/takeover/main/api/repository.json")!
    private let cacheURL: URL = {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return caches.appendingPathComponent("Repository.json")
    }()
    private let cacheDateKey = "RepositoryCacheDate"
    private let cacheDuration: TimeInterval = 86400 // 1 day

    private init() {}

    func load() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        // Return cached data if it's fresh
        if let cachedDate = UserDefaults.standard.object(forKey: cacheDateKey) as? Date,
           Date().timeIntervalSince(cachedDate) < cacheDuration,
           let data = try? Data(contentsOf: cacheURL),
           let cached = try? JSONDecoder().decode(RepositoryResponse.self, from: data) {
            response = cached
            return
        }

        // Fetch from network
        do {
            let (data, _) = try await URLSession.shared.data(from: remoteURL)
            let decoded = try JSONDecoder().decode(RepositoryResponse.self, from: data)
            try data.write(to: cacheURL)
            UserDefaults.standard.set(Date(), forKey: cacheDateKey)
            response = decoded
        } catch let fetchError {
            // Fall back to stale cache if available
            if let data = try? Data(contentsOf: cacheURL),
               let cached = try? JSONDecoder().decode(RepositoryResponse.self, from: data) {
                response = cached
            } else {
                error = fetchError
            }
        }
    }
}
