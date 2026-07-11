import Foundation
import Testing
@testable import FoliBusAPI

@Suite("Dedup Cancellation Tests")
struct DedupCancellationTests {
    /// A transport that hangs until cancelled, like a stalled network request,
    /// and records whether its in-flight request was cancelled.
    private actor HangingTransport: FoliTransport {
        private(set) var wasCancelled = false

        func data(for request: URLRequest) async throws -> (data: Data, response: URLResponse) {
            do {
                try await Task.sleep(for: .seconds(30))
            } catch {
                wasCancelled = true
                throw error
            }
            let (response, data) = try makeDataResponse(for: request, data: Data("[]".utf8))
            return (data, response)
        }
    }

    /// A transport that responds after a short, cancellable delay and records requests.
    private actor DelayedTransport: FoliTransport {
        private(set) var requestCount = 0

        func data(for request: URLRequest) async throws -> (data: Data, response: URLResponse) {
            requestCount += 1
            try await Task.sleep(for: .milliseconds(150))
            let (response, data) = try makeDataResponse(for: request, data: Data("[]".utf8))
            return (data, response)
        }
    }

    @Test("cancelling the sole caller unblocks promptly with CancellationError")
    func cancellingSoleCallerUnblocksPromptly() async throws {
        let transport = HangingTransport()
        let client = FoliClient(transport: transport, cacheBehavior: .noCache)

        let fetchTask = Task { try await client.fetchRoutes() }
        try await Task.sleep(for: .milliseconds(100))
        fetchTask.cancel()

        let start = ContinuousClock.now
        let result = await fetchTask.result
        let elapsed = ContinuousClock.now - start

        #expect(elapsed < .seconds(5), "cancelled caller should not wait out the 30s transport hang")
        guard case .failure(let error) = result else {
            Issue.record("Expected the cancelled fetch to throw")
            return
        }
        #expect(error is CancellationError, "expected CancellationError, got \(error)")
    }

    @Test("cancelling one of two deduplicated callers leaves the other unaffected")
    func cancellingOneOfTwoCallersLeavesOtherUnaffected() async throws {
        let transport = DelayedTransport()
        let client = FoliClient(transport: transport, cacheBehavior: .noCache)

        let first = Task { try await client.fetchRoutes() }
        let second = Task { try await client.fetchRoutes() }
        try await Task.sleep(for: .milliseconds(50))
        first.cancel()

        let firstResult = await first.result
        let secondResult = await second.result

        guard case .failure(let error) = firstResult else {
            Issue.record("Expected the cancelled caller to throw")
            return
        }
        #expect(error is CancellationError, "expected CancellationError, got \(error)")

        guard case .success = secondResult else {
            Issue.record("Expected the surviving caller to succeed, got \(secondResult)")
            return
        }
    }

    @Test("cancelling every caller cancels the shared network request")
    func cancellingAllCallersCancelsSharedRequest() async throws {
        let transport = HangingTransport()
        let client = FoliClient(transport: transport, cacheBehavior: .noCache)

        let first = Task { try await client.fetchRoutes() }
        let second = Task { try await client.fetchRoutes() }
        try await Task.sleep(for: .milliseconds(100))
        first.cancel()
        second.cancel()

        _ = await first.result
        _ = await second.result

        // The shared operation should observe cancellation shortly after the last
        // caller leaves; poll briefly rather than assuming instant propagation.
        var sharedRequestCancelled = false
        for _ in 0..<40 {
            if await transport.wasCancelled {
                sharedRequestCancelled = true
                break
            }
            try await Task.sleep(for: .milliseconds(25))
        }
        #expect(sharedRequestCancelled, "orphaned shared request should be cancelled, not left running")
    }

    @Test("concurrent identical fetches coalesce into one transport request")
    func concurrentFetchesCoalesce() async throws {
        let transport = DelayedTransport()
        let client = FoliClient(transport: transport, cacheBehavior: .noCache)

        let results = try await withThrowingTaskGroup(of: [Foli.Route].self) { group in
            for _ in 0..<5 {
                group.addTask { try await client.fetchRoutes() }
            }
            var collected: [[Foli.Route]] = []
            for try await routes in group {
                collected.append(routes)
            }
            return collected
        }

        #expect(results.count == 5)
        #expect(await transport.requestCount == 1, "identical concurrent fetches should share one request")
    }
}
