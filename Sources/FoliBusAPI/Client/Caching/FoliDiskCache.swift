import Foundation

public extension Foli {
    /// File-based cache implementation for GTFS data.
    ///
    /// ``DiskCache`` is the package's default ``Foli/Cache`` implementation. It stores
    /// serialized data under the app support directory and uses actor isolation to keep
    /// file-system operations safe across concurrent access.
    actor DiskCache: Foli.Cache {
        internal let fileManager: FileManager
        internal let cacheDirectory: URL
        public let timeoutDuration: Foli.CacheTimeout
        internal let baseURL: String = "https://data.foli.fi/gtfs/v0"
        internal let session: URLSession

        /// Creates a disk-backed cache.
        /// - Parameters:
        ///   - timeout: The freshness policy applied to cached resources.
        ///   - fileManager: The file manager used to create and access cache files.
        public init(
            timeout: Foli.CacheTimeout = .default,
            fileManager: FileManager = .default
        ) throws {
            self.timeoutDuration = timeout
            self.fileManager = fileManager
            self.session = URLSession.shared

            let appSupportURL = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )

            self.cacheDirectory = appSupportURL
                .appendingPathComponent("FoliBusAPI", isDirectory: true)
                .appendingPathComponent("Cache", isDirectory: true)

            try fileManager.createDirectory(
                at: self.cacheDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
    }
}
