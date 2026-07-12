import Foundation

// MARK: - Stop Monitoring Response
extension Foli {
    /// Response from the stop monitoring endpoint
    struct ArrivalResponse: Codable, Sendable, Equatable, Hashable {
        // MARK: - Known Status Values

        /// Named constants for the well-known status strings returned by the stop monitoring endpoint.
        ///
        /// Unrecognized status strings decode as ``unknown(_:)`` instead of failing the
        /// whole response, so a new server-side status surfaces as a server error rather
        /// than an opaque decoding error.
        enum Status: RawRepresentable, Codable, Sendable, Equatable, Hashable {
            /// The request succeeded and `result` contains arrivals.
            case ok
            /// The backend has no SIRI data for this stop at the time of the request.
            case noData
            /// A status string this package version doesn't recognize.
            case unknown(String)

            var rawValue: String {
                switch self {
                case .ok: return "OK"
                case .noData: return "NO_SIRI_DATA"
                case .unknown(let value): return value
                }
            }

            init(rawValue: String) {
                switch rawValue {
                case "OK": self = .ok
                case "NO_SIRI_DATA": self = .noData
                default: self = .unknown(rawValue)
                }
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                self.init(rawValue: try container.decode(String.self))
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                try container.encode(rawValue)
            }
        }

        /// System identifier ("SM" for stop monitoring)
        let sys: String
        /// Status of the response
        let status: Status
        /// Unix timestamp when the response was generated
        let serverTime: TimeInterval
        /// Array of vehicle arrivals/departures in order of arrival
        let result: [Foli.Arrival]

        init(sys: String, status: Status, serverTime: TimeInterval, result: [Foli.Arrival]) {
            self.sys = sys
            self.status = status
            self.serverTime = serverTime
            self.result = result
        }

        private enum CodingKeys: String, CodingKey {
            case sys
            case status
            case serverTime = "servertime"
            case result
        }

        /// Computed property to check if the response is valid
        var isValid: Bool {
            status == .ok
        }

        /// Convert server time to Date
        var serverDate: Date {
            Date(timeIntervalSince1970: serverTime)
        }
    }
}
