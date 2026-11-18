
import Foundation

enum CurrencyFormatter {
    static func format(_ amount: Double) -> String {
        let currency = UserDefaults.standard.string(
            forKey: "selectedCurrency"
        ) ?? "PHP"

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 2

        return formatter.string(
            from: NSNumber(value: amount)
        ) ?? "\(amount)"
    }
}
