import Foundation
import Observation

// MARK: - Languages

/// User-facing language choice. `.system` follows the OS preferred language.
enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case system
    case russian
    case english

    var id: String { rawValue }

    /// Localized display name for the language selector (shown in its own language).
    var nativeName: String {
        switch self {
        case .system:  return "Система / System"
        case .russian: return "Русский"
        case .english: return "English"
        }
    }
}

/// Resolved language actually used for lookups (no `.system`).
enum Lang: Sendable { case ru, en }

// MARK: - String keys

/// Every user-facing string has a key here. Using an enum (not raw strings)
/// makes missing translations a compile-time concern and keeps the table
/// exhaustive.
enum LocKey: String, CaseIterable {
    // Navigation / sidebar
    case dashboard, sectionCleanup, sectionSystem, memoryRAM, selected, clean

    // Toolbar
    case scan, scanning, language

    // Dashboard
    case appTagline, runScanPrompt, scanNow, reclaimable, byCategory, found
    case freeDisk, ofTotal

    // Category detail
    case runScanCategory, nothingToClean, selectAll, deselectAll, cleanSelected
    case clearsContents, modeTrash, modeDelete, revealInFinder

    // Memory
    case memory, memoryLiveUsage, totalRAM, free, used, breakdown
    case appMemory, wired, compressed
    case freeInactiveTitle, freeInactiveDesc, purgeButton
    case purgedOK, purgeNeedsAdmin

    // Confirmation
    case confirmTitle, confirmPermanentWarning, cancel

    // Categories
    case catCachesName, catCachesBlurb
    case catLogsName, catLogsBlurb
    case catTrashName, catTrashBlurb
    case catDevName, catDevBlurb
}

// MARK: - String table

enum Strings {
    /// (ru, en) for every key.
    static let table: [LocKey: (ru: String, en: String)] = [
        .dashboard:       ("Обзор", "Dashboard"),
        .sectionCleanup:  ("Очистка", "Cleanup"),
        .sectionSystem:   ("Система", "System"),
        .memoryRAM:       ("Память (RAM)", "Memory (RAM)"),
        .selected:        ("Выбрано", "Selected"),
        .clean:           ("Очистить", "Clean"),

        .scan:            ("Сканировать", "Scan"),
        .scanning:        ("Сканирование…", "Scanning…"),
        .language:        ("Язык", "Language"),

        .appTagline:      ("Безопасный и прозрачный cleaner для macOS. Ничего не удаляется без вашего подтверждения.",
                           "A safe, transparent cleaner for macOS. Nothing is removed without your review."),
        .runScanPrompt:   ("Запустите сканирование, чтобы увидеть, что можно безопасно очистить.",
                           "Run a scan to see what can be safely cleaned."),
        .scanNow:         ("Сканировать сейчас", "Scan now"),
        .reclaimable:     ("Можно освободить", "Reclaimable"),
        .byCategory:      ("По категориям", "By category"),
        .found:           ("найдено", "found"),
        .freeDisk:        ("Свободно на диске", "Free disk"),
        .ofTotal:         ("из", "of"),

        .runScanCategory: ("Запустите сканирование, чтобы найти элементы в этой категории.",
                           "Run a scan to discover items in this category."),
        .nothingToClean:  ("Здесь нечего очищать. 🎉", "Nothing to clean here. 🎉"),
        .selectAll:       ("Выбрать всё", "Select all"),
        .deselectAll:     ("Снять выбор", "Deselect all"),
        .cleanSelected:   ("Очистить выбранное", "Clean selected"),
        .clearsContents:  ("очистка содержимого", "clears contents"),
        .modeTrash:       ("В корзину", "Trash"),
        .modeDelete:      ("Удалить", "Delete"),
        .revealInFinder:  ("Показать в Finder", "Reveal in Finder"),

        .memory:          ("Память", "Memory"),
        .memoryLiveUsage: ("Использование RAM в реальном времени. Обновляется автоматически.",
                           "Live RAM usage. Updates automatically."),
        .totalRAM:        ("Всего RAM", "Total RAM"),
        .free:            ("Свободно", "Free"),
        .used:            ("занято", "used"),
        .breakdown:       ("Распределение", "Breakdown"),
        .appMemory:       ("Память приложений", "App memory"),
        .wired:           ("Закреплённая", "Wired"),
        .compressed:      ("Сжатая", "Compressed"),
        .freeInactiveTitle: ("Освободить неактивную память", "Free inactive memory"),
        .freeInactiveDesc: ("macOS управляет RAM автоматически — её нельзя «почистить» удалением файлов. Эта кнопка просит ядро освободить неактивные и сжимаемые страницы. Эффект обычно недолгий и может кратко замедлить систему, пока кэши перестраиваются.",
                            "macOS manages RAM automatically — you can't \"clean\" it by deleting files. This asks the kernel to purge inactive and compressible pages. It rarely helps for long and may briefly slow the system as caches rebuild."),
        .purgeButton:     ("Освободить неактивную память", "Purge inactive memory"),
        .purgedOK:        ("Неактивная память освобождена.", "Inactive memory purged."),
        .purgeNeedsAdmin: ("Выполните `sudo purge` в Терминале — для этого нужны права администратора.",
                           "Run `sudo purge` in Terminal — this action needs admin rights."),

        .confirmTitle:    ("Подтвердите очистку", "Confirm cleanup"),
        .confirmPermanentWarning: ("Внимание: часть элементов будет удалена безвозвратно (минуя Корзину).",
                                   "Warning: some items will be deleted permanently (bypassing the Trash)."),
        .cancel:          ("Отмена", "Cancel"),

        .catCachesName:   ("Кэши приложений", "Application Caches"),
        .catCachesBlurb:  ("Кэши приложений в ~/Library/Caches. Приложения восстанавливают их автоматически.",
                           "Per-app caches in ~/Library/Caches. Apps rebuild these automatically."),
        .catLogsName:     ("Логи и отчёты о сбоях", "Logs & Crash Reports"),
        .catLogsBlurb:    ("Диагностические логи и отчёты о сбоях. Безопасно очищать после прочтения.",
                           "Diagnostic logs and crash reports. Safe to clear once read."),
        .catTrashName:    ("Корзина", "Trash"),
        .catTrashBlurb:   ("Очистите Корзину, чтобы сразу вернуть её место.",
                           "Empty the Trash to reclaim its space immediately."),
        .catDevName:      ("Мусор разработчика", "Developer Junk"),
        .catDevBlurb:     ("Артефакты сборки и кэши инструментов. Объёмные и полностью восстановимые.",
                           "Build artifacts and tool caches. Large and fully regenerable."),
    ]

