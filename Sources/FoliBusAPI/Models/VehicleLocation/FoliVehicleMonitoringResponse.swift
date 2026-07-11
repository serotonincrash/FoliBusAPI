import Foundation

// MARK: - Vehicle Monitoring Response
extension Foli {
    /// Response from the vehicle monitoring endpoint
    struct VehicleMonitoringResponse: Codable, Sendable, Equatable, Hashable {
        // MARK: - Known Status Values

        /// Named constants for the well-known status strings returned by the vehicle monitoring endpoint.
        ///
        /// Unrecognized status strings decode as ``unknown(_:)`` instead of failing the
        /// whole response, so a new server-side status surfaces as a server error rather
        /// than an opaque decoding error.
        enum Status: RawRepresentable, Codable, Sendable, Equatable, Hashable {
            /// The request succeeded and `result` contains vehicle data.
            case ok
            /// A status string this package version doesn't recognize.
            case unknown(String)

            var rawValue: String {
                switch self {
                case .ok: return "OK"
                case .unknown(let value): return value
                }
            }

            init(rawValue: String) {
                switch rawValue {
                case "OK": self = .ok
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

        // MARK: - Response Wrapper

        /// System identifier ("VM" for vehicle monitoring)
        let sys: String
        /// Status of the response
        let status: Status
        /// Unix timestamp when the response was generated
        let serverTime: TimeInterval
        /// Nested result containing vehicle data
        let result: VehicleMonitoringResult

        init(sys: String, status: Status, serverTime: TimeInterval, result: VehicleMonitoringResult) {
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
        
        /// Get all vehicles as an array
        var vehicles: [Foli.VehicleLocation] {
            Array(result.vehicles.values)
        }
    }
    
    /// Inner result structure containing actual vehicle data
    struct VehicleMonitoringResult: Codable, Sendable, Equatable, Hashable {
        /// Unix timestamp of the response
        let responseTimestamp: TimeInterval
        /// Producer reference identifier
        let producerRef: String
        /// Response message identifier
        let responseMessageIdentifier: String
        /// Whether the monitoring request succeeded
        let isSuccess: Bool
        /// Whether there is more data available
        let moreData: Bool
        /// Dictionary of vehicles keyed by vehicle reference ID
        let vehicles: [String: Foli.VehicleLocation]
        
        private enum CodingKeys: String, CodingKey {
            case responseTimestamp = "responsetimestamp"
            case producerRef = "producerref"
            case responseMessageIdentifier = "responsemessageidentifier"
            case isSuccess = "status"
            case moreData = "moredata"
            case vehicles
        }
        
        init(
            responseTimestamp: TimeInterval,
            producerRef: String,
            responseMessageIdentifier: String,
            isSuccess: Bool,
            moreData: Bool,
            vehicles: [String: Foli.VehicleLocation]
        ) {
            self.responseTimestamp = responseTimestamp
            self.producerRef = producerRef
            self.responseMessageIdentifier = responseMessageIdentifier
            self.isSuccess = isSuccess
            self.moreData = moreData
            self.vehicles = vehicles
        }
        
        /// Convert response timestamp to Date
        var responseDate: Date {
            Date(timeIntervalSince1970: responseTimestamp)
        }
    }
}
