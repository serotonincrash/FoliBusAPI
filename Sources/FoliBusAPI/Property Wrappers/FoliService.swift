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
    
    public init(client: FoliClient = .shared) {
        self.client = client
    }
    
    public var wrappedValue: FoliService {
        self
    }
}

