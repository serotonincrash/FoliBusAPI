import Foundation

@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
extension FoliClient {
    struct AnyInFlightTask: Sendable {
        private let awaitValueClosure: @Sendable () async throws -> any Sendable

        init<T: Sendable>(_ task: Task<T, Error>) {
            self.awaitValueClosure = { try await task.value }
        }

        func value<T: Sendable>(as type: T.Type) async throws -> T {
            let value = try await awaitValueClosure()
            guard let typedValue = value as? T else {
                throw Foli.APIError.invalidResponse
            }
            return typedValue
        }
    }

    internal func performDeduplicated<T: Sendable>(_ key: Foli.CacheResource, operation: @escaping @Sendable () async throws -> T) async throws -> T {
        // Check for existing in-flight request first
        if let existingTask = inFlightRequests[key] {
            return try await existingTask.value(as: T.self)
        }

        // Create and register task before awaiting to prevent reentrancy races
        let task = Task { try await operation() }
        inFlightRequests[key] = AnyInFlightTask(task)
        
        do {
            let result = try await task.value
            inFlightRequests[key] = nil
            return result
        } catch {
            inFlightRequests[key] = nil
            throw error
        }
    }
}
