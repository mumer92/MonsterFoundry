import Foundation

enum APIKeyStore {
    static func value(for key: String) -> String? {
        guard let url = Bundle.main.url(forResource: "keys", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil),
              let values = plist as? [String: Any],
              let rawValue = values[key] as? String else {
            return nil
        }

        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.count > 20 ? value : nil
    }
}
