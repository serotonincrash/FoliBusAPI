import Foundation

extension Foli.DiskCache {
    func cacheAge(for type: Foli.Resource) async -> TimeInterval? {
        guard let metadata = try? await loadMetadata(for: type) else {
            return nil
        }
        return Date().timeIntervalSince(metadata.cachedAt)
    }

    internal func loadResource<T: Codable & Sendable>(_ type: T.Type, forKey key: Foli.Resource) async throws -> T? {
        let fileURL = try fileURL(for: key)
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }

        let data = try Data(contentsOf: fileURL)
        let cachedData = try JSONDecoder().decode(CachedData<T>.self, from: data)

        let age = Date().timeIntervalSince(cachedData.metadata.cachedAt)
        if age <= timeoutDuration.validityDuration {
            return cachedData.data
        }

        // Stale — try revalidation via network; if that fails, return nil.
        do {
            return try await revalidateCache(for: key) ? cachedData.data : nil
        } catch {
            return nil
        }
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
