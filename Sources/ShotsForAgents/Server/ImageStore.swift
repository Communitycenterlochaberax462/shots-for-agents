import Foundation

actor ImageStore {
    struct Entry {
        let data: Data
        let createdAt: Date
        var firstReadAt: Date?
    }

    private var entries: [UUID: Entry] = [:]

    func store(_ data: Data) -> UUID {
        let id = UUID()
        entries[id] = Entry(data: data, createdAt: Date())

        // Enforce max count — drop oldest if over limit
        if entries.count > Constants.maxScreenshots {
            if let oldest = entries.min(by: { $0.value.createdAt < $1.value.createdAt }) {
                entries.removeValue(forKey: oldest.key)
            }
        }

        return id
    }

    func fetch(_ id: UUID) -> Data? {
        guard var entry = entries[id] else { return nil }

        // Mark first read time — image stays alive for readWindowSeconds after first read
        if entry.firstReadAt == nil {
            entry.firstReadAt = Date()
            entries[id] = entry
        }

        return entry.data
    }

    func sweepExpired() {
        let creationCutoff = Date().addingTimeInterval(-Constants.ttlSeconds)
        let readCutoff = Date().addingTimeInterval(-Constants.readWindowSeconds)

        entries = entries.filter { _, entry in
            // Remove if older than TTL (never read)
            if entry.createdAt < creationCutoff { return false }
            // Remove if read window expired (was read and window passed)
            if let firstRead = entry.firstReadAt, firstRead < readCutoff { return false }
            return true
        }
    }

    func pendingCount() -> Int {
        entries.count
    }
}
