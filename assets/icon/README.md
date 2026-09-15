# Launcher icon sources

`flutter_launcher_icons` (configured in `pubspec.yaml`) generates every
Android launcher icon density from these two files. They are **not** in the
repository yet; add them, then run:

```sh
dart run flutter_launcher_icons
```

| File | Size | Notes |
| --- | --- | --- |
| `app_icon.png` | 1024×1024 PNG | Legacy (pre-Android 8) icon. Full-bleed, no transparency needed. Also used for the Play Store listing's 512×512 icon if you export it. |
| `app_icon_foreground.png` | 1024×1024 PNG | Adaptive-icon foreground layer. Transparent background; keep the artwork inside the centre 66% (the outer ring is masked on most launchers). |

The adaptive-icon background is the solid colour `#1D113E` (the app's primary
dark purple, `AppColors.primaryDark`). Change `adaptive_icon_background` in
`pubspec.yaml` to use an image instead.

Do not run the generator before the images exist: it fails, and the default
Flutter icons in `android/app/src/main/res/mipmap-*` remain in place.
