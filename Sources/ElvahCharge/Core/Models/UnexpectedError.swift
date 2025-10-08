// Copyright © elvah. All rights reserved.

package struct UnexpectedError: Error, Equatable {
  package let serverCode: String?
  package let statusCode: Int?
  package let debugTitle: String?
  package let debugMessage: String?

  package init(
    serverCode: String? = nil,
    statusCode: Int? = nil,
    debugTitle: String? = nil,
    debugMessage: String? = nil,
  ) {
    self.serverCode = serverCode
    self.statusCode = statusCode
    self.debugTitle = debugTitle
    self.debugMessage = debugMessage
  }
}
