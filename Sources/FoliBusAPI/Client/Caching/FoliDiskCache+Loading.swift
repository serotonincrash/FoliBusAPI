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
        let cachedData: CachedData<T>
        do {
            cachedData = try JSONDecoder().decode(CachedData<T>.self, from: data)
        } catch is DecodingError {
            // Corrupt or schema-evolved entry: treat as a miss and remove the file so
            // the next fetch re-populates it, instead of failing every load until a
            // manual clearCache(). I/O errors above still throw — a read failure does
            // not prove the content is bad.
            try? fileManager.removeItem(at: fileURL)
            return nil
        }

        let age = Date().timeIntervalSince(cachedData.metadata.cachedAt)
        if age <= timeoutDuration.validityDuration {
            return cachedData.data
        }

        // Stale — try revalidation via network.
        do {
            let cacheStillCurrent = try await revalidateCache(for: key)
            // Definitively `false`: revalidation *reached* the server and confirmed the
            // dataset changed, so the entry really is out of date — the caller should
            // fetch fresh, not receive stale data disguised as current.
            return cacheStillCurrent ? cachedData.data : nil
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            // Inconclusive (a transient network/decoding error, not a definitive
            // "changed" answer): serve the stale entry rather than forcing every
            // caller to handle a network hiccup, matching `hasValidCache`'s policy.
            return cachedData.data
        }
    }

    internal func loadStaleResource<T: Codable & Sendable>(_ type: T.Type, forKey key: Foli.Resource) async throws -> T? {
        let fileURL = try fileURL(for: key)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        let data = try Data(contentsOf: fileURL)
        do {
            return try JSONDecoder().decode(CachedData<T>.self, from: data).data
        } catch is DecodingError {
            // Same self-healing policy as loadResource.
            try? fileManager.removeItem(at: fileURL)
            return nil
        }
    }
}
