import Foundation

enum Constants {
    static let maxScreenshots = 50

    // MARK: - Defaults

    static let defaultPort = 9853
    static let defaultTTLMinutes = 10
    static let defaultReadWindowSeconds = 60

    // MARK: - UserDefaults-backed values

    static var port: UInt16 {
        let val = UserDefaults.standard.integer(forKey: "serverPort")
        return val > 0 ? UInt16(val) : UInt16(defaultPort)
    }

    static var ttlSeconds: TimeInterval {
        let min = UserDefaults.standard.integer(forKey: "ttlMinutes")
        return min > 0 ? TimeInterval(min * 60) : TimeInterval(defaultTTLMinutes * 60)
    }

    static var readWindowSeconds: TimeInterval {
        let sec = UserDefaults.standard.integer(forKey: "readWindowSeconds")
        return sec > 0 ? TimeInterval(sec) : TimeInterval(defaultReadWindowSeconds)
    }

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            "serverPort": defaultPort,
            "ttlMinutes": defaultTTLMinutes,
            "readWindowSeconds": defaultReadWindowSeconds,
        ])
    }
}
