import Foundation

// MARK: - Agency List Response
public extension Foli {
    /// Response containing all known agencies (GTFS agency.txt)
    struct AgencyList: Codable, Sendable {
        /// Array of all agencies
        public let agencies: [Foli.Agency]

        public init(agencies: [Foli.Agency]) {
            self.agencies = agencies
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let array = try container.decode([Foli.Agency].self)
            self.agencies = array.sorted { $0.id < $1.id }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(agencies)
        }
    }
}

/// Backward-compatible typealias for ``Foli/AgencyList``.
@available(*, deprecated, renamed: "Foli.AgencyList")
public typealias FoliAgencyList = Foli.AgencyList
