import Foundation

// MARK: - Stop Collection Helpers

public extension Collection where Element == Foli.Stop {
    /// Returns the stops sorted by name, ascending.
    func sortedByName() -> [Foli.Stop] {
        sorted { $0.name < $1.name }
    }

    /// Returns the stops sorted by ID, ascending.
    func sortedByID() -> [Foli.Stop] {
        sorted { $0.id < $1.id }
    }

    /// Returns the stops whose name or ID contains the given query string (case-insensitive).
    /// - Parameter query: The search string to match against stop names and IDs.
    /// - Returns: Matching stops sorted by name.
    func search(_ query: String) -> [Foli.Stop] {
        filter { stop in
            stop.name.localizedCaseInsensitiveContains(query) || stop.id.contains(query)
        }.sortedByName()
    }
}
