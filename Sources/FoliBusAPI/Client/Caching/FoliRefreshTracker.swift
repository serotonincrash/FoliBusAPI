import Foundation

/// Tracks background stale-while-revalidate refresh tasks so that at most one
/// refresh is in flight per resource: while a refresh is registered, subsequent
/// requests to refresh the same resource are no-ops.
///
/// Extracting bookkeeping into a dedicated actor means the task registration and
/// cleanup dictionary operations no longer block unrelated ``FoliClient`` calls.
internal actor FoliRefreshTracker {
    private var tasks: [Foli.Resource: Task<Void, Never>] = [:]

    /// Registers a task only if no task is already registered for the resource.
    /// Returns `true` if the task was registered, `false` if a task already exists.
    func setTaskIfAbsent(_ task: Task<Void, Never>, for resource: Foli.Resource) -> Bool {
        guard tasks[resource] == nil else { return false }
        tasks[resource] = task
        return true
    }

    /// Removes a background refresh task if it is still the task currently registered for the resource.
    func clearTask(for resource: Foli.Resource, matching task: Task<Void, Never>) {
        guard let currentTask = tasks[resource], currentTask == task else {
            return
        }
        tasks[resource] = nil
    }

    /// Returns whether a resource currently has a background refresh task registered.
    func hasActiveTask(for resource: Foli.Resource) -> Bool {
        tasks[resource] != nil
    }
}
