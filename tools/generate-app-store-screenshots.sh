#!/bin/sh

set -eu

PROJECT_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
DEVICE_NAME=${CIRCUITRY_SCREENSHOT_DEVICE:-iPad Pro 13-inch (M5)}
OUTPUT_DIR=${CIRCUITRY_SCREENSHOT_OUTPUT:-$PROJECT_ROOT/build/app-store-screenshots}
RESULT_BUNDLE="$OUTPUT_DIR/CircuitryScreenshots.xcresult"
ATTACHMENTS_DIR="$OUTPUT_DIR/attachments"

mkdir -p "$OUTPUT_DIR"
rm -rf "$RESULT_BUNDLE" "$ATTACHMENTS_DIR"
find "$OUTPUT_DIR" -maxdepth 1 -type f -name '0[1-4]-*.png' -delete

cd "$PROJECT_ROOT"
xcodebuild test \
  -project Circuitry.xcodeproj \
  -scheme CircuitryUITests \
  -destination "platform=iOS Simulator,name=$DEVICE_NAME" \
  -only-testing:CircuitryUITests/CircuitryGameUITests/testGenerateAppStoreScreenshots \
  -parallel-testing-enabled NO \
  -resultBundlePath "$RESULT_BUNDLE"

xcrun xcresulttool export attachments \
  --path "$RESULT_BUNDLE" \
  --output-path "$ATTACHMENTS_DIR"

jq -r '.[] | .attachments[] | [.exportedFileName, .suggestedHumanReadableName] | @tsv' \
  "$ATTACHMENTS_DIR/manifest.json" |
while IFS="$(printf '\t')" read -r exported_file suggested_name; do
  case "$suggested_name" in
    0[1-4]-*)
      screenshot_name=${suggested_name%%_*}
      cp "$ATTACHMENTS_DIR/$exported_file" "$OUTPUT_DIR/$screenshot_name.png"
      ;;
  esac
done

COUNT=$(find "$OUTPUT_DIR" -maxdepth 1 -type f -name '0[1-4]-*.png' | wc -l | tr -d ' ')
if [ "$COUNT" -ne 4 ]; then
  echo "Expected 4 screenshots, but exported $COUNT. See $ATTACHMENTS_DIR/manifest.json." >&2
  exit 1
fi

echo "App Store screenshots written to $OUTPUT_DIR"
