// Copyright © elvah. All rights reserved.

import Defaults
import MessageUI
import SwiftUI

@available(iOS 16.0, *)
struct SupportBottomSheet: View {
	@Environment(\.dynamicTypeSize) private var dynamicTypeSize
	@Environment(\.dismiss) private var dismiss
	@Environment(\.openURL) private var openURL
	@ObservedObject var router: SupportBottomSheet.Router
	@Default(.chargeSessionContext) private var chargeSessionContext

	var body: some View {
		BottomSheetComponent(
			title: "Help & Support",
			canBeDismissed: true,
			isExpandable: false
		) {
			content
		} footer: {
			if let supportMethods = chargeSessionContext?.organisationDetails.supportMethods {
				ButtonStack {
					ForEach(supportMethods.sorted().filter(\.isPhoneOrUrl)) { supportMethod in
						switch supportMethod {
						case let .phone(number):
							phoneButton(for: number)
						case let .website(url):
							urlButton(for: url)
						default:
							EmptyView()
						}
					}

					let emailAndWhatsAppMethods = supportMethods.sorted().filter(\.isEmailOrWhatsApp)
					if emailAndWhatsAppMethods.isEmpty == false {
						ButtonStack(axis: .horizontal) {
							ForEach(emailAndWhatsAppMethods) { supportMethod in
								switch supportMethod {
								case let .email(email):
									mailButton(for: email)
								case let .whatsApp(number):
									whatsAppButton(for: number)
								default:
									EmptyView()
								}
							}
						}
					}
				}
			}
		}
	}

	@ViewBuilder private var content: some View {
		VStack(spacing: 20) {
			CPOLogo(url: chargeSessionContext?.organisationDetails.logoUrl)
			if let companyName = chargeSessionContext?.organisationDetails.companyName {
				Text("Contact '\(companyName)' for help and support")
					.typography(.title(size: .small), weight: .bold)
					.fixedSize(horizontal: false, vertical: true)
					.multilineTextAlignment(.center)
			}
		}
		.padding(.horizontal)
	}

	@ViewBuilder private func phoneButton(for number: String) -> some View {
		if let url = URL(string: "tel:\(number)") {
			Button(icon: .phone) {
				openURL(url)
			} title: {
				ViewThatFits(in: .horizontal) {
					Text(number)
					Text("Call", bundle: .elvahCharge)
				}
			}
			.buttonStyle(.secondary)
		}
	}

	@ViewBuilder private func urlButton(for url: URL) -> some View {
		Button(icon: .agent) {
			openURL(url)
		} title: {
			ViewThatFits(in: .horizontal) {
				Text("Contact Web Support Agent", bundle: .elvahCharge)
				Text("Web Support", bundle: .elvahCharge)
			}
		}
		.buttonStyle(.secondary)
	}

	@ViewBuilder private func mailButton(for email: String) -> some View {
		if let url = makeMailtoSupportLink(recipient: email) {
			Button("E-Mail", icon: .envelope, bundle: .elvahCharge) {
				openURL(url)
			}
			.buttonStyle(.secondary)
		}
	}

	@ViewBuilder private func whatsAppButton(for number: String) -> some View {
		if let url = makeWhatsAppLink(number: number) {
			Button("WhatsApp", icon: .whatsapp, bundle: .elvahCharge) {
				openURL(url)
			}
			.buttonStyle(.secondary)
		}
	}

	// MARK: - Helpers

	private func makeWhatsAppLink(number: String) -> URL? {
		// Remove any non-digit characters (spaces, brackets, dashes, plus signs)
		let digitsOnly = number.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()

		// Remove any leading zeros
		let formattedNumber = digitsOnly.replacingOccurrences(
			of: "^0+",
			with: "",
			options: .regularExpression
		)

		// Make sure we have a valid number after formatting
		guard !formattedNumber.isEmpty else {
			return nil
		}

		return URL(string: "https://wa.me/\(formattedNumber)")
	}

	private func makeMailtoSupportLink(recipient: String) -> URL? {
		let subject = "Support"
		guard let url = URL(string: "mailto:\(recipient)?subject=\(subject)"),
		      UIApplication.shared.canOpenURL(url)
		else {
			return nil
		}
		return url
	}
}

@available(iOS 16.0, *)
extension SupportBottomSheet {
	@MainActor
	final class Router: BaseRouter {
		func reset() {}
	}
}

@available(iOS 16.0, *)
#Preview {
	SupportBottomSheet(router: .init())
		.withFontRegistration()
		.preferredColorScheme(.dark)
}
