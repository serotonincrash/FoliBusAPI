import Foundation

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
extension FoliClient {
    // MARK: - Request Helpers

    /// Constructs a full URL for a given SIRI endpoint path
    /// - Parameter path: The endpoint path (e.g., "/sm" or "/sm/4")
    /// - Returns: A complete URL
    internal func makeEndpointURL(path: String) throws -> URL {
        guard let url = URL(string: baseURL + path) else {
            throw Foli.APIError.invalidURL
        }
        return url
    }

    /// Constructs a full URL for a given GTFS endpoint path
    /// - Parameter path: The endpoint path (e.g., "/routes" or "/stops")
    /// - Returns: A complete URL
    internal func makeGTFSEndpointURL(path: String) throws -> URL {
        guard let url = URL(string: gtfsBaseURL + path) else {
            throw Foli.APIError.invalidURL
        }
        return url
    }

    /// Fetch and decode a response from a SIRI endpoint.
    internal func requestSIRI<T: Decodable>(_ path: String, as type: T.Type = T.self) async throws -> T {
        let url = try makeEndpointURL(path: path)
        return try await request(url, as: type)
    }

    /// Fetch and decode a response from a GTFS endpoint.
    internal func requestGTFS<T: Decodable>(_ path: String, as type: T.Type = T.self) async throws -> T {
        let url = try makeGTFSEndpointURL(path: path)
        return try await request(url, as: type)
    }

    private func request<T: Decodable>(_ url: URL, as type: T.Type) async throws -> T {
        do {
            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw Foli.APIError.invalidResponse
            }

            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw Foli.APIError.decodingError(error)
            }
        } catch let error as Foli.APIError {
            throw error
        } catch {
            throw Foli.APIError.networkError(error)
        }
    }
}
