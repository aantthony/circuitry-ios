Circuitry
=========

Open `Circuitry.xcodeproj` in Xcode and build the `Circuitry` scheme.

The build uses Xcode's Swift toolchain to generate the circuit texture atlas from
`Circuitry/circuit.image-atlas`. It does not require CocoaPods, Node.js, or
ImageMagick.

Version numbers are managed with Xcode build settings:
`MARKETING_VERSION` for the user-facing version and `CURRENT_PROJECT_VERSION`
for the build number. Increment `CURRENT_PROJECT_VERSION` before uploading a new
release build.
