# TakeoverCLI Unit Tests

This directory contains unit tests for the TakeoverCLI project.

## Repository Tests

The `RepositoryTests.swift` file contains comprehensive unit tests for the `Repository` class that handles loading and saving YAML configuration files.

### Test Coverage

#### Load Functionality (`load()`)
- **testLoadValidYAML**: Tests loading valid YAML data similar to `repository.yml`
- **testLoadEmptyFile**: Tests loading an empty YAML file
- **testLoadFileNotFound**: Tests error handling when the file doesn't exist
- **testLoadInvalidYAML**: Tests error handling for malformed YAML

#### Save Functionality (`save()`)
- **testSaveValidData**: Tests saving repository data to YAML
- **testSaveEmptyArray**: Tests saving an empty array of repositories
- **testSaveOverwritesExistingFile**: Tests that save overwrites existing files

#### Round-trip Testing
- **testLoadSaveRoundTrip**: Tests that data remains consistent when saved and loaded
- **testRepositoryMatchesActualDataStructure**: Tests with real data structure from `repository.yml`

### Sample Data

The tests use sample data that mirrors the structure found in `repository.yml`:

```yaml
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
```

### Test Infrastructure

- **TestRepository**: A test helper class that allows overriding the file path for testing
- **Temporary Files**: Tests use temporary directories and files that are cleaned up after each test
- **Error Testing**: Comprehensive error case testing for file I/O and YAML parsing failures

## UserSettings Tests

The `UserSettingsTests.swift` file contains comprehensive unit tests for the `UserSettings` class that handles loading and saving user settings from YAML configuration files.

### Test Coverage

#### Load Functionality (`load()`)
- **testLoadValidYAML**: Tests loading valid YAML settings data similar to `user_settings.yml`
- **testLoadMinimalYAML**: Tests loading YAML with only some settings defined
- **testLoadEmptySettings**: Tests loading YAML with empty settings section
- **testLoadFileNotFound**: Tests error handling when the settings file doesn't exist
- **testLoadInvalidYAML**: Tests error handling for malformed YAML
- **testLoadMalformedYAML**: Tests error handling for syntactically invalid YAML

#### Save Functionality (`save()`)
- **testSaveValidData**: Tests saving complete settings data to YAML
- **testSaveMinimalSettings**: Tests saving settings with only some values set
- **testSaveEmptySettings**: Tests saving settings with all nil values
- **testSaveOverwritesExistingFile**: Tests that save overwrites existing settings files

#### Round-trip Testing
- **testLoadSaveRoundTrip**: Tests that settings data remains consistent when saved and loaded
- **testLoadSaveRoundTripWithNilValues**: Tests round-trip with nil/optional values

#### Integration Testing
- **testUserSettingsMatchesActualDataStructure**: Tests with real data structure from `user_settings.yml`
- **testUserSettingsWithAdditionalFields**: Tests handling of unknown settings fields
- **testSettingToggleFunctionality**: Tests simulated setting toggle operations

### Sample Data

The tests use sample data that mirrors the structure found in `user_settings.yml`:

```yaml
settings:
  ssh:
    on: true
  hosts:
    on: false
  table_plus:
    on: true
```

### Test Infrastructure

- **TestUserSettings**: A test helper class that allows overriding the file path for testing
- **Temporary Files**: Tests use temporary directories and files that are cleaned up after each test
- **Error Testing**: Comprehensive error case testing for file I/O and YAML parsing failures
- **Optional Value Testing**: Special attention to testing nil/optional values in settings

### Running Tests

To run the tests, use the provided script:

```bash
./run_tests.sh
```

Or run directly with Swift Package Manager:

```bash
swift test
```

Or with Xcode:

```bash
xcodebuild -project TakeoverCLI.xcodeproj -scheme TakeoverCLI test
```