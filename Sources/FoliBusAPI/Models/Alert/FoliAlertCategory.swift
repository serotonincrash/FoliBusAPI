import Foundation

/// Alert category description
public extension Foli {
    struct AlertCategory: Codable, Sendable, Identifiable, Equatable {
        /// Category ID
        public let catId: Int
        /// Category code (e.g., "TIMETABLE_CHANGES")
        public let category: String
        /// Finnish description
        public let descrFi: String
        /// Swedish description
        public let descrSv: String?
        /// English description
        public let descrEn: String?
        
        public var id: Int { catId }
        
        enum CodingKeys: String, CodingKey {
            case catId = "catid"
            case category
            case descrFi = "descr_fi"
            case descrSv = "descr_sv"
            case descrEn = "descr_en"
        }
        
        public init(
            catId: Int,
            category: String,
            descrFi: String,
            descrSv: String? = nil,
            descrEn: String? = nil
        ) {
            self.catId = catId
            self.category = category
            self.descrFi = descrFi
            self.descrSv = descrSv
            self.descrEn = descrEn
        }
        
        /// Get localized description
        public func description(language: String) -> String {
            switch language {
            case "fi": return descrFi
            case "sv": return descrSv ?? descrFi
            case "en": return descrEn ?? descrFi
            default: return descrEn ?? descrFi
            }
        }
    }
}
