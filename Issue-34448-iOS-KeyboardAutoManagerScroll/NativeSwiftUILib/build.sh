#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FRAMEWORK_NAME="NativeSwiftUILib"
SWIFT_SOURCE="$SCRIPT_DIR/SwiftUITextFieldView.swift"
BUILD_DIR="$SCRIPT_DIR/build"
OUTPUT_DIR="$SCRIPT_DIR/../iOSIssue/iOSIssue/Frameworks"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/device" "$BUILD_DIR/simulator"

IPHONEOS_SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
IPHONESIM_SDK="$(xcrun --sdk iphonesimulator --show-sdk-path)"

echo "Building for iOS device (arm64)..."
xcrun --sdk iphoneos swiftc \
    -emit-library \
    -emit-module \
    -emit-module-interface \
    -emit-objc-header \
    -emit-objc-header-path "$BUILD_DIR/device/$FRAMEWORK_NAME-Swift.h" \
    -enable-library-evolution \
    -module-name "$FRAMEWORK_NAME" \
    -target arm64-apple-ios15.0 \
    -sdk "$IPHONEOS_SDK" \
    -Xlinker -install_name -Xlinker "@rpath/$FRAMEWORK_NAME.framework/$FRAMEWORK_NAME" \
    "$SWIFT_SOURCE" \
    -o "$BUILD_DIR/device/lib$FRAMEWORK_NAME.dylib"

echo "Building for iOS simulator (arm64)..."
xcrun --sdk iphonesimulator swiftc \
    -emit-library \
    -emit-module \
    -emit-module-interface \
    -emit-objc-header \
    -emit-objc-header-path "$BUILD_DIR/simulator/$FRAMEWORK_NAME-Swift.h" \
    -enable-library-evolution \
    -module-name "$FRAMEWORK_NAME" \
    -target arm64-apple-ios15.0-simulator \
    -sdk "$IPHONESIM_SDK" \
    -Xlinker -install_name -Xlinker "@rpath/$FRAMEWORK_NAME.framework/$FRAMEWORK_NAME" \
    "$SWIFT_SOURCE" \
    -o "$BUILD_DIR/simulator/lib$FRAMEWORK_NAME.dylib"

# Create .framework bundles for each slice
for ARCH in device simulator; do
    FW_DIR="$BUILD_DIR/$ARCH/$FRAMEWORK_NAME.framework"
    mkdir -p "$FW_DIR/Modules/$FRAMEWORK_NAME.swiftmodule"
    cp "$BUILD_DIR/$ARCH/lib$FRAMEWORK_NAME.dylib" "$FW_DIR/$FRAMEWORK_NAME"
    # Fix the dylib ID
    install_name_tool -id "@rpath/$FRAMEWORK_NAME.framework/$FRAMEWORK_NAME" "$FW_DIR/$FRAMEWORK_NAME"
    # Copy module files (swiftmodule, swiftdoc, swiftinterface, abi.json)
    for EXT in swiftmodule swiftdoc swiftinterface abi.json; do
        if [ -f "$BUILD_DIR/$ARCH/$FRAMEWORK_NAME.$EXT" ]; then
            cp "$BUILD_DIR/$ARCH/$FRAMEWORK_NAME.$EXT" "$FW_DIR/Modules/$FRAMEWORK_NAME.swiftmodule/"
        fi
    done
    cp "$BUILD_DIR/$ARCH/$FRAMEWORK_NAME-Swift.h" "$FW_DIR/Headers/" 2>/dev/null || {
        mkdir -p "$FW_DIR/Headers"
        cp "$BUILD_DIR/$ARCH/$FRAMEWORK_NAME-Swift.h" "$FW_DIR/Headers/"
    }
    # Create module.modulemap
    cat > "$FW_DIR/Modules/module.modulemap" <<MODULEMAP
framework module $FRAMEWORK_NAME {
    header "$FRAMEWORK_NAME-Swift.h"
    requires objc
}
MODULEMAP
    # Create Info.plist
    cat > "$FW_DIR/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$FRAMEWORK_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.repro.$FRAMEWORK_NAME</string>
    <key>CFBundleName</key>
    <string>$FRAMEWORK_NAME</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
</dict>
</plist>
PLIST
done

# Create XCFramework
mkdir -p "$OUTPUT_DIR"
rm -rf "$OUTPUT_DIR/$FRAMEWORK_NAME.xcframework"
xcodebuild -create-xcframework \
    -framework "$BUILD_DIR/device/$FRAMEWORK_NAME.framework" \
    -framework "$BUILD_DIR/simulator/$FRAMEWORK_NAME.framework" \
    -output "$OUTPUT_DIR/$FRAMEWORK_NAME.xcframework"

rm -rf "$BUILD_DIR"
echo "XCFramework created at $OUTPUT_DIR/$FRAMEWORK_NAME.xcframework"
