# sip

A menu bar water reminder for macOS.

## Features

- Set a reminder interval and get notified to drink water
- Silent mode for notifications without sound
- Auto pauses when you're idle
- Auto pauses while Stremio is open, resumes a bit after you switch away

## Install

Download `sip.zip` from the [latest release](https://github.com/arajenk/sip/releases/latest), unzip it, and move `sip.app` to Applications.

The app isn't notarized, so on first launch right click `sip.app` and choose Open, then confirm.

sip needs Accessibility permission to detect idle time. You'll get a system prompt for this the first time you start a timer, grant it in System Settings under Privacy & Security.

## Build from source

Open `sip.xcodeproj` in Xcode and build the `sip` scheme.
