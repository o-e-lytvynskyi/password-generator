import Foundation

enum PasswordStrength: Int {
    case weak
    case medium
    case strong

    var label: String {
        switch self {
        case .weak: return "Weak"
        case .medium: return "Medium"
        case .strong: return "Strong"
        }
    }
}

struct PasswordOptions {
    var length: Int
    var useUppercase: Bool
    var useLowercase: Bool
    var useNumbers: Bool
    var useSymbols: Bool

    var hasAnySet: Bool {
        useUppercase || useLowercase || useNumbers || useSymbols
    }
}

enum PasswordGenerator {
    private static let uppercase = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    private static let lowercase = Array("abcdefghijklmnopqrstuvwxyz")
    private static let numbers = Array("0123456789")
    private static let symbols = Array("!@#$%^&*()-_=+[]{};:,.<>?/")

    /// Generates a random password honoring the selected character sets.
    /// Guarantees at least one character from every enabled set (when length allows).
    static func generate(_ options: PasswordOptions) -> String {
        var pools: [[Character]] = []
        if options.useUppercase { pools.append(uppercase) }
        if options.useLowercase { pools.append(lowercase) }
        if options.useNumbers { pools.append(numbers) }
        if options.useSymbols { pools.append(symbols) }

        guard !pools.isEmpty else { return "" }

        let combined = pools.flatMap { $0 }
        var result: [Character] = []

        // Ensure at least one char from each enabled pool.
        for pool in pools where result.count < options.length {
            if let c = pool.randomElement() {
                result.append(c)
            }
        }

        // Fill the rest from the combined pool.
        while result.count < options.length {
            if let c = combined.randomElement() {
                result.append(c)
            }
        }

        result.shuffle()
        return String(result)
    }

    static func strength(_ options: PasswordOptions) -> PasswordStrength {
        guard options.hasAnySet else { return .weak }

        var poolSize = 0
        if options.useUppercase { poolSize += uppercase.count }
        if options.useLowercase { poolSize += lowercase.count }
        if options.useNumbers { poolSize += numbers.count }
        if options.useSymbols { poolSize += symbols.count }

        // Shannon-style entropy estimate: length * log2(poolSize)
        let entropy = Double(options.length) * log2(Double(max(poolSize, 1)))

        switch entropy {
        case ..<40: return .weak
        case 40..<70: return .medium
        default: return .strong
        }
    }
}
