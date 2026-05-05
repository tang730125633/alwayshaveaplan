import Foundation

struct FocusSessionRecord {
    let taskTitle: String
    let noteText: String
    let startedAt: Date
    let endedAt: Date
}

final class ObsidianDailyNoteService {
    private let fileManager = FileManager.default
    private let calendar = Calendar.current
    private let headingTodayGoals = "## 今日目标"
    private let headingTodayRecord = "## 今日记录"
    private let headingTaskRecords = "### 任务记录"
    private let headingReview = "## 今日复盘"
    private let headingTomorrow = "## 明日计划"

    func appendFocusSession(_ record: FocusSessionRecord) {
        do {
            guard let diaryRoot = try resolveDiaryRoot() else {
                Log.error("Obsidian sync skipped: diary root not found")
                return
            }

            let dailyNoteURL = try ensureDailyNoteExists(in: diaryRoot, for: record.endedAt)
            try append(record, to: dailyNoteURL)
            Log.info("Obsidian sync completed: \(dailyNoteURL.path)")
        } catch {
            Log.error("Obsidian sync failed: \(error)")
        }
    }

    func normalizeTodayNoteIfNeeded(referenceDate: Date = Date()) {
        do {
            guard let diaryRoot = try resolveDiaryRoot() else {
                Log.error("Obsidian normalize skipped: diary root not found")
                return
            }

            let dailyNoteURL = try ensureDailyNoteExists(in: diaryRoot, for: referenceDate)
            let originalContent = try String(contentsOf: dailyNoteURL, encoding: .utf8)
            let normalizedContent = normalizeDailyNoteLayout(originalContent)

            guard normalizedContent != originalContent else {
                Log.info("Obsidian normalize skipped: today's note already matches layout")
                return
            }

            try normalizedContent.write(to: dailyNoteURL, atomically: true, encoding: .utf8)
            Log.info("Obsidian normalize completed: \(dailyNoteURL.path)")
        } catch {
            Log.error("Obsidian normalize failed: \(error)")
        }
    }

    private func resolveDiaryRoot() throws -> URL? {
        let home = fileManager.homeDirectoryForCurrentUser
        let candidates = [
            home
                .appendingPathComponent("Library", isDirectory: true)
                .appendingPathComponent("Mobile Documents", isDirectory: true)
                .appendingPathComponent("iCloud~md~obsidian", isDirectory: true)
                .appendingPathComponent("Documents", isDirectory: true)
                .appendingPathComponent("Workshop", isDirectory: true)
                .appendingPathComponent("📓 睡前写-日记", isDirectory: true)
        ]

        for candidate in candidates where fileManager.fileExists(atPath: candidate.path) {
            return candidate
        }

        let workshopRoot = home
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Mobile Documents", isDirectory: true)
            .appendingPathComponent("iCloud~md~obsidian", isDirectory: true)
            .appendingPathComponent("Documents", isDirectory: true)
            .appendingPathComponent("Workshop", isDirectory: true)

        guard let enumerator = fileManager.enumerator(
            at: workshopRoot,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }

        for case let url as URL in enumerator {
            let values = try url.resourceValues(forKeys: [.isDirectoryKey])
            guard values.isDirectory == true else { continue }
            if url.lastPathComponent.contains("睡前写") {
                return url
            }
        }

        return nil
    }

    private func ensureDailyNoteExists(in diaryRoot: URL, for date: Date) throws -> URL {
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)

        let dayName = "\(month)月\(day)日"
        let noteDirectory = diaryRoot
            .appendingPathComponent("\(year)年", isDirectory: true)
            .appendingPathComponent("\(month)月", isDirectory: true)
            .appendingPathComponent(dayName, isDirectory: true)

        try fileManager.createDirectory(at: noteDirectory, withIntermediateDirectories: true)

        let noteURL = noteDirectory.appendingPathComponent("\(dayName).md")
        if !fileManager.fileExists(atPath: noteURL.path) {
            let content = makeDailyNoteTemplate(for: date)
            try content.write(to: noteURL, atomically: true, encoding: .utf8)
        }

