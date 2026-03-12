import SwiftUI

// MARK: - SwiftUI Environment Support

/// SwiftUI environment integration for resolving configured ``FoliClient`` providers.
@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
extension EnvironmentValues {

    /// The provider used by `FoliService` to resolve a `FoliClient`.
    /// Set this at your app's root to control caching behavior while preserving a reusable client instance:
    /// ```swift
    /// RootView().environment(
    ///     \.foliClientProvider,
    ///     DefaultFoliClientProvider(
    ///         configuration: FoliClientConfiguration(cacheBehavior: .forceRefresh)
    ///     )
    /// )
    /// ```
    public var foliClientProvider: any FoliClientProviding {
        get { self[FoliClientProviderKey.self] }
        set { self[FoliClientProviderKey.self] = newValue }
    }

    private struct FoliClientProviderKey: EnvironmentKey {
        static let defaultValue: any FoliClientProviding = DefaultFoliClientProvider()
    }
}