    static func value(_ key: LocKey, _ lang: Lang) -> String {
        guard let pair = table[key] else { return key.rawValue }
        return lang == .ru ? pair.ru : pair.en
    }
}

// MARK: - Localizer

@MainActor
@Observable
final class Localizer {
    static let shared = Localizer()

    private static let defaultsKey = "app.language"

    var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: Self.defaultsKey) }
    }

    init() {
        if let raw = UserDefaults.standard.string(forKey: Self.defaultsKey),
           let stored = AppLanguage(rawValue: raw) {
            language = stored
        } else {
            language = .russian   // default to Russian on first launch
        }
    }

    /// The concrete language used for lookups right now.
    var resolved: Lang {
        switch language {
        case .russian: return .ru
        case .english: return .en
        case .system:  return Self.systemIsRussian ? .ru : .en
        }
    }

    static var systemIsRussian: Bool {
        let code = Locale.preferredLanguages.first?.lowercased() ?? "en"
        return code.hasPrefix("ru")
    }

    // Simple lookup.
    func callAsFunction(_ key: LocKey) -> String { Strings.value(key, resolved) }
    func string(_ key: LocKey) -> String { Strings.value(key, resolved) }

    // MARK: Composed / pluralized phrases

    /// Localized "<n> items" with correct Russian plural forms.
    func itemsCount(_ n: Int) -> String {
        switch resolved {
        case .ru: return "\(n) \(Self.ruItemWord(n))"
        case .en: return "\(n) \(n == 1 ? "item" : "items")"
        }
    }

    /// "<n> items · <size>"
    func itemsAndSize(_ n: Int, _ size: String) -> String {
        "\(itemsCount(n)) · \(size)"
    }

    /// "<n> selected · <size>"
    func selectedAndSize(_ n: Int, _ size: String) -> String {
        switch resolved {
        case .ru: return "Выбрано: \(itemsCount(n)) · \(size)"
        case .en: return "\(n) selected · \(size)"
        }
    }

    /// Scan/clean progress line, e.g. "Scanning Application Caches…".
    func scanningName(_ name: String) -> String {
        switch resolved {
        case .ru: return "Сканирование: \(name)…"
        case .en: return "Scanning \(name)…"
        }
    }

    func cleaningName(_ name: String) -> String {
        switch resolved {
        case .ru: return "Очистка: \(name)…"
        case .en: return "Cleaning \(name)…"
        }
    }

    /// Honest summary after a clean: distinguishes space reclaimed immediately
    /// (permanent delete) from space merely moved to the Trash.
    func cleanedSummary(deleted: Int64, trashed: Int64) -> String {
        let d = Format.size(deleted), t = Format.size(trashed)
        switch resolved {
        case .ru:
            if deleted > 0 && trashed > 0 { return "Удалено \(d) · в Корзину перемещено \(t)" }
            if trashed > 0 { return "В Корзину перемещено \(t) — место освободится после очистки Корзины" }
            if deleted > 0 { return "Освобождено \(d)" }
            return "Готово"
        case .en:
            if deleted > 0 && trashed > 0 { return "Deleted \(d) · moved \(t) to Trash" }
            if trashed > 0 { return "Moved \(t) to Trash — space frees up once the Trash is emptied" }
            if deleted > 0 { return "Freed \(d)" }
            return "Done"
        }
    }

    /// "Clean <size>"
    func cleanSize(_ size: String) -> String {
        switch resolved {
        case .ru: return "Очистить \(size)"
        case .en: return "Clean \(size)"
        }
    }

    /// Failure line shown after a clean.
    func failuresLine(_ n: Int) -> String {
        switch resolved {
        case .ru: return "Не удалось удалить \(itemsCount(n))."
        case .en: return "\(n) item(s) couldn't be removed."
        }
    }

    /// Confirmation message body.
    func confirmMessage(count: Int, size: String) -> String {
        switch resolved {
        case .ru: return "Будет очищено \(itemsCount(count)) на \(size). Продолжить?"
        case .en: return "About to clean \(itemsCount(count)) totaling \(size). Continue?"
        }
    }

    func purgeFailed(_ detail: String) -> String {
        switch resolved {
        case .ru: return "Не удалось освободить память: \(detail)"
        case .en: return "Couldn't purge memory: \(detail)"
        }
    }

    // MARK: Catalog helpers

    func name(_ category: CleanupCategory) -> String { string(category.nameKey) }
    func blurb(_ category: CleanupCategory) -> String { string(category.blurbKey) }

    /// Russian plural for the word "элемент".
    static func ruItemWord(_ n: Int) -> String {
        let mod10 = n % 10, mod100 = n % 100
        if mod10 == 1 && mod100 != 11 { return "элемент" }
        if (2...4).contains(mod10) && !(12...14).contains(mod100) { return "элемента" }
        return "элементов"
    }
}
