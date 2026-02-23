# FoliBusAPI

A native Swift package for accessing the Foli (Turku Region Public Transport) real-time public transport API.

## Overview

FoliBusAPI provides a clean, modern Swift interface for accessing:
- Real-time stop monitoring (bus/train arrivals and departures)
- Complete stop list with searchable data
- Vehicle tracking with real-time GPS coordinates
- Delay and schedule information

## Requirements

- iOS 15.0+ / macOS 12.0+ / watchOS 8.0+ / tvOS 15.0+
- Swift 6.0+
- Xcode 16.0+

## Installation

### Swift Package Manager

Add FoliBusAPI to your `Package.swift`:

```swift
dependencies: [
    .package(
        url: "https://github.com/yourusername/FoliBusAPI.git",
        from: "1.0.0"
    )
]
