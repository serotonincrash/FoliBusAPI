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
///
/// This property wrapper requires a `FoliClient` to be provided either explicitly
/// or via the SwiftUI environment.
///
/// ## Usage
///
/// Set the client at your app's root:
/// ```swift
/// @main
/// struct MyApp: App {
///     var body: any Scene {
///         WindowGroup {
///             ContentView()
///                 .environment(\.foliClient, .configured(cacheBehavior: .forceRefresh))
///         }
///     }
/// }
/// ```
///
/// Then use it in your views:
/// ```swift
/// struct MyView: View {
///     @FoliService var foliService
///
///     var body: some View { ... }
/// }
/// ```
///
/// Or inject a custom client directly:
/// ```swift
/// let customClient = FoliClient(cachedBy: .noCache)
/// @FoliService(client: customClient) var foliService
/// ```
@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
@propertyWrapper
public struct FoliService: DynamicProperty, Sendable {
    
    /// The injected custom client, if provided directly
    internal let explicitClient: FoliClient?
    
    /// The client from the SwiftUI environment, if set
    @Environment(\.foliClient) private var environmentClient
    
    /// Initialize with a custom client
    /// - Parameter client: A custom FoliClient instance to use
    public init(client: FoliClient) {
        self.explicitClient = client
    }
    
    /// Initialize using the environment client
    ///
    /// This initializer requires that `\.foliClient` be set in the SwiftUI environment.
    /// Set it at your app's root:
    /// ```swift
    /// ContentView().environment(\.foliClient, .configured(cacheBehavior: .forceRefresh))
    /// ```
    public init() {
        self.explicitClient = nil
    }
    
    /// The FoliClient to use for service operations
    /// Returns the explicit client, then the environment client
    internal var client: FoliClient {
        if let explicit = explicitClient {
            return explicit
        }
        guard let environment = environmentClient else {
            fatalError(
                """
                FoliService requires a FoliClient injected into it. Set it via the environment:
                
                .environment(\\.foliClient, .configured(cacheBehavior: .cachedOrFetch))
                
                Or pass it explicitly:
                
                @FoliService(client: myClient) var foliService
                """
            )
        }
        return environment
    }
    
    public var wrappedValue: FoliService {
        self
    }
}

