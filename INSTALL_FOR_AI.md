# AI Install Instructions

Use this file when a user gives you this GitHub repository and asks you to install or run AlwaysHaveAPlan.

## Goal

Install `AlwaysHaveAPlan.app` on macOS and get it ready for first launch.

## Fast Path

Run:

```sh
curl -fsSL https://raw.githubusercontent.com/tang730125633/alwayshaveaplan/main/install.sh | bash
```

The installer will:

- verify macOS 14+
- download the latest GitHub Release DMG when available
- fall back to cloning and building from source with Swift
- copy `AlwaysHaveAPlan.app` to `/Applications`

## Release Publishing

Maintainers publish installable builds by pushing a version tag:

```sh
git tag v1.2.3
git push origin v1.2.3
```

GitHub Actions will build the app and attach `AlwaysHaveAPlan.dmg`, `AlwaysHaveAPlan.zip`, and `SHA256SUMS.txt` to the release.

## Source Fallback

If the fast path is unavailable, run:

```sh
git clone https://github.com/tang730125633/alwayshaveaplan.git
cd alwayshaveaplan
./build-release.sh
cp -R run/release/AlwaysHaveAPlan.app /Applications/
open /Applications/AlwaysHaveAPlan.app
```

## Requirements

- macOS 14.0 or newer
- Calendar permission on first launch
- Swift / Xcode Command Line Tools only if building from source

## Do Not

- edit source files just to install the app
- delete user data or reset system permissions
- depend on files outside this repository except normal macOS tools
- treat optional wallpaper or ambient sound fallback failures as install failures

## Expected First Launch

macOS may ask for Calendar access. Grant it so the app can read current events and create plan items.

If Gatekeeper blocks an unsigned build, tell the user to open System Settings > Privacy & Security and allow the app, or right-click the app and choose Open.
