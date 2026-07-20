# Circuitry UI test harness

This target preserves the reliable parts of the full-game simulator run without
mixing UI automation into the existing unit-test target.

## What is retained

- Real XCUITest long-press-and-drag wiring gestures (no save-state mutation).
- Accessibility-snapshot port discovery, including exact snapped gate geometry.
- Named toolbelt selection and reusable one-, two-, and three-input gate placement.
- A non-destructive check that all 21 shipped problems are unlocked and visible.
- The final four-bit ripple-counter recipe, including the important Q-bar/startup ordering.

The exploratory reset-to-finish script was deliberately not retained verbatim. It
contained level-specific screen coordinates, disabled blocks from repeated reruns,
and diagnostic logging. New level recipes should use the helpers in
`CircuitryGameUITests.m` and connect fixed ports before placing objects over them.

## Running

Run the completion-state check:

```sh
xcodebuild test \
  -project Circuitry.xcodeproj \
  -scheme CircuitryUITests \
  -destination 'platform=iOS Simulator,name=iPad (A16)' \
  -only-testing:CircuitryUITests/CircuitryGameUITests/testCompletedProblemGridHasNoLockedCards \
  -parallel-testing-enabled NO
```

The counter recipe is opt-in because it edits that problem's canvas:

```sh
CIRCUITRY_RUN_COUNTER_RECIPE=YES xcodebuild test \
  -project Circuitry.xcodeproj \
  -scheme CircuitryUITests \
  -destination 'platform=iOS Simulator,name=iPad (A16)' \
  -only-testing:CircuitryUITests/CircuitryGameUITests/testBinaryCounterRecipe \
  -parallel-testing-enabled NO
```

Use a single, booted simulator and disable parallel testing. Simulator clones have
separate application containers, so their progress does not update the visible iPad.

## App Store screenshots

Generate the four App Store screenshots on the 13-inch iPad simulator:

```sh
./tools/generate-app-store-screenshots.sh
```

The script runs only `testGenerateAppStoreScreenshots`, exports its screenshot
attachments, and writes upload-ready PNG files to
`build/app-store-screenshots/`:

- `01-two-of-three.png`
- `02-guided-problem.png`
- `03-problems-overview.png`
- `04-binary-multiplier.png`

The test forces English, skips the first-launch tutorial, and unlocks the problem
list through launch-only defaults. It does not depend on a simulator's saved app
state and does not change the defaults used by a normal app launch.

The default destination is `iPad Pro 13-inch (M5)`. To use a differently named
13-inch simulator or output directory, set either variable before running:

```sh
CIRCUITRY_SCREENSHOT_DEVICE='iPad Air 13-inch (M4)' \
  CIRCUITRY_SCREENSHOT_OUTPUT="$PWD/build/store-assets" \
  ./tools/generate-app-store-screenshots.sh
```
