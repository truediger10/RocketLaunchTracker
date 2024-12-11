
import Foundation

enum TaskQueueError: Error, LocalizedError {
    case queueFull
    
    var errorDescription: String? {
        switch self {
        case .queueFull:
            return "The task queue is full."
        }
    }
}

actor TaskQueue {
    private enum Constants {
        static let defaultQueueCapacity = 100
        static let defaultMaxConcurrent = 5
    }
    
    private let maxConcurrent: Int
    private let queueCapacity: Int
    private var running = 0
    private var queue: [(operation: () async throws -> Void, continuation: CheckedContinuation<Void, Error>)] = []
    private var metrics = QueueMetrics()
    
    struct QueueMetrics {
        var totalTasksProcessed: Int = 0
        var averageWaitTime: TimeInterval = 0
        var peakConcurrency: Int = 0
        var currentQueueDepth: Int = 0
        
        mutating func recordTaskCompletion(waitTime: TimeInterval) {
            totalTasksProcessed += 1
            averageWaitTime = (averageWaitTime * Double(totalTasksProcessed - 1) + waitTime) / Double(totalTasksProcessed)
        }
    }
    
    init(maxConcurrent: Int = Constants.defaultMaxConcurrent,
         queueCapacity: Int = Constants.defaultQueueCapacity) {
        self.maxConcurrent = maxConcurrent
        self.queueCapacity = queueCapacity
    }
    
    func enqueue(_ operation: @escaping () async throws -> Void) async throws {
        guard queue.count < queueCapacity else {
            throw TaskQueueError.queueFull
        }
        
        if running >= maxConcurrent {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                queue.append((operation: operation, continuation: continuation))
                metrics.currentQueueDepth = queue.count
            }
        }
        
        running += 1
        metrics.peakConcurrency = max(metrics.peakConcurrency, running)
        
        defer {
            running -= 1
            if !queue.isEmpty {
                let next = queue.removeFirst()
                metrics.currentQueueDepth = queue.count
                Task {
                    do {
                        try await next.operation()
                        next.continuation.resume()
                    } catch {
                        next.continuation.resume(throwing: error)
                    }
                }
            }
        }
        
        try await operation()
    }
    
    func getMetrics() -> QueueMetrics {
        metrics
    }
}
