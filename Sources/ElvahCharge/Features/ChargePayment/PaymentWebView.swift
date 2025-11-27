// Copyright © elvah. All rights reserved.

import SwiftUI
import WebKit

@available(iOS 16.0, *)
struct PaymentWebView: View {
  @Environment(\.dismiss) private var dismiss

  var paymentURL: URL
  var onPaymentCompleted: (String?) -> Void

  init(paymentURL: URL, onPaymentCompleted: @escaping (String?) -> Void = { _ in }) {
    self.paymentURL = paymentURL
    self.onPaymentCompleted = onPaymentCompleted
  }

  var body: some View {
    ApplePayWebView(
      paymentURL: paymentURL,
      onPaymentCompleted: { paymentIntentId in
        onPaymentCompleted(paymentIntentId)
        dismiss()
      },
    )
    .ignoresSafeArea()
  }
}

@available(iOS 16.0, *)
private struct ApplePayWebView: UIViewRepresentable {
  var paymentURL: URL
  var onPaymentCompleted: (String?) -> Void

  func makeCoordinator() -> Coordinator {
    Coordinator(onPaymentCompleted: onPaymentCompleted)
  }

  func makeUIView(context: Context) -> WKWebView {
    let userContentController = WKUserContentController()
    for handlerName in Coordinator.handlerNames {
      userContentController.add(context.coordinator, name: handlerName)
    }

    let configuration = WKWebViewConfiguration()
    configuration.userContentController = userContentController

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
    for handlerName in Coordinator.handlerNames {
      uiView.configuration.userContentController.removeScriptMessageHandler(forName: handlerName)
    }
    coordinator.invalidate()
  }

  @MainActor
  final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    static let handlerNames = [
      "stripePaymentSucceeded",
      "paymentSucceeded",
      "paymentCompleted",
    ]
    private static let successTypes: Set<String> = [
      "stripe-payment-succeeded",
      "paymentSucceeded",
      "paymentCompleted",
    ]

    private let onPaymentCompleted: (String?) -> Void
    private weak var webView: WKWebView?
    private var hasCompleted = false

    init(onPaymentCompleted: @escaping (String?) -> Void) {
      self.onPaymentCompleted = onPaymentCompleted
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

    func userContentController(
      _: WKUserContentController,
      didReceive message: WKScriptMessage,
    ) {
      guard Coordinator.handlerNames.contains(message.name) else {
        return
      }

      if let payload = message.body as? [String: Any] {
        if let rawType = payload["type"] as? String, Coordinator.successTypes.contains(rawType) == false {
          return
        }
        handleCompletion(paymentIntentId: extractPaymentIntentId(from: payload))
      } else if let rawPaymentIntentId = message.body as? String {
        handleCompletion(paymentIntentId: rawPaymentIntentId)
      } else {
        handleCompletion(paymentIntentId: nil)
      }
    }

    func invalidate() {
      webView = nil
    }

    private func handlePotentialCompletion(with url: URL) {
      let path = url.path.lowercased()
      guard path == "/success" || path.hasSuffix("/success") else {
        return
      }

      let paymentIntentId = extractPaymentIntentId(from: url)
      handleCompletion(paymentIntentId: paymentIntentId)
    }

    private func handleCompletion(paymentIntentId: String?) {
      guard hasCompleted == false else {
        return
      }

      hasCompleted = true
      webView?.stopLoading()
      let completion = onPaymentCompleted
      DispatchQueue.main.async {
        completion(paymentIntentId)
      }
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
  }
}
