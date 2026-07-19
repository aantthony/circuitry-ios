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
