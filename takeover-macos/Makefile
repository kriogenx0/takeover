BUILD_DIR := build
APP_NAME := Takeover.app

.DEFAULT_GOAL := install

.PHONY: test install install-open

test:
	@echo "Running unit tests for TakeoverCLI..."
	@if command -v swift > /dev/null 2>&1; then \
		echo "Using Swift Package Manager to run tests..."; \
		swift test; \
	elif command -v xcodebuild > /dev/null 2>&1; then \
		echo "Using xcodebuild to run tests..."; \
		xcodebuild -project TakeoverCLI.xcodeproj -scheme TakeoverCLI -enableCodeCoverage YES test; \
	else \
		echo "Error: Neither 'swift' nor 'xcodebuild' found in PATH"; \
		echo "Please ensure Xcode or Swift toolchain is installed"; \
		exit 1; \
	fi
	@echo "Tests completed successfully!"

install:
	@echo "Building $(APP_NAME)..."
	xcodebuild -project Takeover.xcodeproj -scheme Takeover -configuration Release \
		-derivedDataPath $(BUILD_DIR) build
	@echo "Installing to /Applications..."
	cp -R "$(BUILD_DIR)/Build/Products/Release/$(APP_NAME)" /Applications/
	@echo "$(APP_NAME) installed successfully!"

install-open: install
	open /Applications/$(APP_NAME)
