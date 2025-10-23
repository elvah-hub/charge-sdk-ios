// Copyright © elvah. All rights reserved.

import Foundation

#if canImport(Defaults)
  import Defaults
#endif

// MARK: - Accessors

public extension ChargeSession {
  /// A shared, internal observation object that keeps track of active charge sessions.
  @MainActor package static let observation: Observervation = .init()

  /// A flag indicating if there's currently an active charge session in the SDK.
  @MainActor static var isActive: Bool {
    observation.isSessionActive
  }

  /// Returns an `AsynAsyncThrowingStreamcStream` that yields whenever the  charge session status
  /// changes, e.g. when it becomes active or new session data is available.
  /// - Returns: An `AsyncStream` that yields charge session updates.
  @MainActor static func updates() -> AsyncThrowingStream<Update, any Error> {
    observation.updates()
  }

  /// A function that calls the provided handler whenever the charge session status changes, e.g.
  /// when it becomes active or new session data is available.
  ///
  /// - Note: The `handler` will be called on the main actor.
  ///
  /// - Important: To cancel the observation you must call the `cancel()` method on the returned
  /// `TaskObserver`. It is not enough to lose the reference to it.
  /// - Returns: A `TaskObsever` holding the task that is running the observation.
  @MainActor static func updates(
    handler: @MainActor @escaping (Result<ChargeSession.Update, Error>) -> Void,
  ) -> TaskObserver {
    observation.updates(handler: handler)
  }

  /// Removes all local charge session data that is stored by the SDK.
  ///
  /// - Warning: When you call this during an active charging session, access to that session will
  /// be lost! Only do this when there is no other choice.
  @MainActor static func resetLocalStorage() {
    Defaults[.chargeSessionContext] = nil
  }
}

// MARK: - Charge Session Status

public extension ChargeSession {
  /// An object containing status information about a possibly active charge session.
  enum Update: Sendable, Hashable {
    /// There is currently no active session.
    case inactive

    /// There is an active session.
    ///
    /// - Note: The associated ``ChargeSession/Update/SessionData-swift.struct`` value is `nil` when
    /// the SDK knows there is an active session but has not yet fetched up-to-date session data
    /// from the backend.
    case active(SessionData?)

    /// Returns `true` when there is an active charge session.
    public var isActive: Bool {
      if case .active = self {
        return true
      }
      return false
    }

    /// The session data, if there is an active session and available session data.
    public var sessionData: SessionData? {
      if case let .active(sessionData) = self {
        return sessionData
      }
      return nil
    }

    /// A collection of data points for the active charge session.
    public struct SessionData: Sendable, Hashable, CustomDebugStringConvertible {
      /// The energy amount that has been consumed during the active charge session, in
      /// kilowatt-hours.
      public var consumption: Measurement<UnitEnergy>

      public var debugDescription: String {
        "[Status - consumption \(consumption.formatted())]"
      }
    }
  }
}

// MARK: - Observer (Internal)

package extension ChargeSession {
  @MainActor
  final class Observervation {
    var isActiveObservationTask: Task<Void, Never>?
    var isSessionActive: Bool

    init() {
      isSessionActive = Defaults[.chargeSessionContext] != nil
      startObservation()
    }

    private var chargeProvider: ChargeProvider {
      if Elvah.configuration.environment.isSimulation {
        ChargeProvider.simulation
      } else {
        ChargeProvider.live
      }
    }

    func updates() -> AsyncThrowingStream<ChargeSession.Update, any Error> {
      updates(using: chargeProvider, sessionContextKey: .chargeSessionContext)
    }

    /// A function that calls the provided handler whenever the charge session status changes, e.g.
    /// when it becomes active or new session data is available.
    ///
    /// - Important: To cancel the observation you must call ``TaskObserver/cancel``. It is not
    /// enough to lose the reference to the task.
    /// - Returns: A `TaskObsever` holding the task that is running the observation.
    func updates(
      handler: @MainActor @escaping (Result<ChargeSession.Update, Error>) -> Void,
    ) -> TaskObserver {
      let task = Task {
        do {
          for try await update in updates() {
            handler(.success(update))
          }
        } catch {
          handler(.failure(error))
        }
      }

      return TaskObserver(task: task)
    }

    // MARK: - Internals

    func startObservation() {
      isActiveObservationTask?.cancel()
      isActiveObservationTask = Task {
        for await sessionContext in Defaults.updates(.chargeSessionContext) {
          isSessionActive = sessionContext != nil
        }
      }
    }

    func updates(
      using chargeProvider: ChargeProvider,
      sessionContextKey: some Defaults.Key<ChargeSessionContext?>,
    ) -> AsyncThrowingStream<ChargeSession.Update, any Error> {
      AsyncThrowingStream { continuation in
        let outerTask = Task {
          // The task that makes the backend requests to fetch the session data
          var pollingTask: Task<Void, Never>? = nil

          // Cache for the stored charge session context
          var currentSessionContext: ChargeSessionContext? = nil

          // Flag to stop processing further charge session context updates after an error
          var pollingStreamFinished = false

          // Observe changes to the stored charge session context
          for await sessionContext in Defaults.updates(sessionContextKey) {
            // If the stream has already been finished due to an error, break early
            if pollingStreamFinished {
              break
            }

            // If sessionContext is nil, cancel polling and yield inactive
            guard let newSessionContext = sessionContext else {
              pollingTask?.cancel()
              pollingTask = nil
              currentSessionContext = nil
              continuation.yield(.inactive)
              continue
            }

            // If the session context hasn’t changed, skip starting a new polling task
            if let current = currentSessionContext, current == newSessionContext {
              continue
            }

            // A new session context is available: cancel any previous polling task
            pollingTask?.cancel()
            pollingTask = nil
            currentSessionContext = newSessionContext

            // Yield an initial active state without session data
            continuation.yield(.active(nil))

            // Start a new polling task
            pollingTask = Task {
              let authentication = newSessionContext.authentication
              let stream = await chargeProvider.sharedSessionUpdates(with: authentication)
              do {
                for try await session in stream {
                  // Check that this polling task is still valid
                  if Task.isCancelled || currentSessionContext != newSessionContext {
                    break
                  }

                  // Yield the session data
                  let sessionData = ChargeSession.Update.SessionData(
                    consumption: session.consumption.measurement,
                  )

                  continuation.yield(.active(sessionData))
                }

                // If the polling loop ended naturally and the stored session context is still
                // current, throw an error and finish the stream
                if currentSessionContext == newSessionContext {
                  pollingStreamFinished = true
                  continuation.finish(throwing: NetworkError.cannotParseClientRequest)
                }
              } catch {
                // If an error occurred (and it wasn’t due to cancellation), yield an error update
                if !Task.isCancelled, currentSessionContext == newSessionContext {
                  pollingStreamFinished = true
                  continuation.finish(throwing: error)
                }
              }
            }
          }
        }

        // If the stream is terminated externally, cancel the outer task
        continuation.onTermination = { _ in
          outerTask.cancel()
        }
      }
    }
  }
}
