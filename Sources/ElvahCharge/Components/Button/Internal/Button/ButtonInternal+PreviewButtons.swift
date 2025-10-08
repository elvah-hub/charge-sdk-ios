// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
extension ButtonInternal {
  struct PreviewButtons: View {
    var body: some View {
      ScrollView {
        VStack {
          VStack {
            Button(Text(verbatim: "Sign in"), icon: .notificationBell) {}
            Button(Text(verbatim: "Sign in"), icon: .notificationBell) {}.loading(true)
            Button(Text(verbatim: "Sign in"), icon: .notificationBell) {}.disabled(true)
            Button(Text(verbatim: "Sign in"), icon: .notificationBell) {}.redacted(reason: .placeholder)
          }
          HStack(alignment: .top) {
            VStack {
              Button(Text(verbatim: "Sign in"), icon: .chevronSmallRight) {}
              Button(Text(verbatim: "Sign in"), icon: .chevronSmallRight) {}.loading(true)
              Button(Text(verbatim: "Sign in"), icon: .chevronSmallRight) {}.disabled(true)
              Button(Text(verbatim: "Sign in"), icon: .chevronSmallRight) {}.redacted(reason: .placeholder)
            }
            .controlSize(.small)
            VStack {
              Button(Text(verbatim: "Sign in")) {}
              Button(Text(verbatim: "Sign in")) {}.loading(true)
              Button(Text(verbatim: "Sign in")) {}.disabled(true)
              Button(Text(verbatim: "Sign in")) {}.redacted(reason: .placeholder)
            }
            .controlSize(.small)
            VStack {
              Button(icon: .share) {}
              Button(icon: .share) {}.loading(true)
              Button(icon: .share) {}.disabled(true)
              Button(icon: .share) {}.redacted(reason: .placeholder)
            }
            VStack {
              Button(icon: .share) {}
              Button(icon: .share) {}.loading(true)
              Button(icon: .share) {}.disabled(true)
              Button(icon: .share) {}.redacted(reason: .placeholder)
            }
            .controlSize(.small)
          }
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
      }
      .background(.canvas)
    }
  }
}

@available(iOS 16.0, *)
#Preview {
  ButtonInternal.PreviewButtons()
    .buttonStyle(.primary)
    .withFontRegistration()
}
