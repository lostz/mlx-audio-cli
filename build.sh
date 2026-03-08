#!/bin/bash
set -e

METAL_DIR=".build/checkouts/mlx-swift/Source/Cmlx/mlx-generated/metal"
BINARY_DIR=".build/release"
METALLIB="$BINARY_DIR/mlx.metallib"

build_swift() {
    echo "Building Swift package (clean)..."
    swift package clean
    swift build -c release
}

build_metal() {
    echo "Compiling Metal shaders..."
    TMPDIR_METAL=$(mktemp -d)
    trap "rm -rf $TMPDIR_METAL" EXIT

    for metal_file in $(find "$METAL_DIR" -name "*.metal"); do
        air_file="$TMPDIR_METAL/$(basename "${metal_file%.metal}").air"
        xcrun metal -I "$METAL_DIR" -c "$metal_file" -o "$air_file"
    done

    xcrun metallib "$TMPDIR_METAL"/*.air -o "$METALLIB"
    echo "Metal library created: $METALLIB ($(du -sh $METALLIB | cut -f1))"
}

# Parse args: --metal-only skips Swift build
if [ "$1" = "--metal-only" ]; then
    build_metal
else
    build_swift
    build_metal
fi

echo ""
echo "Done. Distribute these two files together:"
echo "  $BINARY_DIR/mlx-audio-cli"
echo "  $METALLIB"
