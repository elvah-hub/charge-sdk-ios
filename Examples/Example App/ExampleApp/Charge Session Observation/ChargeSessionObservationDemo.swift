// Copyright elvah. All rights reserved.

import ElvahCharge
import SwiftUI

struct ChargeSessionObservationDemo: View {
  @State private var isChargeSessionActive = false
  @State private var showChargeSession = false

  var body: some View {
    List {
      Section("Session Status") {
        LabeledContent("Charge Session Active", value: "\(isChargeSessionActive)")
      }
      Section {
        Button("Show Charge Session") {
          showChargeSession = true
        }
//        .disabled(isChargeSessionActive == false)
      }
    }
    .navigationTitle("Session Observation")
    .navigationBarTitleDisplayMode(.inline)
    .chargeSessionPresentation(isPresented: $showChargeSession)
    .task {
      await observeChargeSession()
    }
  }

  private func observeChargeSession() async {
    do {
      for try await update in ChargeSession.updates() {
        isChargeSessionActive = update.isActive
        switch update {
        case .inactive:
          print("Session is inactive")
        case let .active(sessionData):
          print("Session is active. Session Data: \(String(describing: sessionData))")
        }
      }
    } catch {
      print("Error: \(error)")
    }
  }
}

#Preview {
  ChargeSessionObservationDemo()
    .preferredColorScheme(.dark)
}
