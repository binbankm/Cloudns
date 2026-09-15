import Foundation

// MARK: - AnyJSONValue (Unified Dynamic JSON Value, Swift 6 Sendable)

public indirect enum AnyJSONValue: Codable, Equatable, Sendable, CustomStringConvertible {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([AnyJSONValue])
    case dictionary([String: AnyJSONValue])
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let b = try? container.decode(Bool.self) {
            self = .bool(b)
        } else if let i = try? container.decode(Int.self) {
            self = .int(i)
        } else if let d = try? container.decode(Double.self) {
            self = .double(d)
        } else if let s = try? container.decode(String.self) {
            self = .string(s)
        } else if let arr = try? container.decode([AnyJSONValue].self) {
            self = .array(arr)
        } else if let dict = try? container.decode([String: AnyJSONValue].self) {
            self = .dictionary(dict)
        } else {
            self = .null
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .string(s): try container.encode(s)
        case let .int(i): try container.encode(i)
        case let .double(d): try container.encode(d)
        case let .bool(b): try container.encode(b)
        case let .array(a): try container.encode(a)
        case let .dictionary(d): try container.encode(d)
        case .null: try container.encodeNil()
        }
    }

    public var description: String {
        switch self {
        case let .string(s):
            return s
        case let .int(i):
            return String(i)
        case let .double(d):
            return String(d)
        case let .bool(b):
            return b ? "true" : "false"
        case let .array(arr):
            return "[" + arr.map(\.description).joined(separator: ", ") + "]"
        case let .dictionary(dict):
            let pairs = dict.sorted { $0.key < $1.key }
                .map { "\($0.key): \($0.value.description)" }
            return "{" + pairs.joined(separator: ", ") + "}"
        case .null:
            return "null"
        }
    }

    public var displayText: String {
        switch self {
        case let .string(value):
            return value
        case let .int(value):
            return String(value)
        case let .double(value):
            return value.truncatingRemainder(dividingBy: 1) == 0
                ? String(Int(value))
                : String(value)
        case let .bool(value):
            return value ? "true" : "false"
        case .null:
            return "null"
        case let .array(values):
            return "[" + values.map(\.displayText).joined(separator: ", ") + "]"
        case let .dictionary(dict):
            let pairs = dict.sorted { $0.key < $1.key }
                .map { "\($0.key): \($0.value.displayText)" }
            return "{" + pairs.joined(separator: ", ") + "}"
        }
    }

    public var prettyJSONString: String {
        switch self {
        case let .string(s):
            return s
        case .dictionary, .array:
            if let data = try? JSONSerialization.data(withJSONObject: rawObject, options: [.prettyPrinted, .sortedKeys]),
               let str = String(data: data, encoding: .utf8) {
                return str
            }
            return description
        default:
            return description
        }
    }

    public var rawObject: Any {
        switch self {
        case let .string(s):
            s
        case let .int(i):
            i
        case let .double(d):
            d
        case let .bool(b):
            b
        case let .array(a):
            a.map(\.rawObject)
        case let .dictionary(d):
            d.mapValues { $0.rawObject }
        case .null:
            NSNull()
        }
    }

    public var stringValue: String? {
        switch self {
        case let .string(s):
            s
        case let .int(i):
            String(i)
        case let .double(d):
            String(d)
        case let .bool(b):
            b ? "true" : "false"
        default:
            nil
        }
    }

    public var intValue: Int? {
        switch self {
        case let .int(i):
            i
        case let .double(d):
            Int(d)
        default:
            nil
        }
    }

    public var doubleValue: Double? {
        switch self {
        case let .double(d):
            d
        case let .int(i):
            Double(i)
        default:
            nil
        }
    }

    public var boolValue: Bool? {
        if case let .bool(b) = self {
            return b
        }
        return nil
    }

    public var arrayValue: [AnyJSONValue]? {
        if case let .array(arr) = self {
            return arr
        }
        return nil
    }

    public var dictionaryValue: [String: AnyJSONValue]? {
        if case let .dictionary(dict) = self {
            return dict
        }
        return nil
    }

    public subscript(key: String) -> AnyJSONValue? {
        if case let .dictionary(dict) = self {
            return dict[key]
        }
        return nil
    }

    public subscript(index: Int) -> AnyJSONValue? {
        if case let .array(arr) = self, arr.indices.contains(index) {
            return arr[index]
        }
        return nil
    }

    // MARK: - Factory Helpers for Compatibility

    public static func number(_ value: Double) -> AnyJSONValue {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return .int(Int(value))
        }
        return .double(value)
    }

    public static func object(_ dict: [String: AnyJSONValue]) -> AnyJSONValue {
        .dictionary(dict)
    }
}

// MARK: - Global Typealias for Legacy Code

public typealias JSONValue = AnyJSONValue
