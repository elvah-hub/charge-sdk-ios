// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
extension View {
  func bottomSheet(
    isPresented: Binding<Bool>,
    onDismiss: (() -> Void)? = nil,
    @ViewBuilder content: @escaping () -> some View,
    @ViewBuilder footer: @escaping () -> some View,
  ) -> some View {
    modifier(
      BottomSheet(
        isPresented: isPresented,
        onDismiss: onDismiss,
        sheetContent: content,
        footer: footer,
      ),
    )
  }
}

@available(iOS 16.0, *)
private struct BottomSheet<SheetContent: View, Footer: View>: ViewModifier {
  var isPresented: Binding<Bool>
  let onDismiss: (() -> Void)?
  let sheetContent: SheetContent
  let footer: Footer

  init(
    isPresented: Binding<Bool>,
    onDismiss: (() -> Void)?,
    @ViewBuilder sheetContent: () -> SheetContent,
    @ViewBuilder footer: () -> Footer,
  ) {
    self.isPresented = isPresented
    self.onDismiss = onDismiss
    self.sheetContent = sheetContent()
    self.footer = footer()
  }

  func body(content: Content) -> some View {
    content
      .sheet(
        isPresented: isPresented,
        onDismiss: {
          onDismiss?()
        },
        content: {
          BottomSheetComponent(
            content: {
              sheetContent
            },
            footer: {
              footer
            },
          )
        },
      )
  }
}
