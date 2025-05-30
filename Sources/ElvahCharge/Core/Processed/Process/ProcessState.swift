// swiftformat:disable all
//
//  Copyright © 2023 Dennis Müller and all collaborators
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation

/// An enumeration representing the possible states of a process.
package enum ProcessState<ProcessKind>: Sendable where ProcessKind: Sendable {

  /// Represents the state where the process is currently not running and has no result or error.
  case idle

  /// Represents the state where the process is currently running.
  /// - Parameter ProcessKind: The process that is running.
  case running(ProcessKind)

  /// Represents the state where the process has finished with an error.
  /// - Parameter process: The process that has thrown an error.
  /// - Parameter error: The thrown error.
  case failed(process: ProcessKind, error: Swift.Error)

  /// Represents the state where the process has finished successfully.
  /// - Parameter process: The process that has finished.
  case finished(ProcessKind)
}

/// A convenience typealias for a `ProcessState` with the generic type of `SingleProcess`
package typealias SingleProcessState = ProcessState<SingleProcess>

extension ProcessState: CustomDebugStringConvertible {
  package var debugDescription: String {
    switch self {
    case .idle:
      return "idle"
    case .running(let process):
      return "running(\(process))"
    case .failed(let process, let error):
      return "failed((\(process)), \(error.localizedDescription))"
    case .finished(let process):
      return "finished(\(process))"
    }
  }
}

extension ProcessState {
  
  // MARK: - Start
  
  /// Starts running the specified process.
  /// - Parameter process: The process to start running.
  package mutating func start(_ process: ProcessKind) {
    self = .running(process)
  }
  
  /// Starts running a new unique process.
  package mutating func start() where ProcessKind == SingleProcess {
    start(.init())
  }
  
  // MARK: - Finish
  
  /// Finishes the currently running process.
  package mutating func finish() {
    guard case .running(let process) = self else {
      return
    }
    
    self = .finished(process)
  }
  
  // MARK: - Fail
  
  /// Sets the state to `.failed` with the specified error.
  /// - Parameter error: The error causing the failure.
  package mutating func fail(with error: Swift.Error) {
    guard case .running(let process) = self else {
      return
    }
    
    self = .failed(process: process, error: error)
  }
  
  // MARK: - Manual Control
  
  /// Sets the state to `idle`.
  package mutating func setIdle() {
    self = .idle
  }
  
  /// Sets the state to `running` with the given process.
  /// - Parameters:
  ///   - process: The process that is running.
  package mutating func setRunning(_ process: ProcessKind) {
    self = .running(process)
  }
  
  /// Sets the state to `running`.
  package mutating func setRunning() where ProcessKind == SingleProcess {
    self = .running(.init())
  }
  
  /// Sets the process state to `.failed` with the given process id.
  /// - Parameters:
  ///   - process: The process that failed.
  ///   - error: The error causing the failure.
  package mutating func setFailed(_ process: ProcessKind, error: Swift.Error) {
    self = .failed(process: process, error: error)
  }

  /// Sets the process state to `.failed`.
  /// - Parameters:
  ///   - error: The error causing the failure.
  package mutating func setFailed(with error: Swift.Error) where ProcessKind == SingleProcess {
    self = .failed(process: .init(), error: error)
  }

  /// Sets the process state to `.finished` with the given process.
  /// - Parameters:
  ///   - process: The process that finished.
  package mutating func setFinished(_ process: ProcessKind) {
    self = .finished(process)
  }
  
  /// Sets the process state to `.finished`.
  package mutating func setFinished() where ProcessKind == SingleProcess {
    self = .finished(.init())
  }
  
  // MARK: - Convenience
  
  /// A Boolean value indicating whether the state is `idle`.
  package var isIdle: Bool {
    if case .idle = self { return true }
    return false
  }

  /// A Boolean value indicating whether the state is `running`.
  package var isRunning: Bool {
    if case .running = self { return true }
    return false
  }
  
  /// A Boolean value indicating whether the state is `running` with the given process.
  /// - Parameter process: The process to check against.
  /// - Returns: A boolean.
  package func isRunning(_ process: ProcessKind) -> Bool where ProcessKind: Equatable {
    if case .running(let runningProcess) = self { return runningProcess == process }
    return false
  }
  
  /// A Boolean value indicating whether the state is `failed`.
  package var hasFailed: Bool {
    if case .failed = self { return true }
    return false
  }
  
  /// A Boolean value indicating whether the state is `failed` with the given process.
  /// - Parameter process: The process to check against.
  /// - Returns: A boolean.
  package func hasFailed(_ process: ProcessKind) -> Bool where ProcessKind: Equatable {
    if case .failed(let failedProcess, _) = self { return failedProcess == process }
    return false
  }

  /// A Boolean value indicating whether the state is `finished`.
  package var hasFinished: Bool {
    if case .finished = self { return true }
    return false
  }

  /// A Boolean value indicating whether the state is `finished` with the given process.
  /// - Parameter process: The process to check against.
  /// - Returns: A boolean.
  package func hasFinished(_ process: ProcessKind) -> Bool where ProcessKind: Equatable {
    if case .finished(let finishedProcess) = self { return finishedProcess == process }
    return false
  }

  /// The current process if the state is `running`, `failed` or `finished`, and `nil` otherwise.
  package var process: ProcessKind? {
    switch self {
    case .idle: return nil
    case .running(let process): return process
    case .failed(let process,_ ): return process
    case .finished(let process): return process
    }
  }

  /// The current error if the state is `failed`, and `nil` otherwise.
  package var error: Error? {
    if case .failed(_, let error) = self { return error }
    return nil
  }
}

extension ProcessState: Equatable where ProcessKind: Equatable {
  nonisolated package static func == (lhs: ProcessState, rhs: ProcessState) -> Bool {
    switch (lhs, rhs) {
    case (.idle, .idle): return true
    case (.running(let leftId), .running(let rightId)): return leftId == rightId
    case (.failed(let leftId, _), .failed(let rightId, _)): return leftId == rightId
    case (.finished(let leftId), .finished(let rightId)): return leftId == rightId
    default: return false
    }
  }
}
