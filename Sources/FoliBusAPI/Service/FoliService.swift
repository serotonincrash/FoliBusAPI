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
/// This property wrapper resolves a `FoliClient` either from an explicit client override
/// or from the SwiftUI environment's configured provider.
///
/// ## Usage
///
/// Set the provider at your app's root:
/// ```swift
/// @main
/// struct MyApp: App {
///     var body: some Scene {
///         WindowGroup {
///             ContentView()
///                 .environment(
///                     \.foliClientProvider,
///                     DefaultFoliClientProvider(
///                         configuration: FoliClientConfiguration(cacheBehavior: .forceRefresh)
///                     )
///                 )
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
/// let customClient = FoliClient(cacheBehavior: .noCache)
/// @FoliService(client: customClient) var foliService
/// ```
@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
@propertyWrapper
public struct FoliService: DynamicProperty, Sendable {
    
    /// The injected custom client, if provided directly
    internal let explicitClient: FoliClient?
    
    /// The client provider from the SwiftUI environment
    @Environment(\.foliClientProvider) private var clientProvider
    
    /// Creates a service wrapper backed by an explicit client instance.
    /// - Parameter client: The client to use for service operations.
    public init(client: FoliClient) {
        self.explicitClient = client
    }
    
    /// Creates a service wrapper that resolves its client from the SwiftUI environment.
    public init() {
        self.explicitClient = nil
    }
    
    /// The FoliClient to use for service operations
    /// Returns the explicit client, then the environment provider's client
    internal var client: FoliClient {
        explicitClient ?? clientProvider.client()
    }
    
    /// The property-wrapper value exposed to the enclosing view.
    public var wrappedValue: FoliService {
        self
    }
}
