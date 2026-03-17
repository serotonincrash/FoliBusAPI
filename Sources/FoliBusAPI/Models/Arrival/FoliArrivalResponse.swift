import Foundation

// MARK: - Stop Monitoring Response
public extension Foli {
    /// Response from the stop monitoring endpoint
    struct ArrivalResponse: Codable, Sendable {
        // MARK: - Known Status Values

        /// Named constants for the well-known status strings returned by the stop monitoring endpoint.
        public enum Status {
            /// The request succeeded and `result` contains arrivals.
            public static let ok = "OK"
            /// The backend has no SIRI data for this stop at the time of the request.
            public static let noData = "NO_SIRI_DATA"
        }

        /// System identifier ("SM" for stop monitoring)
        public let sys: String
        /// Status of the response (see ``Status`` for known values)
        public let status: String
        /// Unix timestamp when the response was generated
        public let serverTime: TimeInterval
        /// Array of vehicle arrivals/departures in order of arrival
        public let result: [Foli.Arrival]

        /// Creates a stop-monitoring response value.
        /// - Parameters:
        ///   - sys: The system identifier, typically `SM`.
        ///   - status: The backend status string.
        ///   - serverTime: Unix timestamp for when the response was generated.
        ///   - result: The ordered arrival list returned by the backend.
        public init(sys: String, status: String, serverTime: TimeInterval, result: [Foli.Arrival]) {
            self.sys = sys
            self.status = status
            self.serverTime = serverTime
            self.result = result
        }

        enum CodingKeys: String, CodingKey {
            case sys
            case status
            case serverTime = "servertime"
            case result
        }

        /// Computed property to check if the response is valid
        public var isValid: Bool {
            status == Foli.ArrivalResponse.Status.ok
        }

        /// Convert server time to Date
        public var serverDate: Date {
            Date(timeIntervalSince1970: serverTime)
        }
    }
}
