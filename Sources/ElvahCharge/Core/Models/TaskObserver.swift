// Copyright © elvah. All rights reserved.

import Foundation

/// An object that holds a reference to a running task, providing a way to cancel it.
///
/// - Important: Simply deallocating this object is not enough to cancel the task. The underlying
/// task will continue to run unless ``TaskObserver/cancel()`` is explicitly called.
public struct TaskObserver: Sendable, Equatable {
	var task: Task<Void, Never>

	package init(task: Task<Void, Never>) {
		self.task = task
	}

	/// Cancel the task.
	public func cancel() {
		return task.cancel()
	}
}
