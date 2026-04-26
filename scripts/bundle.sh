#!/bin/bash
set -euo pipefail

# Build Thockspace and create .app bundle
# Usage: ./scripts/bundle.sh [release|debug]

CONFIG="${1:-debug}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
APP_NAME="Thockspace"
BUNDLE_DIR="$PROJECT_DIR/build/$APP_NAME.app"

echo "Building $APP_NAME ($CONFIG, universal)..."

BUILD_FLAGS=(--package-path "$PROJECT_DIR")
if [ "$CONFIG" = "release" ]; then
    BUILD_FLAGS+=(-c release)
fi

# Build for both architectures
swift build "${BUILD_FLAGS[@]}" --arch arm64 2>&1
swift build "${BUILD_FLAGS[@]}" --arch x86_64 2>&1

# Create universal binary
ARM_BINARY="$PROJECT_DIR/.build/arm64-apple-macosx/$CONFIG/$APP_NAME"
X86_BINARY="$PROJECT_DIR/.build/x86_64-apple-macosx/$CONFIG/$APP_NAME"
BINARY="$PROJECT_DIR/.build/$APP_NAME-universal"

lipo -create -output "$BINARY" "$ARM_BINARY" "$X86_BINARY"
echo "Universal binary: $(file "$BINARY")"

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

# Copy app icon
cp "$PROJECT_DIR/Thockspace/Resources/AppIcon.icns" "$BUNDLE_DIR/Contents/Resources/AppIcon.icns"

# Copy menu bar icon (template image — "Template" suffix = auto light/dark)
cp "$PROJECT_DIR/Thockspace/Resources/MenuBarIconTemplate.png" "$BUNDLE_DIR/Contents/Resources/MenuBarIconTemplate.png"
cp "$PROJECT_DIR/Thockspace/Resources/MenuBarIconTemplate@2x.png" "$BUNDLE_DIR/Contents/Resources/MenuBarIconTemplate@2x.png"

# Create PkgInfo
echo -n "APPL????" > "$BUNDLE_DIR/Contents/PkgInfo"

# Ad-hoc sign — avoids "damaged" error, becomes "unidentified developer" instead
# User only needs right-click → Open once
codesign --force --deep --sign - "$BUNDLE_DIR"
echo "Ad-hoc signed."

echo ""
echo "Bundle created at: $BUNDLE_DIR"
echo ""
echo "To run:"
echo "  open $BUNDLE_DIR"
echo ""
echo "To install:"
echo "  cp -r $BUNDLE_DIR /Applications/"
echo ""
echo "First launch on another Mac: right-click → Open"
