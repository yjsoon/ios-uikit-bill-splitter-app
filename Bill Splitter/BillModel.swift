import Foundation

enum RoundingStrategy: CaseIterable {
    case none
    case roundUp
    case roundToNearestDollar

    var title: String {
        switch self {
        case .none:
            return "None"
        case .roundUp:
            return "Round Up"
        case .roundToNearestDollar:
            return "Nearest Dollar"
        }
    }

    func adjustedTotal(for amount: Decimal) -> Decimal {
        switch self {
        case .none:
            return amount
        case .roundUp:
            return amount.rounded(scale: 2, mode: .up)
        case .roundToNearestDollar:
            return amount.roundedToNearestDollar()
        }
    }

    func description(for difference: Decimal, using formatter: CurrencyFormatter) -> String? {
        let zero: Decimal = 0
        if difference == zero { return nil }

        let absoluteDifference = difference >= zero ? difference : -difference
        let prefix = difference >= zero ? "+" : "-"
        let formattedDifference = formatter.string(from: absoluteDifference)

        switch self {
        case .none:
            return nil
        case .roundUp:
            return "Rounded up by \(formattedDifference)."
        case .roundToNearestDollar:
            return "Rounded to nearest dollar (\(prefix)\(formattedDifference))."
        }
    }
}

struct BillModel {
    let billAmount: Decimal
    let gstEnabled: Bool
    let serviceEnabled: Bool
    let serviceRate: Decimal
    let gstRate: Decimal
    let partySize: Int
    let roundingStrategy: RoundingStrategy

    var subtotal: Decimal { billAmount }

    var serviceChargeAmount: Decimal {
        guard serviceEnabled else { return 0 }
        return subtotal * serviceRate
    }

    var gstAmount: Decimal {
        guard gstEnabled else { return 0 }
        let base = subtotal + serviceChargeAmount
        return base * gstRate
    }

    var totalAmount: Decimal {
        subtotal + serviceChargeAmount + gstAmount
    }

    var displayTotal: Decimal {
        roundingStrategy.adjustedTotal(for: totalAmount)
    }

    var displayPerPerson: Decimal {
        guard partySize > 0 else { return displayTotal }
        return displayTotal / Decimal(partySize)
    }

    func roundingDescription(using formatter: CurrencyFormatter) -> String? {
        let difference = displayTotal - totalAmount
        return roundingStrategy.description(for: difference, using: formatter)
    }
}

extension Decimal {
    func rounded(scale: Int, mode: NSDecimalNumber.RoundingMode) -> Decimal {
        var value = self
        var result = Decimal()
        NSDecimalRound(&result, &value, scale, mode)
        return result
    }

    func roundedToNearestDollar() -> Decimal {
        var value = self
        var result = Decimal()
        NSDecimalRound(&result, &value, 0, .plain)
        return result
    }
}
