// Copyright © elvah. All rights reserved.

import SwiftUI

@available(iOS 16.0, *)
extension View {
	/// Observes active discount slots in a pricing schedule and notifies when changes occur.
	///
	/// The modifier continuously monitors the pricing schedule, calling the onChange handler when:
	/// - A discount slot becomes active
	/// - The current discount slot expires
	/// - The schedule changes
	///
	/// - Parameters:
	///   - schedule: The pricing schedule to observe.
	///   - onChange: A closure called with the currently active discount slot (or nil if none is active).
	/// - Returns: A view that observes discount slot changes.
	func onActiveDiscountSlotChange(
		in schedule: PricingSchedule?,
		perform onChange: @escaping (PricingSchedule.DiscountSlot?) -> Void,
	) -> some View {
		modifier(ActiveDiscountSlotModifier(schedule: schedule, onChange: onChange))
	}
}

@available(iOS 16.0, *)
private struct ActiveDiscountSlotModifier: ViewModifier {
	var schedule: PricingSchedule?
	var onChange: (PricingSchedule.DiscountSlot?) -> Void

	func body(content: Content) -> some View {
		content
			.task(id: schedule) {
				await observeDiscountSlots()
			}
	}

	private func observeDiscountSlots() async {
		guard let schedule else {
			onChange(nil)
			return
		}

		while !Task.isCancelled {
			let now = Date()

			// Check for active slot
			if let activeSlot = schedule.activeDiscount(at: now) {
				onChange(activeSlot)

				// Wait until this slot expires
				if let endDate = activeSlot.to.date(on: now), await sleepUntil(endDate, from: now) {
					// Sleep was interrupted, exit
					return
				}

				// Slot has expired, clear and continue loop
				onChange(nil)
			} else {
				// No active slot, find the next upcoming slot
				onChange(nil)

				guard let nextSlotStartDate = findNextDiscountStart(in: schedule, after: now) else {
					// No upcoming slots in the schedule (yesterday/today/tomorrow), stop observing
					return
				}

				if await sleepUntil(nextSlotStartDate, from: now) {
					// Sleep was interrupted, exit
					return
				}
				// Loop will re-check and activate the slot
			}
		}
	}

	/// Sleeps until the target date is reached.
	/// - Parameters:
	///   - targetDate: The date to sleep until
	///   - referenceDate: The current date
	/// - Returns: `true` if sleep was interrupted (task cancelled), `false` if completed normally
	private func sleepUntil(_ targetDate: Date, from referenceDate: Date) async -> Bool {
		let delaySeconds = targetDate.timeIntervalSince(referenceDate)
		guard delaySeconds > 0 else {
			return false
		}

		do {
			try await Task.sleep(for: .seconds(delaySeconds))
			return false
		} catch is CancellationError {
			return true
		} catch {
			return true
		}
	}

	/// Finds the next discount slot start time across all available days in the schedule.
	/// - Parameters:
	///   - schedule: The pricing schedule to search
	///   - referenceDate: The current date/time
	/// - Returns: The date when the next discount slot begins, or nil if none found
	private func findNextDiscountStart(in schedule: PricingSchedule, after referenceDate: Date) -> Date? {
		let calendar = Calendar.current

		// Collect all potential upcoming slots from today/tomorrow
		var upcomingSlots: [(date: Date, slot: PricingSchedule.DiscountSlot)] = []

		// Check today's slots
		if let today = schedule.dailyPricing.today {
			for slot in today.discounts {
				if let startDate = slot.from.date(on: referenceDate), startDate > referenceDate {
					upcomingSlots.append((startDate, slot))
				}
			}
		}

		// Check tomorrow's slots
		if let tomorrow = schedule.dailyPricing.tomorrow {
			if let tomorrowDate = calendar.date(byAdding: .day, value: 1, to: referenceDate) {
				for slot in tomorrow.discounts {
					if let startDate = slot.from.date(on: tomorrowDate), startDate > referenceDate {
						upcomingSlots.append((startDate, slot))
					}
				}
			}
		}

		// Return the earliest upcoming slot
		return upcomingSlots.min(by: { $0.date < $1.date })?.date
	}
}
