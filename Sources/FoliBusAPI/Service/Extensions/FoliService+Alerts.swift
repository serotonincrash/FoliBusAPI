//
//  FoliService+Alerts.swift
//  FoliBusAPI
//
//  Created by sero on 18/3/26.
//

import Foundation

// MARK: - Alerts API

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
public extension FoliService {
    
    /// Fetch all active alerts (messages and cancellations).
    ///
    /// - Returns: Alerts response containing messages, cancellations, and special alerts.
    /// - Throws: `Foli.APIError` if the request fails.
    func fetchAlerts() async throws -> Foli.AlertsResponse {
        return try await client.fetchAlerts()
    }
    
    /// Fetch only informational messages (no cancellations).
    ///
    /// - Returns: Array of alert messages.
    /// - Throws: `Foli.APIError` if the request fails.
    func fetchAlertMessages() async throws -> [Foli.Alert] {
        return try await client.fetchAlertMessages()
    }
    
    /// Fetch only trip cancellations (no messages).
    ///
    /// - Returns: Array of trip cancellations.
    /// - Throws: `Foli.APIError` if the request fails.
    func fetchCancellations() async throws -> [Foli.TripCancellation] {
        return try await client.fetchCancellations()
    }
    
    /// Fetch alert category descriptions.
    ///
    /// - Returns: Array of alert categories.
    /// - Throws: `Foli.APIError` if the request fails.
    func fetchAlertCategories() async throws -> [Foli.AlertCategory] {
        return try await client.fetchAlertCategories()
    }
}
