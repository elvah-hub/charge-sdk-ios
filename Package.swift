// swift-tools-version: 6.0

import PackageDescription

let package = Package(
	name: "charge-sdk-ios",
	defaultLocalization: "en",
	platforms: [.iOS(.v15), .macOS(.v11)],
	products: [
		.library(
			name: "ElvahCharge",
			targets: ["ElvahCharge"]
		),
	],
	dependencies: [
		.package(url: "https://github.com/stripe/stripe-ios", from: "24.6.0"),
		.package(url: "https://github.com/kean/Get", from: "2.2.1"),
		.package(url: "https://github.com/sindresorhus/Defaults", from: "8.2.0"),
	],
	targets: [
		.target(
			name: "ElvahCharge",
			dependencies: [
				.product(name: "Get", package: "Get"),
				.product(name: "Defaults", package: "Defaults"),
				.product(name: "Stripe", package: "stripe-ios"),
				.product(name: "StripePaymentSheet", package: "stripe-ios"),
			],
			path: "Sources/ElvahCharge",
			exclude: ["Core/Note.txt"],
			resources: [
				.copy("PrivacyInfo.xcprivacy"),
				.copy("Core/Resources/Colors.xcassets"),
				.copy("Core/Resources/Inter.ttf"),
				.copy("Resources/Images.xcassets"),
				.copy("Resources/Localizable.xcstrings"),
			]
		),
		.testTarget(
			name: "Tests",
			dependencies: [
				"ElvahCharge",
				"Get",
				"Defaults",
			]
		),
	]
)
