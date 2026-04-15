#!/bin/bash
set -euo pipefail

# Build Thockspace and create .app bundle
# Usage: ./scripts/bundle.sh [release|debug]

CONFIG="${1:-debug}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
APP_NAME="Thockspace"
BUNDLE_DIR="$PROJECT_DIR/build/$APP_NAME.app"

echo "Building $APP_NAME ($CONFIG)..."

if [ "$CONFIG" = "release" ]; then
    swift build -c release --package-path "$PROJECT_DIR" 2>&1
    BINARY="$PROJECT_DIR/.build/release/$APP_NAME"
else
    swift build --package-path "$PROJECT_DIR" 2>&1
    BINARY="$PROJECT_DIR/.build/debug/$APP_NAME"
fi

echo "Creating app bundle..."

# Clean previous bundle
rm -rf "$BUNDLE_DIR"

# Create bundle structure
mkdir -p "$BUNDLE_DIR/Contents/MacOS"
mkdir -p "$BUNDLE_DIR/Contents/Resources"

# Copy binary
cp "$BINARY" "$BUNDLE_DIR/Contents/MacOS/$APP_NAME"

# Copy Info.plist
cp "$PROJECT_DIR/Thockspace/Info.plist" "$BUNDLE_DIR/Contents/Info.plist"

# Copy sound resources
cp -r "$PROJECT_DIR/Thockspace/Resources/sounds" "$BUNDLE_DIR/Contents/Resources/sounds"

# Create PkgInfo
echo -n "APPL????" > "$BUNDLE_DIR/Contents/PkgInfo"

echo "Bundle created at: $BUNDLE_DIR"
echo ""
echo "To run:"
echo "  open $BUNDLE_DIR"
echo ""
echo "To install:"
echo "  cp -r $BUNDLE_DIR /Applications/"
