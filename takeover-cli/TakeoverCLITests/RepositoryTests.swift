//
//  RepositoryTests.swift
//  TakeoverCLITests
//
//  Created by Alex Vaos on 1/20/26.
//

import XCTest
import Yams
@testable import TakeoverCLI

class RepositoryTests: XCTestCase {

    var tempDirectory: URL!

    override func setUp() {
        super.setUp()

        // Create a temporary directory for test files
        tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("RepositoryTests")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        // Set the test file path for TestRepository
        let testFilePath = tempDirectory.appendingPathComponent("test_repository.yml").path
        TestRepository.setTestFilePath(testFilePath)
    }

    override func tearDown() {
        // Clean up temporary files
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    // MARK: - Sample Data

    private var sampleRepositoryData: [RepositoryStructure] {
        return [
            RepositoryStructure(
                name: "SSH",
                from: "~/.ssh",
                to: "ssh",
                after: ["sudo chmod 0600 $to"]
            ),
            RepositoryStructure(
                name: "Desktop",
                from: "~/Desktop",
                to: nil,
                after: nil
            ),
            RepositoryStructure(
                name: "Documents",
                from: "~/Documents",
                to: nil,
                after: nil
            ),
            RepositoryStructure(
                name: "Hosts",
                from: "/etc/hosts",
                to: "hosts",
                after: nil
            ),
            RepositoryStructure(
                name: "Fonts",
                from: "/Library/Fonts",
                to: nil,
                after: nil
            ),
            RepositoryStructure(
                name: "FileZilla",
                from: "~/.filezilla",
                to: nil,
                after: nil
            )
        ]
    }

    private var sampleYAMLString: String {
        return """
        - name: SSH
          from: ~/.ssh
          to: ssh
          after:
            - sudo chmod 0600 $to
        - name: Desktop
          from: ~/Desktop
        - name: Documents
          from: ~/Documents
        - name: Hosts
          from: /etc/hosts
          to: hosts
        - name: Fonts
          from: /Library/Fonts
        - name: FileZilla
          from: ~/.filezilla
        """
    }

    // MARK: - Load Tests

    func testLoadValidYAML() throws {
        // Given: A valid YAML file with sample data
        try sampleYAMLString.write(to: testFileURL, atomically: true, encoding: .utf8)

        // When: Loading the repositories
        let repositories = try TestRepository.load()

        // Then: Should successfully load all repositories
        XCTAssertEqual(repositories.count, 6)

        // Verify first repository (SSH)
        let sshRepo = repositories[0]
        XCTAssertEqual(sshRepo.name, "SSH")
        XCTAssertEqual(sshRepo.from, "~/.ssh")
        XCTAssertEqual(sshRepo.to, "ssh")
        XCTAssertEqual(sshRepo.after, ["sudo chmod 0600 $to"])

        // Verify second repository (Desktop) - no to or after
        let desktopRepo = repositories[1]
        XCTAssertEqual(desktopRepo.name, "Desktop")
        XCTAssertEqual(desktopRepo.from, "~/Desktop")
        XCTAssertNil(desktopRepo.to)
        XCTAssertNil(desktopRepo.after)

        // Verify fourth repository (Hosts) - has to but no after
        let hostsRepo = repositories[3]
        XCTAssertEqual(hostsRepo.name, "Hosts")
        XCTAssertEqual(hostsRepo.from, "/etc/hosts")
        XCTAssertEqual(hostsRepo.to, "hosts")
        XCTAssertNil(hostsRepo.after)
    }

    func testLoadEmptyFile() throws {
        // Given: An empty YAML file
        try "".write(to: testFileURL, atomically: true, encoding: .utf8)

        // When: Loading the repositories
        let repositories = try TestRepository.load()

        // Then: Should return empty array
        XCTAssertEqual(repositories.count, 0)
    }

    func testLoadFileNotFound() {
        // Given: No file exists at the path

        // When/Then: Loading should throw an error
        XCTAssertThrowsError(try (testRepository as! TestRepository).load()) { error in
            XCTAssertTrue(error is CocoaError || error is DecodingError)
        }
    }

    func testLoadInvalidYAML() {
        // Given: Invalid YAML content
        let invalidYAML = """
        - name: Test
          from: ~/test
          invalid_field: value
        - name: Another
          missing_from_field: true
        """

        try? invalidYAML.write(to: testFileURL, atomically: true, encoding: .utf8)

        // When/Then: Loading should throw a decoding error
        XCTAssertThrowsError(try (testRepository as! TestRepository).load()) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    // MARK: - Save Tests

    func testSaveValidData() throws {
        // Given: Sample repository data
        let repositories = sampleRepositoryData

        // When: Saving the repositories
        try TestRepository.save(repositories)

        // Then: File should exist and contain valid YAML
        XCTAssertTrue(FileManager.default.fileExists(atPath: testFileURL.path))

        // Verify we can load it back
        let loadedRepositories = try (testRepository as! TestRepository).load()
        XCTAssertEqual(loadedRepositories.count, repositories.count)

        // Verify first repository
        XCTAssertEqual(loadedRepositories[0].name, "SSH")
        XCTAssertEqual(loadedRepositories[0].from, "~/.ssh")
        XCTAssertEqual(loadedRepositories[0].to, "ssh")
        XCTAssertEqual(loadedRepositories[0].after, ["sudo chmod 0600 $to"])
    }

    func testSaveEmptyArray() throws {
        // Given: Empty array of repositories
        let repositories: [RepositoryStructure] = []

        // When: Saving the repositories
        try TestRepository.save(repositories)

        // Then: File should exist
        XCTAssertTrue(FileManager.default.fileExists(atPath: testFileURL.path))

        // And loading it back should return empty array
        let loadedRepositories = try (testRepository as! TestRepository).load()
        XCTAssertEqual(loadedRepositories.count, 0)
    }

    func testSaveOverwritesExistingFile() throws {
        // Given: An existing file with different content
        try sampleYAMLString.write(to: testFileURL, atomically: true, encoding: .utf8)

        // Verify initial content
        let initialRepositories = try (testRepository as! TestRepository).load()
        XCTAssertEqual(initialRepositories.count, 6)

        // When: Saving different data
        let newRepositories = [
            RepositoryStructure(name: "New Repo", from: "~/new", to: nil, after: nil)
        ]
        try (testRepository as! TestRepository).save(newRepositories)

        // Then: File should contain new data
        let loadedRepositories = try (testRepository as! TestRepository).load()
        XCTAssertEqual(loadedRepositories.count, 1)
        XCTAssertEqual(loadedRepositories[0].name, "New Repo")
    }

    // MARK: - Round-trip Tests

    func testLoadSaveRoundTrip() throws {
        // Given: Original repository data
        let originalRepositories = sampleRepositoryData

        // When: Save then load
        try (testRepository as! TestRepository).save(originalRepositories)
        let loadedRepositories = try (testRepository as! TestRepository).load()

        // Then: Data should be identical
        XCTAssertEqual(loadedRepositories.count, originalRepositories.count)

        for (original, loaded) in zip(originalRepositories, loadedRepositories) {
            XCTAssertEqual(original.name, loaded.name)
            XCTAssertEqual(original.from, loaded.from)
            XCTAssertEqual(original.to, loaded.to)
            XCTAssertEqual(original.after, loaded.after)
        }
    }

    // MARK: - Integration Tests

    func testRepositoryMatchesActualDataStructure() throws {
        // Given: Create a test file with actual repository.yml content
        let actualYAML = """
        - name: SSH
          from: ~/.ssh
          to: ssh
          after:
            - sudo chmod 0600 $to
        - name: Desktop
          from: ~/Desktop
        - name: Documents
          from: ~/Documents
        - name: Hosts
          from: /etc/hosts
          to: hosts
        - name: Fonts
          from: /Library/Fonts
        - name: User Fonts
          from: ~/Library/Fonts
        - name: FileZilla
          from: ~/.filezilla
        - name: Cyberduck
          from: ~/Library/Application Support/Cyberduck
        - name: Table Plus
          from: dunno
        """

        try actualYAML.write(to: testFileURL, atomically: true, encoding: .utf8)

        // When: Loading the repositories
        let repositories = try TestRepository.load()

        // Then: Should successfully load all 9 repositories
        XCTAssertEqual(repositories.count, 9)

        // Verify specific repositories
        XCTAssertEqual(repositories[0].name, "SSH")
        XCTAssertEqual(repositories[0].from, "~/.ssh")
        XCTAssertEqual(repositories[0].to, "ssh")
        XCTAssertEqual(repositories[0].after, ["sudo chmod 0600 $to"])

        XCTAssertEqual(repositories[1].name, "Desktop")
        XCTAssertEqual(repositories[1].from, "~/Desktop")
        XCTAssertNil(repositories[1].to)
        XCTAssertNil(repositories[1].after)

        XCTAssertEqual(repositories[8].name, "Table Plus")
        XCTAssertEqual(repositories[8].from, "dunno")
        XCTAssertNil(repositories[8].to)
        XCTAssertNil(repositories[8].after)
    }
}

// MARK: - Test Helper Classes

class TestRepository {
    private static var testFilePath: String?

    static func setTestFilePath(_ path: String) {
        testFilePath = path
    }

    static func load() throws -> [RepositoryStructure] {
        let fileURL = URL(fileURLWithPath: testFilePath ?? Repository.filePath)
        let data = try Data(contentsOf: fileURL)
        let repositories: [RepositoryStructure] = try YAMLDecoder().decode([RepositoryStructure].self, from: data)
        return repositories
    }

    static func save(_ repositories: [RepositoryStructure]) throws {
        let fileURL = URL(fileURLWithPath: testFilePath ?? Repository.filePath)
        let yamlData = try YAMLEncoder().encode(repositories)
        try yamlData.write(to: fileURL, atomically: true, encoding: .utf8)
    }
}