import Foundation

// MARK: - Vehicle Monitoring Response
extension Foli {
    /// Response from the vehicle monitoring endpoint
    struct VehicleMonitoringResponse: Codable, Sendable, Equatable, Hashable {
        // MARK: - Response Wrapper
        
        /// System identifier ("VM" for vehicle monitoring)
        let sys: String
        /// Status of the response
        let status: String
        /// Unix timestamp when the response was generated
        let serverTime: TimeInterval
        /// Nested result containing vehicle data
        let result: VehicleMonitoringResult
        
        init(sys: String, status: String, serverTime: TimeInterval, result: VehicleMonitoringResult) {
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
            status == "OK"
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
        /// Status flag
        let status: Bool
        /// Whether there is more data available
        let moreData: Bool
        /// Dictionary of vehicles keyed by vehicle reference ID
        let vehicles: [String: Foli.VehicleLocation]
        
        enum CodingKeys: String, CodingKey {
            case responseTimestamp = "responsetimestamp"
            case producerRef = "producerref"
            case responseMessageIdentifier = "responsemessageidentifier"
            case status
            case moreData = "moredata"
            case vehicles
        }
        
        init(
            responseTimestamp: TimeInterval,
            producerRef: String,
            responseMessageIdentifier: String,
            status: Bool,
            moreData: Bool,
            vehicles: [String: Foli.VehicleLocation]
        ) {
            self.responseTimestamp = responseTimestamp
            self.producerRef = producerRef
            self.responseMessageIdentifier = responseMessageIdentifier
            self.status = status
            self.moreData = moreData
            self.vehicles = vehicles
        }
        
        /// Convert response timestamp to Date
        var responseDate: Date {
            Date(timeIntervalSince1970: responseTimestamp)
        }
    }
}
