#!/bin/bash

# Run Unit Tests for TakeoverCLI
# This script runs the unit tests using Swift Package Manager

set -e

echo "Running unit tests for TakeoverCLI..."

# Navigate to the project directory
cd "$(dirname "$0")"

# Run tests using Swift Package Manager
if command -v swift &> /dev/null; then
    echo "Using Swift Package Manager to run tests..."
    swift test
elif command -v xcodebuild &> /dev/null; then
    echo "Using xcodebuild to run tests..."
    xcodebuild -project TakeoverCLI.xcodeproj -scheme TakeoverCLI -enableCodeCoverage YES test
else
    echo "Error: Neither 'swift' nor 'xcodebuild' found in PATH"
    echo "Please ensure Xcode or Swift toolchain is installed"
    exit 1
fi

echo "Tests completed successfully!"