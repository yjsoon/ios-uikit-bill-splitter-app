import Foundation

/// Shared formatter responsible for currency formatting and input sanitisation.
public final class CurrencyFormatter {
    public static let shared = CurrencyFormatter()

    private let formatter: NumberFormatter
    private let decimalScale: Decimal = 100

    private init() {
        formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "SGD"
        formatter.locale = Locale(identifier: "en_SG")
        formatter.usesGroupingSeparator = true
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
    }

    /// Formats a decimal value to an SGD currency string.
    public func string(from decimal: Decimal) -> String {
        let number = NSDecimalNumber(decimal: decimal)
        return formatter.string(from: number) ?? formatter.currencySymbol + "0.00"
    }

    /// Returns the formatted string and decimal value that should replace the current text field contents.
    /// - Parameters:
    ///   - currentText: The existing text in the field.
    ///   - range: The range to be replaced.
    ///   - replacement: The incoming replacement string from `shouldChangeCharactersIn`.
    public func formattedReplacement(currentText: String, range: NSRange, replacement: String) -> (formatted: String, decimal: Decimal?)? {
        guard let textRange = Range(range, in: currentText) else { return nil }
        let updatedText = currentText.replacingCharacters(in: textRange, with: replacement)

        let digits = digitsOnly(from: updatedText)
        guard !digits.isEmpty else {
            return ("", nil)
        }

        let decimalValue = decimal(fromDigits: digits)
        let formattedString = string(from: decimalValue)
        return (formattedString, decimalValue)
    }

    // MARK: - Helpers

    private func digitsOnly(from string: String) -> String {
        return string.filter(\.isNumber)
    }

    private func decimal(fromDigits digits: String) -> Decimal {
        guard let integerValue = Decimal(string: digits) else { return 0 }
        var value = integerValue
        value /= decimalScale
        return value
    }
}
