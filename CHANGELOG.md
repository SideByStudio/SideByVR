# Changelog

English | [简体中文](CHANGELOG_zh.md)

## Unreleased — 0.1.0 preview

This version has not been published. Physical-device regression and clean-checkout build verification are pending.

### Added

- Standalone Android viewer for local side-by-side images and `.sbs.mp4` videos, with no account or cloud configuration required.
- Android folder picker, saved folder access, subfolder browsing and ZIP collections.
- Explicit opt-in for ordinary JPG/JPEG/PNG filenames, case-insensitive matching and filter-aware ZIP caching.
- Phone/VR menus, controller and keyboard navigation, zoom, positioning, eye separation and viewing preferences.
- In-app open-source notices, Apache-2.0 project code and original launcher artwork.

### Known limits

- Full-SBS left/right images only; no Half-SBS correction, eye swapping, top/bottom layout, JPS/MPO parsing or GIF selection.
- PNG split views use a JPEG intermediate; transparency and lossless output are not preserved.
- Video decoding depends on the Android device. Device playback, controller mappings and folder permission restoration still need hardware validation.
- Release signing and downloadable release artifacts are not configured. Existing local Debug APKs are development artifacts.

See [usage and format support](docs/usage.md) for exact behavior.
