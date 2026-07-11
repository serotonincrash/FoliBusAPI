import Foundation

/// Owns the in-flight request registry used by ``FoliClient`` for request deduplication.
///
/// Concurrent callers requesting the same ``Foli/DedupeKey`` share one underlying
/// operation. Each caller awaits its own continuation, which keeps the wait responsive
/// to that caller's cancellation: a cancelled caller is resumed immediately with
/// `CancellationError`, and when the last live caller cancels, the shared operation
/// itself is cancelled so the network request aborts instead of running for nobody.
///
/// Extracting deduplication into a dedicated actor means the dedup bookkeeping
/// no longer blocks unrelated ``FoliClient`` calls.
internal actor FoliDedup {
    /// One shared in-flight operation and the callers waiting on it.
    private struct InFlightRequest {
        /// Cancels the underlying operation task.
        let cancelUnderlying: @Sendable () -> Void
        /// Continuations of callers that have registered and are awaiting the result.
        var waiters: [Int: CheckedContinuation<any Sendable, any Error>] = [:]
        /// IDs of callers that have joined but not yet registered their continuation.
        var pendingWaiterIds: Set<Int> = []
        /// Joined callers minus cancelled ones; at zero the underlying task is cancelled.
        var liveWaiters: Int = 0
    }

    private var inFlightRequests: [Foli.DedupeKey: InFlightRequest] = [:]
    private var nextWaiterId = 0
    /// Waiter IDs whose cancellation was processed before their continuation registered.
    private var preRegistrationCancellations: Set<Int> = []
    /// Results stashed for waiters whose operation completed before they registered.
    private var pendingResults: [Int: Result<any Sendable, any Error>] = [:]

    /// Executes an operation with request deduplication.
    ///
    /// If an identical request (identified by `key`) is already in flight, this method
    /// returns the result of the existing request instead of starting a new one.
    /// This prevents duplicate network requests when multiple callers request the same data simultaneously.
    ///
    /// Cancellation semantics: a cancelled caller throws `CancellationError` promptly
    /// without waiting for the shared operation; the shared operation is cancelled only
    /// when every caller sharing it has been cancelled.
    ///
    /// - Parameters:
    ///   - key: The deduplication key identifying this request type.
    ///   - operation: The async operation to execute if no request is in flight.
    /// - Returns: The result from either the new or existing request.
    /// - Throws: Any error thrown by the operation, or `CancellationError` if the caller is cancelled.
    func performDeduplicated<T: Sendable>(forKey key: Foli.DedupeKey, operation: @escaping @Sendable () async throws -> T) async throws -> T {
        // Join or create synchronously — no suspension between entry setup and waiter
        // accounting, so completion can never slip between the two.
        let waiterId = nextWaiterId
        nextWaiterId += 1

        if inFlightRequests[key] != nil {
            inFlightRequests[key]!.pendingWaiterIds.insert(waiterId)
            inFlightRequests[key]!.liveWaiters += 1
        } else {
            let task = Task { try await operation() }
            var entry = InFlightRequest(cancelUnderlying: { task.cancel() })
            entry.pendingWaiterIds.insert(waiterId)
            entry.liveWaiters = 1
            inFlightRequests[key] = entry

            // Forwarder: deliver the operation's outcome to whoever is waiting.
            Task { [weak self] in
                let result: Result<any Sendable, any Error>
                do {
                    result = .success(try await task.value)
                } catch {
                    result = .failure(error)
                }
                await self?.complete(key: key, with: result)
            }
        }

        let value = try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<any Sendable, any Error>) in
                self.registerWaiter(id: waiterId, forKey: key, continuation: continuation)
            }
        } onCancel: {
            Task { await self.cancelWaiter(id: waiterId, forKey: key) }
        }

        guard let typedValue = value as? T else {
            throw Foli.APIError.invalidResponse
        }
        return typedValue
    }

    /// Registers a waiter's continuation, or resumes it immediately if its outcome
    /// (cancellation or a completed result) arrived before registration.
    private func registerWaiter(id: Int, forKey key: Foli.DedupeKey, continuation: CheckedContinuation<any Sendable, any Error>) {
        if preRegistrationCancellations.remove(id) != nil {
            continuation.resume(throwing: CancellationError())
            return
        }
        if let result = pendingResults.removeValue(forKey: id) {
            continuation.resume(with: result)
            return
        }
        guard inFlightRequests[key] != nil else {
            // Unreachable: an entry survives until it has stashed a result for every
            // pending waiter. Fail defensively rather than leak the continuation.
            continuation.resume(throwing: Foli.APIError.invalidResponse)
            return
        }
        inFlightRequests[key]!.pendingWaiterIds.remove(id)
        inFlightRequests[key]!.waiters[id] = continuation
    }

    /// Handles one waiter's cancellation: resumes it promptly with `CancellationError`
    /// and cancels the shared operation once no live waiters remain.
    private func cancelWaiter(id: Int, forKey key: Foli.DedupeKey) {
        if let continuation = inFlightRequests[key]?.waiters.removeValue(forKey: id) {
            inFlightRequests[key]!.liveWaiters -= 1
            if inFlightRequests[key]!.liveWaiters <= 0 {
                inFlightRequests[key]!.cancelUnderlying()
            }
            continuation.resume(throwing: CancellationError())
        } else if inFlightRequests[key]?.pendingWaiterIds.contains(id) == true {
            inFlightRequests[key]!.pendingWaiterIds.remove(id)
            inFlightRequests[key]!.liveWaiters -= 1
            if inFlightRequests[key]!.liveWaiters <= 0 {
                inFlightRequests[key]!.cancelUnderlying()
            }
            preRegistrationCancellations.insert(id)
        } else if pendingResults[id] != nil {
            // Completed before the cancellation was processed; the cancelled waiter
            // should still observe cancellation, not a value.
            pendingResults[id] = .failure(CancellationError())
        }
        // Otherwise the waiter was already resumed — nothing to do.
    }

    /// Delivers the shared operation's outcome: resumes registered waiters, stashes
    /// results for joined-but-unregistered ones, and retires the entry so subsequent
    /// callers start a fresh request.
    private func complete(key: Foli.DedupeKey, with result: Result<any Sendable, any Error>) {
        guard let entry = inFlightRequests.removeValue(forKey: key) else { return }
        for (_, continuation) in entry.waiters {
            continuation.resume(with: result)
        }
        for id in entry.pendingWaiterIds {
            pendingResults[id] = result
        }
    }
}
