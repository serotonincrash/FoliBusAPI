import Foundation

/// Owns the in-flight request dictionary used by ``FoliClient`` for request deduplication.
///
/// Extracting deduplication into a dedicated actor means the dedup bookkeeping
/// (dictionary lookups, task creation, and cleanup) no longer blocks unrelated
/// ``FoliClient`` calls, since they execute on the dedup actor's executor
/// rather than the client's.
@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
internal actor FoliDedup {
    /// Type-erased wrapper for in-flight tasks.
    ///
    /// This wrapper allows storing heterogeneous task types in a single dictionary
    /// while preserving type safety when retrieving values.
    struct AnyInFlightTask: Sendable {
        /// Closure that awaits the underlying task and returns its result.
        private let awaitValueClosure: @Sendable () async throws -> any Sendable

        /// Creates a type-erased wrapper for the given task.
        /// - Parameter task: The task to wrap.
        init<T: Sendable>(_ task: Task<T, Error>) {
            self.awaitValueClosure = { try await task.value }
        }

        /// Awaits the underlying task and casts the result to the expected type.
        /// - Parameter type: The expected result type.
        /// - Returns: The task result cast to the specified type.
        /// - Throws: `Foli.APIError.invalidResponse` if the type cast fails.
        func value<T: Sendable>(as type: T.Type) async throws -> T {
            let value = try await awaitValueClosure()
            guard let typedValue = value as? T else {
                throw Foli.APIError.invalidResponse
            }
            return typedValue
        }
    }

    private var inFlightRequests: [Foli.DedupeKey: AnyInFlightTask] = [:]

    /// Executes an operation with request deduplication.
    ///
    /// If an identical request (identified by `key`) is already in flight, this method
    /// returns the result of the existing request instead of starting a new one.
    /// This prevents duplicate network requests when multiple callers request the same data simultaneously.
    ///
    /// > Important: Dedup correctness for hung operations depends on the transport layer
    /// > timing out (e.g., `URLSessionConfiguration.timeoutIntervalForRequest`). A
    /// > never-completing operation blocks every caller sharing the same key until the
    /// > transport gives up. Configure timeouts at the transport or caller level rather
    /// > than adding timeout logic here.
    ///
    /// - Parameters:
    ///   - key: The deduplication key identifying this request type.
    ///   - operation: The async operation to execute if no request is in flight.
    /// - Returns: The result from either the new or existing request.
    /// - Throws: Any error thrown by the operation.
    func performDeduplicated<T: Sendable>(forKey key: Foli.DedupeKey, operation: @escaping @Sendable () async throws -> T) async throws -> T {
        // Check for existing in-flight request first
        if let existingTask = inFlightRequests[key] {
            return try await existingTask.value(as: T.self)
        }

        // Create and register task before awaiting to prevent reentrancy races
        let task = Task { try await operation() }
        inFlightRequests[key] = AnyInFlightTask(task)

        defer { inFlightRequests[key] = nil }
        return try await task.value
    }
}
