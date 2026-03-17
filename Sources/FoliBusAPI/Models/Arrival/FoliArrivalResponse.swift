import Foundation

// MARK: - Stop Monitoring Response
extension Foli {
    /// Response from the stop monitoring endpoint
    struct ArrivalResponse: Codable, Sendable {
        // MARK: - Known Status Values

        /// Named constants for the well-known status strings returned by the stop monitoring endpoint.
        enum Status {
            /// The request succeeded and `result` contains arrivals.
            static let ok = "OK"
            /// The backend has no SIRI data for this stop at the time of the request.
            static let noData = "NO_SIRI_DATA"
        }

        /// System identifier ("SM" for stop monitoring)
        let sys: String
        /// Status of the response
        let status: String
        /// Unix timestamp when the response was generated
        let serverTime: TimeInterval
        /// Array of vehicle arrivals/departures in order of arrival
        let result: [Foli.Arrival]

        init(sys: String, status: String, serverTime: TimeInterval, result: [Foli.Arrival]) {
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
        var isValid: Bool {
            status == Foli.ArrivalResponse.Status.ok
        }

        /// Convert server time to Date
        var serverDate: Date {
            Date(timeIntervalSince1970: serverTime)
        }
    }
}
