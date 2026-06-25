import Foundation

/// Tracks background stale-while-revalidate refresh tasks so they can be cancelled
/// when the client is asked to refresh the same resource again before the previous
/// refresh completes.
///
/// Extracting bookkeeping into a dedicated actor means the task registration and
/// cleanup dictionary operations no longer block unrelated ``FoliClient`` calls.
@available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *)
internal actor FoliRefreshTracker {
    private var tasks: [Foli.Resource: Task<Void, Never>] = [:]

    /// Records a background refresh task for the provided resource.
    func setTask(_ task: Task<Void, Never>, for resource: Foli.Resource) {
        tasks[resource] = task
    }

    /// Removes a background refresh task if it is still the task currently registered for the resource.
    func clearTask(for resource: Foli.Resource, matching task: Task<Void, Never>) {
        guard let currentTask = tasks[resource], currentTask == task else {
            return
        }
        tasks[resource] = nil
    }

    /// Cancels any in-flight background refresh for the provided resource.
    func cancelTask(for resource: Foli.Resource) {
        tasks[resource]?.cancel()
    }

    /// Returns the currently registered background refresh task for the given resource, if any.
    func currentTask(for resource: Foli.Resource) -> Task<Void, Never>? {
        tasks[resource]
    }

    /// Returns whether a resource currently has a background refresh task registered.
    func hasActiveTask(for resource: Foli.Resource) -> Bool {
        tasks[resource] != nil
    }
}
