//
//  UserSettingsTests.swift
//  TakeoverCLITests
//
//  Created by Alex Vaos on 1/20/26.
//

import XCTest
import Yams
@testable import TakeoverCLI

class UserSettingsTests: XCTestCase {

    var tempDirectory: URL!
    var testUserSettings: UserSettings!
    var testFileURL: URL!

    override func setUp() {
        super.setUp()

        // Create a temporary directory for test files
        tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("UserSettingsTests")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        // Create a test user settings instance that uses our temp file
        testUserSettings = TestUserSettings(testFileURL: tempDirectory.appendingPathComponent("test_user_settings.yml"))
    }

    override func tearDown() {
        // Clean up temporary files
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    // MARK: - Sample Data

    private var sampleSettings: Settings {
        return Settings(
            ssh: Setting(on: true),
            hosts: Setting(on: false),
            table_plus: Setting(on: true)
        )
    }

    private var sampleYAMLString: String {
        return """
        settings:
          ssh:
            on: true
          hosts:
            on: false
          table_plus:
            on: true
        """
    }

    private var minimalYAMLString: String {
        return """
        settings:
          ssh:
            on: true
        """
    }

    private var emptySettingsYAMLString: String {
        return """
        settings:
        """
    }

    // MARK: - Load Tests

    func testLoadValidYAML() throws {
        // Given: A valid YAML file with sample settings
        try sampleYAMLString.write(to: testUserSettings.filePathURL, atomically: true, encoding: .utf8)

        // When: Loading the settings
        let settings = try testUserSettings.load()

        // Then: Should successfully load all settings
        XCTAssertNotNil(settings.ssh)
        XCTAssertNotNil(settings.hosts)
        XCTAssertNotNil(settings.table_plus)

        XCTAssertEqual(settings.ssh?.on, true)
        XCTAssertEqual(settings.hosts?.on, false)
        XCTAssertEqual(settings.table_plus?.on, true)
    }

    func testLoadMinimalYAML() throws {
        // Given: A YAML file with only some settings
        try minimalYAMLString.write(to: testUserSettings.filePathURL, atomically: true, encoding: .utf8)

        // When: Loading the settings
        let settings = try testUserSettings.load()

        // Then: Should load the available settings and nil for missing ones
        XCTAssertNotNil(settings.ssh)
        XCTAssertEqual(settings.ssh?.on, true)

        XCTAssertNil(settings.hosts)
        XCTAssertNil(settings.table_plus)
    }

    func testLoadEmptySettings() throws {
        // Given: A YAML file with empty settings
        try emptySettingsYAMLString.write(to: testUserSettings.filePathURL, atomically: true, encoding: .utf8)

        // When: Loading the settings
        let settings = try testUserSettings.load()

        // Then: All settings should be nil
        XCTAssertNil(settings.ssh)
        XCTAssertNil(settings.hosts)
        XCTAssertNil(settings.table_plus)
    }

    func testLoadFileNotFound() {
        // Given: No file exists at the path

        // When/Then: Loading should throw an error
        XCTAssertThrowsError(try testUserSettings.load()) { error in
            XCTAssertTrue(error is CocoaError || error is DecodingError)
        }
    }

    func testLoadInvalidYAML() {
        // Given: Invalid YAML content
        let invalidYAML = """
        settings:
          ssh:
            on: true
          hosts:
            invalid_field: true
            on: maybe
        """

        try? invalidYAML.write(to: testUserSettings.filePathURL, atomically: true, encoding: .utf8)

        // When/Then: Loading should throw a decoding error
        XCTAssertThrowsError(try testUserSettings.load()) { error in
            XCTAssertTrue(error is DecodingError)
        }
    }

    func testLoadMalformedYAML() {
        // Given: Malformed YAML content
        let malformedYAML = """
        settings:
          ssh:
            on: true
          hosts:
            on: false
            [invalid yaml syntax
        """

        try? malformedYAML.write(to: testUserSettings.filePathURL, atomically: true, encoding: .utf8)

        // When/Then: Loading should throw an error
        XCTAssertThrowsError(try testUserSettings.load()) { error in
            // Could be Yams parsing error or other decoding error
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Save Tests

    func testSaveValidData() throws {
        // Given: Sample settings data
        let settings = sampleSettings

        // When: Saving the settings
        try testUserSettings.save(settings)

        // Then: File should exist and contain valid YAML
        XCTAssertTrue(FileManager.default.fileExists(atPath: testUserSettings.filePathURL.path))

        // Verify we can load it back
        let loadedSettings = try testUserSettings.load()
        XCTAssertEqual(loadedSettings.ssh?.on, true)
        XCTAssertEqual(loadedSettings.hosts?.on, false)
        XCTAssertEqual(loadedSettings.table_plus?.on, true)
    }

    func testSaveMinimalSettings() throws {
        // Given: Settings with only some values set
        let settings = Settings(
            ssh: Setting(on: true),
            hosts: nil,
            table_plus: nil
        )

        // When: Saving the settings
        try testUserSettings.save(settings)

        // Then: File should exist and loading should work
        let loadedSettings = try testUserSettings.load()
        XCTAssertEqual(loadedSettings.ssh?.on, true)
        XCTAssertNil(loadedSettings.hosts)
        XCTAssertNil(loadedSettings.table_plus)
    }

    func testSaveEmptySettings() throws {
        // Given: Settings with all nil values
        let settings = Settings(ssh: nil, hosts: nil, table_plus: nil)

        // When: Saving the settings
        try testUserSettings.save(settings)

        // Then: File should exist and loading should work
        let loadedSettings = try testUserSettings.load()
        XCTAssertNil(loadedSettings.ssh)
        XCTAssertNil(loadedSettings.hosts)
        XCTAssertNil(loadedSettings.table_plus)
    }

    func testSaveOverwritesExistingFile() throws {
        // Given: An existing file with different content
        try sampleYAMLString.write(to: testUserSettings.filePathURL, atomically: true, encoding: .utf8)

        // Verify initial content
        let initialSettings = try testUserSettings.load()
        XCTAssertEqual(initialSettings.ssh?.on, true)

        // When: Saving different data
        let newSettings = Settings(
            ssh: Setting(on: false),
            hosts: Setting(on: true),
            table_plus: nil
        )
        try testUserSettings.save(newSettings)

        // Then: File should contain new data
        let loadedSettings = try testUserSettings.load()
        XCTAssertEqual(loadedSettings.ssh?.on, false)
        XCTAssertEqual(loadedSettings.hosts?.on, true)
        XCTAssertNil(loadedSettings.table_plus)
    }

    // MARK: - Round-trip Tests

    func testLoadSaveRoundTrip() throws {
        // Given: Original settings data
        let originalSettings = sampleSettings

        // When: Save then load
        try testUserSettings.save(originalSettings)
        let loadedSettings = try testUserSettings.load()

        // Then: Data should be identical
        XCTAssertEqual(loadedSettings.ssh?.on, originalSettings.ssh?.on)
        XCTAssertEqual(loadedSettings.hosts?.on, originalSettings.hosts?.on)
        XCTAssertEqual(loadedSettings.table_plus?.on, originalSettings.table_plus?.on)
    }

    func testLoadSaveRoundTripWithNilValues() throws {
        // Given: Settings with nil values
        let originalSettings = Settings(
            ssh: Setting(on: true),
            hosts: nil,
            table_plus: Setting(on: false)
        )

        // When: Save then load
        try testUserSettings.save(originalSettings)
        let loadedSettings = try testUserSettings.load()

        // Then: Data should be identical including nil values
        XCTAssertEqual(loadedSettings.ssh?.on, true)
        XCTAssertNil(loadedSettings.hosts)
        XCTAssertEqual(loadedSettings.table_plus?.on, false)
    }

    // MARK: - Integration Tests

    func testUserSettingsMatchesActualDataStructure() throws {
        // Given: Create a test file with actual user_settings.yml content
        let actualYAML = """
        settings:
          ssh:
            on: true
          hosts:
            on: true
          table_plus:
            on: true
        """

        try actualYAML.write(to: testUserSettings.filePathURL, atomically: true, encoding: .utf8)

        // When: Loading the settings
        let settings = try testUserSettings.load()

        // Then: Should successfully load all settings
        XCTAssertNotNil(settings.ssh)
        XCTAssertNotNil(settings.hosts)
        XCTAssertNotNil(settings.table_plus)

        XCTAssertEqual(settings.ssh?.on, true)
        XCTAssertEqual(settings.hosts?.on, true)
        XCTAssertEqual(settings.table_plus?.on, true)
    }

    func testUserSettingsWithAdditionalFields() throws {
        // Given: YAML with additional settings that might be added later
        let extendedYAML = """
        settings:
          ssh:
            on: true
          hosts:
            on: false
          table_plus:
            on: true
          new_setting:
            on: false
        """

        // Note: Since our struct doesn't include new_setting, this should work
        // because the decoder will ignore unknown fields
        try extendedYAML.write(to: testUserSettings.filePathURL, atomically: true, encoding: .utf8)

        // When: Loading the settings
        let settings = try testUserSettings.load()

        // Then: Should successfully load known settings and ignore unknown ones
        XCTAssertNotNil(settings.ssh)
        XCTAssertNotNil(settings.hosts)
        XCTAssertNotNil(settings.table_plus)

        XCTAssertEqual(settings.ssh?.on, true)
        XCTAssertEqual(settings.hosts?.on, false)
        XCTAssertEqual(settings.table_plus?.on, true)
    }

    // MARK: - Edge Cases

    func testSettingToggleFunctionality() throws {
        // Given: Initial settings
        var settings = Settings(
            ssh: Setting(on: true),
            hosts: Setting(on: false),
            table_plus: Setting(on: true)
        )

        // When: Simulating toggling settings (this would be done in your app logic)
        settings = Settings(
            ssh: Setting(on: !settings.ssh!.on),
            hosts: Setting(on: !settings.hosts!.on),
            table_plus: Setting(on: !settings.table_plus!.on)
        )

        try testUserSettings.save(settings)
        let loadedSettings = try testUserSettings.load()

        // Then: Settings should be toggled
        XCTAssertEqual(loadedSettings.ssh?.on, false)  // was true, now false
        XCTAssertEqual(loadedSettings.hosts?.on, true)  // was false, now true
        XCTAssertEqual(loadedSettings.table_plus?.on, false)  // was true, now false
    }
}

// MARK: - Test Helper Classes

class TestUserSettings: UserSettings {
    private let testFileURL: URL

    init(testFileURL: URL) {
        self.testFileURL = testFileURL
        super.init()
    }

    override var filePath: String {
        return testFileURL.path
    }

    // Computed property for convenience in tests
    var filePathURL: URL {
        return testFileURL
    }
}