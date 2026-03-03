//
//  FoliService.swift
//  FoliBusAPI
//
//  Created by sero on 26/2/26.
//

import SwiftUI

// MARK: - FoliService Property Wrapper

/// A property wrapper that provides a service interface for fetching Foli transit data
/// with async methods for manual state management.
@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
@propertyWrapper
public struct FoliService: DynamicProperty, Sendable {
    
    internal let client: FoliClient
    
    /// Initialize with a custom client
    public init(client: FoliClient) {
        self.client = client
    }
    
    /// Initialize using the shared singleton instance
    /// - Important: Call `FoliClient.configure()` before using this initializer to customize cache settings
    public init() async {
        self.client = await FoliClient.shared
    }
    
    public var wrappedValue: FoliService {
        self
    }
}

