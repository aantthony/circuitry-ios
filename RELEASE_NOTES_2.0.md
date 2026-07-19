# Circuitry 2.0 — Release Notes

**Version:** 2.0 (build 301)
**Compared against:** `master` (1.1.x)

Circuitry 2.0 is a major modernization of the app. The circuit canvas has been
rebuilt on SpriteKit, the legacy OpenGL renderer is gone, the build and app
lifecycle are brought up to current iOS standards, and a series of memory-safety
and document-loading fixes make the simulator considerably more robust. The
release also adds a hint system, expands the playground, and ships a redesigned
website.

## Highlights

- **New SpriteKit rendering engine.** The circuit canvas is now drawn with
  SpriteKit and the old OpenGL renderer has been removed entirely. Scene updates
  are incremental — only the wires, gates, and notes that actually changed are
  rebuilt, rather than tearing down and recreating the whole scene on every
  frame. This is a large performance win for clocked circuits.
- **Hint system.** Problems can now provide step-by-step hints. A Hint button in
  the problem view reveals numbered hints one at a time and tracks your progress.
- **Resizable canvas notes.** Notes on the canvas can be added and resized
  directly.
- **Modernized build and lifecycle.** The project adopts current Xcode build
  tooling, manual version/build-number settings, and the UIScene app lifecycle.
- **Redesigned website.** A new marketing site (`index.html`, `legal.html`,
  styles, and imagery) replaces the old tooling-driven site.

## New Features & Improvements

### Rendering
- Migrated the circuit canvas to SpriteKit and removed the legacy OpenGL
  renderer.
- Incremental scene updates: per-item group nodes keyed by identity are rebuilt
  only when their fingerprint (position, state, connectivity, editing status)
  changes; removed items are pruned. In-progress editing links and attach
  highlights are redrawn each pass in their own layers.
- A single shared `CIContext` is reused for the tinted LED images at startup
  instead of creating one per image.
- Restored seven-segment display rendering.
- Modernized viewport rendering.

### Simulation & Clocks
- The SpriteKit scene stays active for clocked circuits: clock detection in the
  editor keeps elapsed-time-driven clock transitions running while the editor is
  otherwise paused, and pauses fully only for clockless circuits.
- Support for `acceptedSpecs` in circuit tests — a test can now accept
  alternative correct output specifications, with detailed failure messages when
  none match. Backwards compatible: tests without `acceptedSpecs` behave as
  before.

### Content & UI
- Expanded playground components and fixed canvas layout.
- Improved intro/tutorial layouts with dynamic, programmatic sizing for
  different screen sizes; centralized nav-bar styling via `StyleManager` with
  iOS 13+ `UINavigationBarAppearance`.
- Improved problem wording.
- Centered unlocked-object modal content.
- Polished Mac (Catalyst) appearance, fixed Mac title contrast, and added a
  source link.

## Bug Fixes

### Memory safety (CircuitInternal)
- Fixed a fixed-size 512-entry clocks array that could be written past its end
  during long editing sessions; the array now grows on demand and removed
  objects vacate their slot.
- Fixed several latent buffer-growth bugs (verified with an ASan harness):
  `realloc` called on the address of a struct field instead of the buffer it
  points to; a link target assigned from its source, leaving `clocks[]` and the
  pending-update queue dangling after relocation; relocation offsets added to
  NULL inlet/outlet/sibling slots turning them into dangling non-NULL pointers.
- `CircuitLinkCreate` consistency checks now run in all build configurations
  (previously compiled out in DEBUG).

### Document loading & export
- Hardened document loading and export against malformed packages:
  - Validate that `hints` is an array before use (a non-array value crashed the
    problem view when the Hint button was tapped).
  - Items without a `name` key no longer dereference NULL during load; names are
    copied with `strlcpy`, guaranteeing NUL termination and preventing reads
    past the fixed name buffer.
  - Export no longer throws during autosave for imported packages missing
    optional fields (per-test names/specs, title, author, license, description,
    version, meta), which previously lost the user's edits.
- Discard saved links to outlets that no longer exist: out-of-range source
  outlets, out-of-range target inlets, and duplicate inlet attachments are
  silently dropped during load instead of exiting the app in release builds.
  This recovers documents saved before the d4 register's output count was
  reduced from 8 to 4.
- Handle invalid circuit object types gracefully.

### Interaction
- Push-button taps must now hit the round cap; taps near the output terminal no
  longer spuriously clock downstream flip-flops and counters.
- Fixed terminal touch hit regions.
- Fixed push-button z-ordering.
- Fixed the 4-bit register output count.
- Fixed a crash when exiting the playground.
- Aligned the tutorial arrow with the check button.

## Housekeeping & Platform

- Modernized the iOS build; the atlas is generated with Xcode's Swift toolchain
  (`GenerateAtlas.swift`) — no CocoaPods, Node.js, or ImageMagick required.
- Manual Xcode build versioning via `MARKETING_VERSION` and
  `CURRENT_PROJECT_VERSION`.
- Adopted the UIScene lifecycle; aligned deployment and export settings.
- Removed the legacy URL scheme and obsolete plist keys.
- Modernized App Store metadata.
- Disabled dark mode (light appearance only, for consistent rendering).
- Fixed generated atlas sprite orientation.
- Fixed assorted Xcode and runtime layout warnings.
- Added a redesigned Circuitry website and a retained UI test harness.
- Prompt the user to rate the app on the App Store.

## Notes for Developers

- The OpenGL rendering path has been removed; SpriteKit is now the only
  renderer.
- Increment `CURRENT_PROJECT_VERSION` before uploading a new release build.
