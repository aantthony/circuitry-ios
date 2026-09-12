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
