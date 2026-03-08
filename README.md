# Ferry Services iOS

Native iOS app for checking Scottish ferry service status, disruptions, and route details.

## Overview

The app displays ferry routes and real-time service information from the Scottish Ferries backend API, with support for:

- Service status and disruption indicators
- Route details and additional service information
- Push notification preferences per installation
- In-app map and web information screens

## Tech Stack

- SwiftUI
- Swift 6.0
- Xcode project + workspace
- Sentry (via Swift Package Manager)

## Requirements

- Xcode with Swift 6 support
- iOS deployment target configured in project: `26.0`

## Getting Started

1. Clone the repository.
2. Open `FerryServices_2.xcworkspace` in Xcode.
3. Select the `FerryServices_2` scheme.
4. Build and run on a simulator or device.

## Command Line Build & Test

Build:

```bash
xcodebuild \
  -workspace FerryServices_2.xcworkspace \
  -scheme FerryServices_2 \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  build
```

Test:

```bash
xcodebuild \
  -workspace FerryServices_2.xcworkspace \
  -scheme FerryServices_2 \
  -destination 'generic/platform=iOS Simulator' \
  test
```

## Project Structure

- `FerryServices_2/` app source code (views, models, API client, assets)
- `FerryServices_2Tests/` unit tests
- `FerryServices_2.xcodeproj/` project configuration
- `FerryServices_2.xcworkspace/` workspace and shared scheme
- `Licenses/` license artifacts

## API

The app currently targets:

- `https://scottishferryapp.com/api`

See `FerryServices_2/API Client/APIClient.swift` for endpoint usage.