        return noteURL
    }

    private func makeDailyNoteTemplate(for date: Date) -> String {
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let weekday = weekdaySymbol(for: date)
        let todayName = "\(month)月\(day)日"

        guard
            let previousDate = calendar.date(byAdding: .day, value: -1, to: date),
            let nextDate = calendar.date(byAdding: .day, value: 1, to: date)
        else {
            return "# \(todayName) \(weekday)\n\n\(headingTodayGoals)\n- [ ] \n\n\(headingTodayRecord)\n\n\(headingTaskRecords)\n\n\(headingReview)\n\n\(headingTomorrow)\n"
        }

        return "[[\(dayLink(for: previousDate))]] | [[\(dayLink(for: nextDate))]]\n\n---\n\n# \(todayName) \(weekday)\n\n\(headingTodayGoals)\n- [ ] \n\n\(headingTodayRecord)\n\n\(headingTaskRecords)\n\n\(headingReview)\n\n\(headingTomorrow)\n"
    }

    private func append(_ record: FocusSessionRecord, to noteURL: URL) throws {
        var content = try String(contentsOf: noteURL, encoding: .utf8)
        content = normalizeDailyNoteLayout(content)

        let entry = makeFocusEntry(for: record)

        if let reviewRange = content.range(of: "\n\(headingReview)") {
            let insertion = ensureTaskSectionExists(in: String(content[..<reviewRange.lowerBound])) + entry
            content.replaceSubrange(..<reviewRange.lowerBound, with: insertion)
        } else {
            content = ensureTaskSectionExists(in: content) + entry
        }

        try content.write(to: noteURL, atomically: true, encoding: .utf8)
    }

    private func normalizeDailyNoteLayout(_ content: String) -> String {
        var normalized = content.replacingOccurrences(of: "\r\n", with: "\n")
        normalized = normalized.replacingOccurrences(of: "### 专注空间", with: headingTaskRecords)

        normalized = ensureSection(
            headingTodayGoals,
            in: normalized,
            content: "- [ ]"
        )
        normalized = ensureSection(
            headingTodayRecord,
            in: normalized
        )
        normalized = ensureTaskSectionExists(in: normalized)
        normalized = ensureSection(
            headingReview,
            in: normalized
        )
        normalized = ensureSection(
            headingTomorrow,
            in: normalized
        )

        return normalized.hasSuffix("\n") ? normalized : normalized + "\n"
    }

    private func ensureSection(_ heading: String, in content: String, content body: String? = nil) -> String {
        guard !content.contains(heading) else { return content }

        var updated = content
        if !updated.hasSuffix("\n") {
            updated += "\n"
        }

        updated += "\n\(heading)\n"
        if let body, !body.isEmpty {
            updated += "\(body)\n"
        }

        return updated
    }

    private func ensureTaskSectionExists(in content: String) -> String {
        if content.contains(headingTaskRecords) {
            return content.hasSuffix("\n\n") ? content : content + "\n\n"
        }

        guard let todayRecordRange = content.range(of: headingTodayRecord) else {
            let normalized = ensureSection(headingTodayRecord, in: content)
            return ensureTaskSectionExists(in: normalized)
        }

        let afterRecordHeading = content[todayRecordRange.upperBound...]
        if let nextTopLevelRange = afterRecordHeading.range(of: "\n## ") {
            let insertionPoint = nextTopLevelRange.lowerBound
            var updated = content
            updated.insert(contentsOf: "\n\n\(headingTaskRecords)\n", at: insertionPoint)
            return updated
        }

        let normalized = content.hasSuffix("\n") ? content : content + "\n"
        return normalized + "\n\(headingTaskRecords)\n"
    }

    private func makeFocusEntry(for record: FocusSessionRecord) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        let durationMinutes = max(Int(record.endedAt.timeIntervalSince(record.startedAt) / 60), 1)
        let noteBody = record.noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        let renderedBody = noteBody.isEmpty ? "_这次专注没有留下额外文字。_" : noteBody

        return "#### \(timeFormatter.string(from: record.startedAt)) - \(timeFormatter.string(from: record.endedAt))｜\(record.taskTitle)\n- 专注时长：\(durationMinutes) 分钟\n- 来源：AlwaysHaveAPlan\n\n\(renderedBody)\n\n"
    }

    private func weekdaySymbol(for date: Date) -> String {
        let index = calendar.component(.weekday, from: date) - 1
        let weekdays = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        return weekdays[index]
    }

    private func dayLink(for date: Date) -> String {
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        return "\(month)月\(day)日"
    }
}