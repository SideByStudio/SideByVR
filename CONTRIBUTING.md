# Contributing

English | [简体中文](CONTRIBUTING_zh.md)

SideByVR Viewer is an Android app for viewing existing local SBS media. Keep contributions focused on browsing, stereo presentation, input, accessibility, performance and tests.

## Development

Use the SDK versions and commands in the README. Work on a feature or fix branch, keep changes focused, and run `flutter analyze` and relevant `flutter test` checks. Android native changes also need an Android build. Describe the behavior changed and distinguish automated testing from physical-device testing.

## Contributions and licensing

Contributions intentionally submitted for inclusion are provided under Apache-2.0 unless explicitly stated otherwise, consistent with section 5 of that license. Contributors retain their copyright; submitting a contribution does not transfer ownership or grant a special proprietary relicensing agreement.

Submit only code and resources you have permission to contribute. Preserve upstream copyright and attribution notices. Identify copied or adapted third-party code, its exact source/version and license in the contribution. Update `THIRD_PARTY_NOTICES.md` and supplemental bundled notices for new or changed dependencies or resources.

Do not include credentials, signing keys, private media, user records or third-party decompiled code. Use synthetic or clearly licensed test media. Keep hosted account, billing and generation services out of this viewer repository.

## Dependency updates

Review the locked Dart packages, Flutter SDK and resolved Android dependency graph. Update supplemental in-app notices and THIRD_PARTY_NOTICES.md together, and provide upstream source/version/license references in the change description. Maintainers keep the full evidence inventory separately. A new package-level license does not replace bundled third-party notices. Review differences before updating the snapshot, and verify the resulting APK still contains all required notice text.
