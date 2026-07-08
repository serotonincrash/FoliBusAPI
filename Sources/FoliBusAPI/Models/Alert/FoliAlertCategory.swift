import Foundation

/// Alert category description
public extension Foli {
    struct AlertCategory: Codable, Sendable, Identifiable, Equatable, Hashable {
        /// Category ID
        public let catId: Int
        /// Category code (e.g., "TIMETABLE_CHANGES")
        public let category: String
        /// Finnish description
        public let descriptionFi: String
        /// Swedish description
        public let descriptionSv: String?
        /// English description
        public let descriptionEn: String?
        
        public var id: Int { catId }
        
        private enum CodingKeys: String, CodingKey {
            case catId = "catid"
            case category
            case descriptionFi = "descr_fi"
            case descriptionSv = "descr_sv"
            case descriptionEn = "descr_en"
        }
        
        public init(
            catId: Int,
            category: String,
            descriptionFi: String,
            descriptionSv: String? = nil,
            descriptionEn: String? = nil
        ) {
            self.catId = catId
            self.category = category
            self.descriptionFi = descriptionFi
            self.descriptionSv = descriptionSv
            self.descriptionEn = descriptionEn
        }
        
        /// Get localized description
        public func description(language: String) -> String {
            switch language {
            case "fi": return descriptionFi
            case "sv": return descriptionSv ?? descriptionFi
            case "en": return descriptionEn ?? descriptionFi
            default: return descriptionEn ?? descriptionFi
            }
        }
    }
}
