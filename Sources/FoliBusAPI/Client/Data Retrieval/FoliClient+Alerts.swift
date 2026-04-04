//
//  FoliClient+Alerts.swift
//  FoliBusAPI
//
//  Created by sero on 18/3/26.
//

import Foundation

// MARK: - Alerts

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public extension FoliClient {
    
    /// Fetch all active alerts (messages and cancellations).
    ///
    /// - Returns: Alerts response containing messages, cancellations, and special alerts.
    /// - Throws: `Foli.APIError` if the request fails.
    ///
    /// - Note: Alert data is real-time. Recommended polling interval: 30-60 seconds.
    ///         Response may be gzip-compressed.
    func fetchAlerts() async throws -> Foli.AlertsResponse {
        try await performDeduplicated(.alerts) { [self] in
            try await requestAlerts("/alerts", as: Foli.AlertsResponse.self)
        }
    }
    
    /// Fetch only informational messages (no cancellations).
    ///
    /// - Returns: Array of alert messages.
    /// - Throws: `Foli.APIError` if the request fails.
    func fetchAlertMessages() async throws -> [Foli.Alert] {
        try await performDeduplicated(.alertMessages) { [self] in
            let response = try await requestAlerts("/alerts/messages", as: Foli.AlertsResponse.self)
            return response.messages
        }
    }
    
    /// Fetch only trip cancellations (no messages).
    ///
    /// - Returns: Array of trip cancellations.
    /// - Throws: `Foli.APIError` if the request fails.
    func fetchCancellations() async throws -> [Foli.TripCancellation] {
        try await performDeduplicated(.alertCancellations) { [self] in
            let response = try await requestAlerts("/alerts/cancellations", as: Foli.AlertsResponse.self)
            return response.cancellations
        }
    }
    
    /// Fetch alert category descriptions.
    ///
    /// Categories describe the tag classifications used in alerts.
    ///
    /// - Returns: Array of alert categories.
    /// - Throws: `Foli.APIError` if the request fails.
    func fetchAlertCategories() async throws -> [Foli.AlertCategory] {
        try await requestAlerts("/alerts/categories", as: [Foli.AlertCategory].self)
    }
}
