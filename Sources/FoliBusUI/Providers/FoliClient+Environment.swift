import SwiftUI
import FoliBusAPI

// MARK: - SwiftUI Environment Support

/// SwiftUI environment integration for resolving configured ``FoliClient`` providers.
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
