#!/bin/bash

# Script to increment version and build APK or App Bundle
# Usage: ./build_apk.sh [apk|bundle]
# Build APK with version increment
#./build_apk.sh apk

# Build App Bundle with version increment  
#./build_apk.sh bundle

# Default (builds APK)
#./build_apk.sh
# Default: apk

set -e  # Exit on any error

# Parse command line arguments
BUILD_TYPE="apk"  # Default to APK

if [ $# -gt 0 ]; then
    case "$1" in
        "apk"|"APK")
            BUILD_TYPE="apk"
            ;;
        "bundle"|"appbundle"|"BUNDLE"|"APPBUNDLE")
            BUILD_TYPE="appbundle"
            ;;
        *)
            echo "❌ Error: Invalid build type '$1'"
            echo "Usage: $0 [apk|bundle]"
            echo "  apk     - Build APK (default)"
            echo "  bundle  - Build App Bundle"
            exit 1
            ;;
    esac
fi

echo "🚀 Starting build process..."
echo "📦 Build type: $BUILD_TYPE"

# Get the current directory (should be the project root)
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PUBSPEC_FILE="$PROJECT_DIR/pubspec.yaml"

# Check if pubspec.yaml exists
if [ ! -f "$PUBSPEC_FILE" ]; then
    echo "❌ Error: pubspec.yaml not found in $PROJECT_DIR"
    exit 1
fi

# Extract current version from pubspec.yaml
echo "📖 Reading current version from pubspec.yaml..."
CURRENT_VERSION=$(grep "^version:" "$PUBSPEC_FILE" | sed 's/version: *//' | tr -d ' ')

if [ -z "$CURRENT_VERSION" ]; then
    echo "❌ Error: Could not find version in pubspec.yaml"
    exit 1
fi

echo "📋 Current version: $CURRENT_VERSION"

# Parse version and build number
# Format: major.minor.patch+build
VERSION_PART=$(echo "$CURRENT_VERSION" | cut -d'+' -f1)
BUILD_NUMBER=$(echo "$CURRENT_VERSION" | cut -d'+' -f2)

# Check if build number exists
if [ "$BUILD_NUMBER" = "$CURRENT_VERSION" ]; then
    echo "⚠️  No build number found, adding +1"
    BUILD_NUMBER=1
    # If no build number, just increment patch version
    MAJOR=$(echo "$VERSION_PART" | cut -d'.' -f1)
    MINOR=$(echo "$VERSION_PART" | cut -d'.' -f2)
    PATCH=$(echo "$VERSION_PART" | cut -d'.' -f3)
    PATCH=$((PATCH + 1))
    VERSION_PART="$MAJOR.$MINOR.$PATCH"
else
    # Increment both patch version and build number
    MAJOR=$(echo "$VERSION_PART" | cut -d'.' -f1)
    MINOR=$(echo "$VERSION_PART" | cut -d'.' -f2)
    PATCH=$(echo "$VERSION_PART" | cut -d'.' -f3)
    PATCH=$((PATCH + 1))
    BUILD_NUMBER=$((BUILD_NUMBER + 1))
    VERSION_PART="$MAJOR.$MINOR.$PATCH"
fi

# Create new version
NEW_VERSION="$VERSION_PART+$BUILD_NUMBER"

echo "🔄 Incrementing patch version and build number..."
echo "📋 New version: $NEW_VERSION"

# Update pubspec.yaml with new version
echo "✏️  Updating pubspec.yaml..."
sed -i.bak "s/^version: .*/version: $NEW_VERSION/" "$PUBSPEC_FILE"

# Remove backup file
rm -f "$PUBSPEC_FILE.bak"

echo "✅ Version updated successfully!"

# Build APK or App Bundle using fvm flutter
if [ "$BUILD_TYPE" = "apk" ]; then
    echo "🔨 Building APK with fvm flutter build apk..."
    BUILD_COMMAND="fvm flutter build apk"
    OUTPUT_PATH="build/app/outputs/flutter-apk/app-release.apk"
else
    echo "🔨 Building App Bundle with fvm flutter build appbundle..."
    BUILD_COMMAND="fvm flutter build appbundle"
    OUTPUT_PATH="build/app/outputs/bundle/release/app-release.aab"
fi

cd "$PROJECT_DIR"

# Check if fvm is available
if ! command -v fvm &> /dev/null; then
    echo "❌ Error: fvm is not installed or not in PATH"
    echo "Please install fvm or use regular flutter command"
    exit 1
fi

# Build the APK or App Bundle
$BUILD_COMMAND

if [ $? -eq 0 ]; then
    if [ "$BUILD_TYPE" = "apk" ]; then
        echo "🎉 APK built successfully!"
        echo "📱 APK location: $OUTPUT_PATH"
    else
        echo "🎉 App Bundle built successfully!"
        echo "📱 App Bundle location: $OUTPUT_PATH"
    fi
    echo "📋 New version: $NEW_VERSION"
else
    echo "❌ Error: $BUILD_TYPE build failed"
    exit 1
fi
