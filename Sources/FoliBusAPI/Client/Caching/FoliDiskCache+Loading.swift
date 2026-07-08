import Foundation

extension Foli.DiskCache {
    func cacheAge(for type: Foli.Resource) async -> TimeInterval? {
        guard let metadata = try? await loadMetadata(for: type) else {
            return nil
        }
        return Date().timeIntervalSince(metadata.cachedAt)
    }

    internal func loadResource<T: Codable & Sendable>(_ type: T.Type, forKey key: Foli.Resource) async throws -> T? {
        // Load the value first, then check freshness.  This avoids a reentrancy
        // race on the actor: between the old hasValidCache check and the subsequent
        // loadStaleResource call, clearCache(for:) could delete the file, causing
        // a spurious nil return (surfacing as .cacheMiss in .cachedOnly mode).
        guard let cached = try await loadStaleResource(type, forKey: key) else {
            return nil
        }

        guard let metadata = try? await loadMetadata(for: key), isMetadataFresh(metadata) else {
            return await hasValidCache(for: key) ? cached : nil
        }

        return cached
    }

    internal func loadStaleResource<T: Codable & Sendable>(_ type: T.Type, forKey key: Foli.Resource) async throws -> T? {
        let fileURL = try fileURL(for: key)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        let data = try Data(contentsOf: fileURL)
        let cachedData = try JSONDecoder().decode(CachedData<T>.self, from: data)
        return cachedData.data
    }
}
