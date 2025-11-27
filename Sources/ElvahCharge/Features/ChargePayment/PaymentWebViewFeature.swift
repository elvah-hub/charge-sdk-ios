// Copyright © elvah. All rights reserved.

import SwiftUI
import WebKit
#if canImport(Core)
  import Core
#endif

/// Hosts the Apple Pay web checkout built from a base URL and optional query parameters, then reports when the flow completes, fails, or is dismissed.
@available(iOS 16.0, *)
struct PaymentWebViewFeature: View {
  @Environment(\.dismiss) private var dismiss
  @State private var hasReportedCompletion = false

  /// Default redirect endpoints emitted by the hosted web experience.
  static let successRedirectPath = "/success"
  static let errorRedirectPath = "/error"

  var paymentBaseURL: URL
  var parameters: Parameters
  var successRedirectPath: String
  var errorRedirectPath: String
  var completion: (Completion) -> Void

  private var paymentURL: URL {
    guard var components = URLComponents(url: paymentBaseURL, resolvingAgainstBaseURL: false) else {
      return paymentBaseURL
    }

    let updatedQueryItems = mergeQueryItems(
      existing: components.queryItems ?? [],
      newItems: parameters.queryItems,
    )

    components.queryItems = updatedQueryItems.isEmpty ? nil : updatedQueryItems
    return components.url ?? paymentBaseURL
  }

  init(
    paymentBaseURL: URL,
    parameters: Parameters,
    successRedirectPath: String = PaymentWebViewFeature.successRedirectPath,
    errorRedirectPath: String = PaymentWebViewFeature.errorRedirectPath,
    completion: @escaping (Completion) -> Void,
  ) {
    self.paymentBaseURL = paymentBaseURL
    self.parameters = parameters
    self.successRedirectPath = successRedirectPath
    self.errorRedirectPath = errorRedirectPath
    self.completion = completion
  }

  var body: some View {
    ApplePayWebView(
      paymentURL: paymentURL,
      successRedirectPath: successRedirectPath,
      errorRedirectPath: errorRedirectPath,
      completion: { completionResult in
        reportCompletionIfNeeded(completionResult)
      },
    )
    .ignoresSafeArea()
    .onDisappear {
      reportCompletionIfNeeded(.cancelled)
    }
  }

  private func reportCompletionIfNeeded(_ completionResult: Completion) {
    guard hasReportedCompletion == false else {
      return
    }

    hasReportedCompletion = true
    completion(completionResult)

    switch completionResult {
    case .completed,
         .failed:
      dismiss()
    case .cancelled:
      break
    }
  }

  enum Completion {
    /// JavaScript or redirect reported a successful payment; a payment intent ID might be present.
    case completed(paymentIntentId: String?)
    /// Loading failed or the experience redirected to the error path.
    case failed
    /// The user dismissed the sheet without reaching success or failure.
    case cancelled
  }
}

@available(iOS 16.0, *)
extension PaymentWebViewFeature {
  // TODO: Finalize the parameters for the web view
  struct Parameters {
    var brandColor: String
    var clientSecret: String
    var paymentIntentId: String
    var customItems: [URLQueryItem] = []

    var queryItems: [URLQueryItem] {
      var items: [URLQueryItem] = []
      items.append(URLQueryItem(name: "brandColor", value: brandColor))
      items.append(URLQueryItem(name: "clientSecret", value: clientSecret))
      items.append(URLQueryItem(name: "paymentIntentId", value: paymentIntentId))
      return mergeQueryItems(existing: items, newItems: customItems)
    }
  }
}

private func mergeQueryItems(existing: [URLQueryItem], newItems: [URLQueryItem]) -> [URLQueryItem] {
  newItems.reduce(into: existing) { combined, newItem in
    combined.removeAll { $0.name == newItem.name }
    combined.append(newItem)
  }
}

@available(iOS 16.0, *)
private struct ApplePayWebView: UIViewRepresentable {
  var paymentURL: URL
  var successRedirectPath: String
  var errorRedirectPath: String
  var completion: (PaymentWebViewFeature.Completion) -> Void

  func makeCoordinator() -> Coordinator {
    Coordinator(
      successRedirectPath: successRedirectPath,
      errorRedirectPath: errorRedirectPath,
      completion: completion,
    )
  }

  func makeUIView(context: Context) -> WKWebView {
    let configuration = WKWebViewConfiguration()

    let webView = WKWebView(frame: .zero, configuration: configuration)
    webView.navigationDelegate = context.coordinator
    context.coordinator.observe(webView: webView)
    webView.load(URLRequest(url: paymentURL))
    return webView
  }

