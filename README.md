# Observe iOS

Observe iOS is an iOS client for Observe — a server monitoring and observability platform. The app provides mobile-first access to server metrics, logs, alerts, and basic control actions so administrators and engineers can monitor and respond to incidents on the go.

This README describes the project purpose, how to build and run the app, configuration options, architecture overview, testing, and contribution guidelines.

Contents
- About
- Features
- Requirements
- Getting started
  - Clone
  - Build (Xcode / Swift Package Manager)
  - Configuration
- Usage
- Architecture & design
- Testing
- Contributing
- License
- Contact

About
Observe iOS aims to deliver a fast, focused experience for viewing server health and responding to alerts. It is designed to be a companion to an existing Observe backend (the server/API is out of scope for this client).

Features
- View realtime and historical metrics (CPU, memory, disk, network)
- Browse and search logs
- Receive and inspect alerts and their history
- Acknowledge or resolve alerts (API-dependent)
- Lightweight dashboards and charts
- Dark mode and accessibility support
- Offline caching for last-known-state
- Secure authentication and token handling

Requirements
- macOS with Xcode (recommend latest stable; minimum Xcode 14)
- iOS 15.0+ target (adjust in project if needed)
- Swift 5.7+ (project may use Swift Concurrency / Combine)
- Internet connection for backend API
- Optional: CocoaPods or Swift Package Manager depending on dependency setup

Getting started

1) Clone the repository
- SSH:
  git clone git@github.com:ObServe-Your-Server/observe-ios.git
- HTTPS:
  git clone https://github.com/ObServe-Your-Server/observe-ios.git

2) Open in Xcode (recommended)
- Open observe-ios.xcodeproj or observe-ios.xcworkspace (if using CocoaPods).
- Select the target device or simulator, then Build & Run (Cmd+R).

3) Build with Swift Package Manager
- If dependencies are configured as Swift packages, Xcode will resolve them automatically when opening the project.
- Alternatively:
  swift build

Configuration
The app requires configuration to point to your Observe backend. These include IP, Port, API-KEY. All of those mentioned are configured on Backend Setup.

Architecture & design
The project is structured to be modular and testable:
- Presentation: SwiftUI (or UIKit) views, following MVVM where view models expose state and inputs.
- Domain: Business logic and models isolated from UI.
- Networking: A small API client layer (URLSession or a networking library) handling authentication, requests, retries, and decoding.
- Persistence: Lightweight caching layer (Core Data, SQLite, or file-based cache) for offline viewing.
- Concurrency: Swift Concurrency (async/await) or Combine for reactive flows.
- Dependency injection to make components swappable for tests and different environments.

Coding conventions
- Follow Swift API Design Guidelines
- Keep view models small and testable
- Use Result types and structured error handling
- Localize user-facing strings

Contributing
- Open issues for bugs or feature requests.
- Create pull requests against the main branch; include a clear description and tests where applicable.

License
This project is distributed under the MIT License. See the LICENSE file for details.

Contact
For questions or support, open an issue on this repository or contact the maintainers via the repository communication channels.

Acknowledgements
- Built to be backend-agnostic and to complement server-side observability tooling.
