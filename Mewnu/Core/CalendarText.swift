import Foundation

enum CalendarText {
    private static let entityPattern = try! NSRegularExpression(pattern: "&(#(?:x[0-9A-Fa-f]+|[0-9]+)|amp|lt|gt|quot|apos|nbsp);")

    static func decoded(_ value: String) -> String {
        let matches = entityPattern.matches(in: value, range: NSRange(value.startIndex..., in: value))
        guard !matches.isEmpty else { return value }
        var result = value
        for match in matches.reversed() {
            guard let fullRange = Range(match.range, in: result),
                  let nameRange = Range(match.range(at: 1), in: result),
                  let replacement = replacement(for: String(result[nameRange])) else { continue }
            result.replaceSubrange(fullRange, with: replacement)
        }
        return result
    }

    private static func replacement(for entity: String) -> String? {
        switch entity {
        case "amp": return "&"
        case "lt": return "<"
        case "gt": return ">"
        case "quot": return "\""
        case "apos": return "'"
        case "nbsp": return "\u{00A0}"
        default:
            guard entity.hasPrefix("#") else { return nil }
            let isHex = entity.hasPrefix("#x")
            let digits = String(entity.dropFirst(isHex ? 2 : 1))
            guard let code = UInt32(digits, radix: isHex ? 16 : 10),
                  let scalar = Unicode.Scalar(code) else { return nil }
            return String(scalar)
        }
    }
}
