//
//  Repository.swift
//  Takeover
//
//  Created by Alex Vaos on 11/7/25.
//

import Foundation

struct RepositoryResponse: Decodable {
    let os_recipes: [OSRecipe]
    let apps: [App]
}

struct OSRecipe: Decodable {
    let name: String
    let defaults: String
}

struct App: Decodable {
    let name: String
    let files: [File]
}

struct File: Decodable {
    let path: String
}

struct Repository {
    let fileName = "Repository"
    
    func fetch(completion: @escaping (Result<RepositoryResponse, Error>) -> Void) {
        // Load local file
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            fatalError("Failed to find \(fileName) in bundle.")
        }
        do {
            let data = try Data(contentsOf: url)
            return parseJson(data)
        } catch {
            print("error:\(error)")
        }
    }
    
    func parseJson(_ data: Data) -> RepositoryResponse? {
        return try? JSONDecoder().decode(RepositoryResponse.self, from: data)
    }
}

//Repository.fetch { result in
//    
//}
