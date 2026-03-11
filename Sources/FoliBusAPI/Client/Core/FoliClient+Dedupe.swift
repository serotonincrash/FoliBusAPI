import Foundation

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
extension FoliClient {
    internal enum RequestKey: Hashable, Sendable {
        case stopMonitoring(String)
        case stops
        case routes
        case trips
        case tripsForRoute(String)
        case stopTimes
        case stopTimesForTrip(String)
        case stopTimesForStop(String)
        case calendarDates
    }

    final class AnyInFlightTask: @unchecked Sendable {
        private let awaitValueClosure: @Sendable () async throws -> Any

        init<T: Sendable>(_ task: Task<T, Error>) {
            self.awaitValueClosure = { try await task.value }
        }

        func value<T>(as type: T.Type) async throws -> T {
            let value = try await awaitValueClosure()
            guard let typedValue = value as? T else {
                throw Foli.APIError.invalidResponse
            }
            return typedValue
        }
    }

    internal func performDeduplicated<T: Sendable>(_ key: RequestKey, operation: @escaping @Sendable () async throws -> T) async throws -> T {
        if let task = inFlightRequests[key] {
            return try await task.value(as: T.self)
        }

        let task = Task { try await operation() }
        inFlightRequests[key] = AnyInFlightTask(task)
        defer { inFlightRequests[key] = nil }
        return try await task.value
    }
}