  func updateUIView(_ uiView: WKWebView, context: Context) {
    if uiView.url == nil || uiView.url != paymentURL {
      uiView.load(URLRequest(url: paymentURL))
    }
  }

  static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
    coordinator.invalidate()
  }

  /// Presents Stripe's hosted Apple Pay experience inside a WKWebView and forwards progress through the coordinator.
  @MainActor
  final class Coordinator: NSObject, WKNavigationDelegate {
    private let successRedirectPath: String
    private let errorRedirectPath: String
    private let completion: (PaymentWebViewFeature.Completion) -> Void
    private weak var webView: WKWebView?
    private var hasProvidedCompletion = false

    init(
      successRedirectPath: String,
      errorRedirectPath: String,
      completion: @escaping (PaymentWebViewFeature.Completion) -> Void,
    ) {
      self.successRedirectPath = successRedirectPath.lowercased()
      self.errorRedirectPath = errorRedirectPath.lowercased()
      self.completion = completion
    }

    func observe(webView: WKWebView) {
      self.webView = webView
    }

    func webView(
      _ webView: WKWebView,
      decidePolicyFor navigationAction: WKNavigationAction,
      decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void,
    ) {
      if navigationAction.targetFrame?.isMainFrame == true, let url = navigationAction.request.url {
        handlePotentialCompletion(with: url)
      }
      decisionHandler(.allow)
    }

    func invalidate() {
      webView = nil
    }

    func webView(
      _ webView: WKWebView,
      didFailProvisionalNavigation navigation: WKNavigation!,
      withError error: Error,
    ) {
      handleFailure(for: webView, navigation: navigation, error: error)
    }

    func webView(
      _ webView: WKWebView,
      didFail navigation: WKNavigation!,
      withError error: Error,
    ) {
      handleFailure(for: webView, navigation: navigation, error: error)
    }

    private func handlePotentialCompletion(with url: URL) {
      let path = url.path.lowercased()
      if matches(path: path, targetRedirectPath: successRedirectPath) {
        let paymentIntentId = extractPaymentIntentId(from: url)
        handleSuccess(paymentIntentId: paymentIntentId)
      } else if matches(path: path, targetRedirectPath: errorRedirectPath) {
        guard let webView else {
          return
        }
        handleFailure(
          for: webView,
          navigation: nil,
          error: WebViewError.redirectedToErrorPath,
        )
      }
    }

    private func handleSuccess(paymentIntentId: String?) {
      guard hasProvidedCompletion == false else {
        return
      }

      hasProvidedCompletion = true
      webView?.stopLoading()
      let completion = completion
      completion(.completed(paymentIntentId: paymentIntentId))
    }

    private func handleFailure(for webView: WKWebView, navigation: WKNavigation?, error: Error) {
      if shouldIgnoreFailure(error) {
        return
      }

      guard hasProvidedCompletion == false else {
        return
      }

      hasProvidedCompletion = true
      let navigationState = navigation == nil ? "nil navigation" : "has navigation"
      Elvah.logger.error("Apple Pay web view failed (\(navigationState)): \(error.localizedDescription)")

      webView.stopLoading()
      let completion = completion
      completion(.failed)
    }

    private func shouldIgnoreFailure(_ error: Error) -> Bool {
      let nsError = error as NSError
      return nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled
    }

    private func extractPaymentIntentId(from url: URL) -> String? {
      guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
        return nil
      }
      return components.queryItems?.first { $0.name == "paymentIntentId" }?.value
    }

    private func extractPaymentIntentId(from payload: [String: Any]) -> String? {
      if let rawPaymentIntentId = payload["paymentIntentId"] as? String {
        return rawPaymentIntentId
      }
      if let data = payload["data"] as? [String: Any], let rawPaymentIntentId = data["paymentIntentId"] as? String {
        return rawPaymentIntentId
      }
      return nil
    }

    private func matches(path: String, targetRedirectPath: String) -> Bool {
      // Accept both absolute match and trailing match so nested paths (e.g., /checkout/success) are handled.
      path == targetRedirectPath || path.hasSuffix(targetRedirectPath)
    }

    private enum WebViewError: LocalizedError {
      case redirectedToErrorPath

      var errorDescription: String? {
        "Apple Pay web view reached the error redirect path."
      }
    }
  }
}
