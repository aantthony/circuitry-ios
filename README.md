Circuitry
=========

Circuitry is free and open source. You can build and run it yourself for free,
including at school or work. Buying the official app from the Apple App Store
supports its continued development and provides convenient installation and
updates.

## Building

Open `Circuitry.xcodeproj` in Xcode and build the `Circuitry` scheme.

The build uses Xcode's Swift toolchain to generate the circuit texture atlas from
`Circuitry/circuit.image-atlas`. It does not require CocoaPods, Node.js, or
ImageMagick.

Version numbers are managed with Xcode build settings:
`MARKETING_VERSION` for the user-facing version and `CURRENT_PROJECT_VERSION`
for the build number. Increment `CURRENT_PROJECT_VERSION` before uploading a new
release build.

## Licence

Copyright Anthony Foster and contributors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this work except in compliance with the License.
You may obtain a copy of the License in [LICENSE](LICENSE) or at
<https://www.apache.org/licenses/LICENSE-2.0>.

Unless required by applicable law or agreed to in writing, this work is
distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
either express or implied. See the License for the specific language governing
permissions and limitations under the License.

This applies to the code, documentation, and project-owned artwork and bundled
educational problems. Third-party materials retain their own terms and
attributions. See [BRAND_AND_ASSETS.md](BRAND_AND_ASSETS.md) for scope and use of
the Circuitry name and logo.
