// Services/TaskQueue.swift

import Foundation

/// Errors that can occur during task queue operations
enum TaskQueueError: LocalizedError {
    case queueFull
    case operationCancelled
    
    var errorDescription: String? {
        switch self {
        case .queueFull:
            return "Task queue capacity exceeded."
        case .operationCancelled:
            return "Operation was cancelled."
        }
    }
}

/// Manages concurrent task execution with configurable limits and monitoring
actor TaskQueue {
    // MARK: - Properties
    
    private let maxConcurrent: Int
    private let queueCapacity: Int
    private var running = 0
    private var queue: [TaskContinuation] = []
    private var metrics = QueueMetrics()
    
    /// Task continuation with metadata for monitoring
    private struct TaskContinuation {
        let continuation: CheckedContinuation<Void, Error>
        let enqueueTime: Date
    }
    
    /// Metrics for monitoring queue performance
    struct QueueMetrics {
        var totalTasksProcessed: Int = 0
        var averageWaitTime: TimeInterval = 0
        var peakConcurrency: Int = 0
        
        mutating func recordTaskCompletion(waitTime: TimeInterval, currentConcurrency: Int) {
            totalTasksProcessed += 1
            averageWaitTime = (averageWaitTime * Double(totalTasksProcessed - 1) + waitTime) / Double(totalTasksProcessed)
            peakConcurrency = max(peakConcurrency, currentConcurrency)
        }
    }
    
    // MARK: - Initialization
    
    /// Initialize TaskQueue with configuration
    /// - Parameters:
    ///   - maxConcurrent: Maximum number of concurrent tasks
    ///   - queueCapacity: Maximum number of waiting tasks (default: 100)
    init(maxConcurrent: Int, queueCapacity: Int = 100) {
        self.maxConcurrent = maxConcurrent
        self.queueCapacity = queueCapacity
    }
    
    // MARK: - Public Methods
    
    /// Enqueues an operation for execution
    /// - Parameters:
    ///   - operation: The async operation to execute
    /// - Returns: The operation result
    /// - Throws: TaskQueueError if the queue is full
    func enqueue<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        if queue.count >= queueCapacity {
            throw TaskQueueError.queueFull
        }
        
        let startTime = Date()
        // Removed 'currentConcurrency' as it was unused
        
        if running >= maxConcurrent {
            try await withCheckedThrowingContinuation { continuation in
                let taskContinuation = TaskContinuation(
                    continuation: continuation,
                    enqueueTime: startTime
                )
                queue.append(taskContinuation)
            }
        }
        
        running += 1
        metrics.peakConcurrency = max(metrics.peakConcurrency, running)
        
        defer {
            running -= 1
            if let next = queue.first {
                queue.removeFirst()
                next.continuation.resume(returning: ())
            }
            let waitTime = Date().timeIntervalSince(startTime)
            metrics.recordTaskCompletion(waitTime: waitTime, currentConcurrency: running)
        }
        
        return try await operation()
    }
    
    /// Retrieves current queue metrics
    /// - Returns: Snapshot of queue performance metrics
    func getMetrics() -> QueueMetrics {
        metrics
    }
    
    // MARK: - Private Methods
    
    // Removed 'resumeNextTask' as it's unused
}

/// Extension for additional functionalities if needed in the future
private extension TaskQueue {
    // Future methods can be added here
}
