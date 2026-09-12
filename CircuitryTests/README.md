# Simulation regression tests

Run the standalone C tests from the repository root on macOS. They exercise
signal propagation, wire and simulation-queue growth, and circuit cleanup with
AddressSanitizer and UndefinedBehaviorSanitizer. Small initial capacities force
the same growth paths used by large circuits without creating 100,000 gates.

```sh
clang -g -fsanitize=address,undefined \
  -I Circuitry/CircuitInternal \
  CircuitryTests/CircuitInternalRegressionTests.c \
  Circuitry/CircuitInternal/CircuitInternal.c \
  -o /tmp/circuitry-regression-tests
/tmp/circuitry-regression-tests
```

These tests run independently of the Xcode unit and UI test targets.

## Progress and thumbnail tests

The XCTest suite checks migration of legacy progress (including the old `999`
unlock flag), unlocking without granting completion, reset, persistence, and
adding/reordering levels. It also captures the ALU card with the editor renderer.
Use a simulator test host matching the current app product name:

```sh
xcodebuild test -project Circuitry.xcodeproj -scheme Circuitry \
  -destination 'platform=iOS Simulator,name=iPad (A16)' \
  -parallel-testing-enabled NO \
  'TEST_HOST=$(BUILT_PRODUCTS_DIR)/Circuitry.app/Circuitry' \
  -resultBundlePath build/ProgressTests.xcresult
xcrun xcresulttool export attachments \
  --path build/ProgressTests.xcresult --output-path build/ProgressAttachments
```

The `level-024` attachment is the source for the ALU thumbnail asset.
