# Contributing

Thanks for considering a contribution to HorizonLens HUD for iPhone.

## Development Setup

1. Open `HUD2.xcodeproj` in Xcode.
2. Select the `HUD2` scheme.
3. Set your own signing team and bundle identifier in Xcode.
4. Prefer testing on a physical iPhone because the app depends on camera, location, motion, barometer, microphone, Photos, and ReplayKit.

## Code Guidelines

- Keep SwiftUI views focused and move sensor or platform behavior into service objects.
- Keep HUD widgets small, composable, and easy to enable or disable from settings.
- Avoid committing personal Xcode state, derived data, archives, exported videos, CSV logs, or local backups.
- When changing sensor math, document the coordinate convention and verify behavior in portrait and landscape modes.
- When adding user-facing strings, update both Chinese and English text where applicable.

## Testing

Before opening a pull request, run at least:

```sh
xcodebuild -project HUD2.xcodeproj -scheme HUD2 -destination 'generic/platform=iOS Simulator' build
```

For sensor, camera, recording, and Photos behavior, also test on a physical iPhone.
