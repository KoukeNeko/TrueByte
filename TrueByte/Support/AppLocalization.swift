import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case zhHant = "zh-Hant"
    case en = "en"
    case ja = "ja"

    var id: String { rawValue }

    static var defaultLanguage: AppLanguage {
        let preferred = Locale.preferredLanguages.first?.lowercased() ?? ""
        if preferred.hasPrefix("ja") {
            return .ja
        }
        if preferred.hasPrefix("zh") {
            return .zhHant
        }
        return .en
    }

    var strings: AppStrings {
        AppStrings(language: self)
    }

    var toolbarTitle: String {
        switch self {
        case .zhHant: "繁"
        case .en: "EN"
        case .ja: "日"
        }
    }

    var displayName: String {
        switch self {
        case .zhHant: "繁體中文"
        case .en: "English"
        case .ja: "日本語"
        }
    }
}

struct AppStrings: Sendable {
    var language: AppLanguage

    var appSubtitle: String {
        switch language {
        case .zhHant: "H2 風格媒體驗證"
        case .en: "H2-style media verification"
        case .ja: "H2 形式のメディア検証"
        }
    }

    var languagePickerLabel: String {
        switch language {
        case .zhHant: "語言"
        case .en: "Language"
        case .ja: "言語"
        }
    }

    var languagePickerHelp: String {
        switch language {
        case .zhHant: "切換介面語言"
        case .en: "Change the interface language"
        case .ja: "表示言語を切り替えます"
        }
    }

    var target: String {
        switch language {
        case .zhHant: "目標"
        case .en: "Target"
        case .ja: "対象"
        }
    }

    var change: String {
        switch language {
        case .zhHant: "更改"
        case .en: "Change"
        case .ja: "変更"
        }
    }

    var selectTarget: String {
        switch language {
        case .zhHant: "選擇目標"
        case .en: "Select Target"
        case .ja: "対象を選択"
        }
    }

    var changeTarget: String {
        switch language {
        case .zhHant: "更改目標"
        case .en: "Change target"
        case .ja: "対象を変更"
        }
    }

    var available: String {
        switch language {
        case .zhHant: "可用"
        case .en: "Available"
        case .ja: "空き容量"
        }
    }

    var total: String {
        switch language {
        case .zhHant: "總容量"
        case .en: "Total"
        case .ja: "総容量"
        }
    }

    var mode: String {
        switch language {
        case .zhHant: "模式"
        case .en: "Mode"
        case .ja: "モード"
        }
    }

    var writeVerify: String {
        switch language {
        case .zhHant: "寫入 + 驗證"
        case .en: "Write + Verify"
        case .ja: "書き込み + 検証"
        }
    }

    var verifyOnly: String {
        switch language {
        case .zhHant: "只驗證"
        case .en: "Verify Only"
        case .ja: "検証のみ"
        }
    }

    var useAllAvailableSpace: String {
        switch language {
        case .zhHant: "使用所有可用空間"
        case .en: "Use all available space"
        case .ja: "すべての空き容量を使用"
        }
    }

    var size: String {
        switch language {
        case .zhHant: "大小"
        case .en: "Size"
        case .ja: "サイズ"
        }
    }

    var planned: String {
        switch language {
        case .zhHant: "預計"
        case .en: "Planned"
        case .ja: "予定"
        }
    }

    var reserved: String {
        switch language {
        case .zhHant: "預留"
        case .en: "Reserved"
        case .ja: "予約"
        }
    }

    var clearH2W: String {
        switch language {
        case .zhHant: "清除 .h2w"
        case .en: "Clear .h2w"
        case .ja: ".h2w を削除"
        }
    }

    var start: String {
        switch language {
        case .zhHant: "開始"
        case .en: "Start"
        case .ja: "開始"
        }
    }

    var verify: String {
        switch language {
        case .zhHant: "驗證"
        case .en: "Verify"
        case .ja: "検証"
        }
    }

    var stop: String {
        switch language {
        case .zhHant: "停止"
        case .en: "Stop"
        case .ja: "停止"
        }
    }

    var ready: String {
        switch language {
        case .zhHant: "就緒"
        case .en: "Ready"
        case .ja: "準備完了"
        }
    }

    var writing: String {
        switch language {
        case .zhHant: "寫入中"
        case .en: "Writing"
        case .ja: "書き込み中"
        }
    }

    var verifying: String {
        switch language {
        case .zhHant: "驗證中"
        case .en: "Verifying"
        case .ja: "検証中"
        }
    }

    var finished: String {
        switch language {
        case .zhHant: "完成"
        case .en: "Finished"
        case .ja: "完了"
        }
    }

    var failed: String {
        switch language {
        case .zhHant: "失敗"
        case .en: "Failed"
        case .ja: "失敗"
        }
    }

    var cancelled: String {
        switch language {
        case .zhHant: "已取消"
        case .en: "Cancelled"
        case .ja: "キャンセル済み"
        }
    }

    var selectTargetStatus: String {
        switch language {
        case .zhHant: "選擇目標"
        case .en: "Select a target"
        case .ja: "対象を選択"
        }
    }

    var noResult: String {
        switch language {
        case .zhHant: "無結果"
        case .en: "No Result"
        case .ja: "結果なし"
        }
    }

    var passed: String {
        switch language {
        case .zhHant: "通過"
        case .en: "Passed"
        case .ja: "合格"
        }
    }

    var noTestHasRun: String {
        switch language {
        case .zhHant: "尚未執行測試。"
        case .en: "No test has run yet."
        case .ja: "まだテストしていません。"
        }
    }

    var testCancelled: String {
        switch language {
        case .zhHant: "測試已取消。"
        case .en: "Test cancelled."
        case .ja: "テストはキャンセルされました。"
        }
    }

    var written: String {
        switch language {
        case .zhHant: "已寫入"
        case .en: "Written"
        case .ja: "書き込み済み"
        }
    }

    var verified: String {
        switch language {
        case .zhHant: "已驗證"
        case .en: "Verified"
        case .ja: "検証済み"
        }
    }

    var write: String {
        switch language {
        case .zhHant: "寫入"
        case .en: "Write"
        case .ja: "書き込み"
        }
    }

    var read: String {
        switch language {
        case .zhHant: "讀取"
        case .en: "Read"
        case .ja: "読み込み"
        }
    }

    var elapsed: String {
        switch language {
        case .zhHant: "已用時間"
        case .en: "Elapsed"
        case .ja: "経過"
        }
    }

    var remaining: String {
        switch language {
        case .zhHant: "剩餘"
        case .en: "Remaining"
        case .ja: "残り"
        }
    }

    var estimating: String {
        switch language {
        case .zhHant: "估算中"
        case .en: "Estimating"
        case .ja: "推定中"
        }
    }

    var ok: String {
        switch language {
        case .zhHant: "正常"
        case .en: "OK"
        case .ja: "OK"
        }
    }

    var dataLost: String {
        switch language {
        case .zhHant: "資料遺失"
        case .en: "Data Lost"
        case .ja: "データ欠損"
        }
    }

    var aliased: String {
        switch language {
        case .zhHant: "錯誤映射"
        case .en: "Aliased"
        case .ja: "エイリアス"
        }
    }

    var overwritten: String {
        switch language {
        case .zhHant: "被覆寫"
        case .en: "Overwritten"
        case .ja: "上書き"
        }
    }

    var slightlyChanged: String {
        switch language {
        case .zhHant: "輕微變更"
        case .en: "Slightly Changed"
        case .ja: "軽微な変化"
        }
    }

    var corrupted: String {
        switch language {
        case .zhHant: "損毀"
        case .en: "Corrupted"
        case .ja: "破損"
        }
    }

    var writeTime: String {
        switch language {
        case .zhHant: "寫入時間"
        case .en: "Write Time"
        case .ja: "書き込み時間"
        }
    }

    var verifyTime: String {
        switch language {
        case .zhHant: "驗證時間"
        case .en: "Verify Time"
        case .ja: "検証時間"
        }
    }

    var files: String {
        switch language {
        case .zhHant: "檔案"
        case .en: "Files"
        case .ja: "ファイル"
        }
    }

    var firstError: String {
        switch language {
        case .zhHant: "第一個錯誤"
        case .en: "First Error"
        case .ja: "最初のエラー"
        }
    }

    var offset: String {
        switch language {
        case .zhHant: "位移"
        case .en: "Offset"
        case .ja: "オフセット"
        }
    }

    var expected: String {
        switch language {
        case .zhHant: "預期"
        case .en: "Expected"
        case .ja: "期待値"
        }
    }

    var found: String {
        switch language {
        case .zhHant: "找到"
        case .en: "Found"
        case .ja: "検出値"
        }
    }

    var log: String {
        switch language {
        case .zhHant: "記錄"
        case .en: "Log"
        case .ja: "ログ"
        }
    }

    var noLogEntries: String {
        switch language {
        case .zhHant: "沒有記錄"
        case .en: "No log entries"
        case .ja: "ログはありません"
        }
    }

    var flushingFileData: String {
        switch language {
        case .zhHant: "正在將檔案資料刷新到媒體"
        case .en: "Flushing file data to media"
        case .ja: "ファイルデータをメディアへフラッシュ中"
        }
    }

    var flushingTakingLonger: String {
        switch language {
        case .zhHant: "正在將資料刷新到媒體，花費時間比平常久。慢速 USB 或快閃儲存可能會這樣。"
        case .en: "Flushing to media is taking longer than usual. This can happen on slow USB or flash storage."
        case .ja: "メディアへのフラッシュに通常より時間がかかっています。低速な USB やフラッシュストレージで起こることがあります。"
        }
    }

    var openPanelPrompt: String {
        switch language {
        case .zhHant: "選擇"
        case .en: "Select"
        case .ja: "選択"
        }
    }

    var openPanelMessage: String {
        switch language {
        case .zhHant: "選擇可寫入的卷宗或資料夾"
        case .en: "Choose a writable volume or folder"
        case .ja: "書き込み可能なボリュームまたはフォルダを選択してください"
        }
    }

    var deleteH2WTitle: String {
        switch language {
        case .zhHant: "刪除 .h2w 檔案？"
        case .en: "Delete .h2w files?"
        case .ja: ".h2w ファイルを削除しますか？"
        }
    }

    var deleteH2WMessage: String {
        switch language {
        case .zhHant: "這會移除所選目標中的 H2 風格測試檔案。"
        case .en: "This removes H2-style test files in the selected target."
        case .ja: "選択した対象内の H2 形式テストファイルを削除します。"
        }
    }

    var delete: String {
        switch language {
        case .zhHant: "刪除"
        case .en: "Delete"
        case .ja: "削除"
        }
    }

    var deletingH2WFiles: String {
        switch language {
        case .zhHant: "正在刪除 .h2w 檔案"
        case .en: "Deleting .h2w files"
        case .ja: ".h2w ファイルを削除中"
        }
    }

    var cancel: String {
        switch language {
        case .zhHant: "取消"
        case .en: "Cancel"
        case .ja: "キャンセル"
        }
    }

    var testMenuTitle: String {
        switch language {
        case .zhHant: "測試"
        case .en: "Test"
        case .ja: "テスト"
        }
    }

    func title(for mode: TestMode) -> String {
        switch mode {
        case .writeVerify: writeVerify
        case .verifyOnly: verifyOnly
        }
    }

    func title(for phase: TestPhase) -> String {
        switch phase {
        case .idle: ready
        case .writing: writing
        case .verifying: verifying
        case .finished: finished
        case .failed: failed
        case .cancelled: cancelled
        }
    }

    func title(for verdict: TestVerdict) -> String {
        switch verdict {
        case .notRun: noResult
        case .passed: passed
        case .failed: failed
        case .cancelled: cancelled
        }
    }

    func h2wFileSummary(count: Int, size: String) -> String {
        switch language {
        case .zhHant: "\(count) 個檔案 / \(size)"
        case .en: "\(count) files / \(size)"
        case .ja: "\(count) ファイル / \(size)"
        }
    }

    func fileTitle(index: Int, total: Int, name: String) -> String {
        switch language {
        case .zhHant: "檔案 \(index) / \(total)：\(name)"
        case .en: "File \(index) of \(total): \(name)"
        case .ja: "ファイル \(index) / \(total)：\(name)"
        }
    }

    func sectors(_ count: UInt64) -> String {
        switch language {
        case .zhHant: "\(count) 個磁區"
        case .en: "\(count) sectors"
        case .ja: "\(count) セクタ"
        }
    }

    func noByteProgress(seconds: Int) -> String {
        switch language {
        case .zhHant: "\(seconds) 秒沒有位元組進度。裝置可能正在重試寫入或暫時無回應。"
        case .en: "No byte progress for \(seconds)s. The device may be retrying writes or temporarily unresponsive."
        case .ja: "\(seconds) 秒間バイト進捗がありません。デバイスが書き込みを再試行しているか、一時的に応答していない可能性があります。"
        }
    }

    func storageError(_ error: StorageTestError) -> String {
        switch error {
        case .targetNotWritable:
            switch language {
            case .zhHant: "選擇的目標是唯讀。"
            case .en: "The selected target is read-only."
            case .ja: "選択した対象は読み取り専用です。"
            }
        case .noTarget:
            switch language {
            case .zhHant: "尚未選擇目標資料夾。"
            case .en: "No target folder selected."
            case .ja: "対象フォルダが選択されていません。"
            }
        case .noTestFiles:
            switch language {
            case .zhHant: "找不到編號的 .h2w 檔案。"
            case .en: "No numbered .h2w files were found."
            case .ja: "番号付きの .h2w ファイルが見つかりません。"
            }
        case .invalidSize:
            switch language {
            case .zhHant: "測試大小至少需要 1 MiB。"
            case .en: "The requested test size must be at least 1 MiB."
            case .ja: "要求されたテストサイズは 1 MiB 以上である必要があります。"
            }
        case .existingTestFiles(let count):
            switch language {
            case .zhHant: "\(count) 個既有 .h2w 檔案已在目標中。"
            case .en: "\(count) existing .h2w file(s) are already in the target."
            case .ja: "\(count) 個の既存 .h2w ファイルが対象にあります。"
            }
        case .unableToAccessSecurityScope:
            switch language {
            case .zhHant: "macOS 未授權存取選擇的目標。"
            case .en: "macOS did not grant access to the selected target."
            case .ja: "macOS が選択した対象へのアクセスを許可しませんでした。"
            }
        }
    }

    func message(for error: Error) -> String {
        if let storageError = error as? StorageTestError {
            return self.storageError(storageError)
        }
        return error.localizedDescription
    }

    func deletedFiles(_ count: Int) -> String {
        switch language {
        case .zhHant: "已刪除 \(count) 個 .h2w 檔案"
        case .en: "Deleted \(count) .h2w file(s)"
        case .ja: "\(count) 個の .h2w ファイルを削除しました"
        }
    }

    func writingTo(size: String, path: String) -> String {
        switch language {
        case .zhHant: "正在寫入 \(size) 到 \(path)"
        case .en: "Writing \(size) to \(path)"
        case .ja: "\(size) を \(path) に書き込み中"
        }
    }

    func leavingFree(_ size: String) -> String {
        switch language {
        case .zhHant: "預留 \(size) 作為檔案系統安全空間"
        case .en: "Leaving \(size) free for filesystem safety"
        case .ja: "ファイルシステム保護のため \(size) を空けています"
        }
    }

    var writingTestFiles: String {
        switch language {
        case .zhHant: "正在寫入測試檔案"
        case .en: "Writing test files"
        case .ja: "テストファイルを書き込み中"
        }
    }

    func writingFile(index: Int, total: Int) -> String {
        switch language {
        case .zhHant: "正在寫入檔案 \(index) / \(total)"
        case .en: "Writing file \(index) of \(total)"
        case .ja: "ファイル \(index) / \(total) を書き込み中"
        }
    }

    func writingFileName(_ name: String) -> String {
        switch language {
        case .zhHant: "正在寫入 \(name)"
        case .en: "Writing \(name)"
        case .ja: "\(name) を書き込み中"
        }
    }

    func flushingFileName(_ name: String) -> String {
        switch language {
        case .zhHant: "正在將 \(name) 刷新到媒體"
        case .en: "Flushing \(name) to media"
        case .ja: "\(name) をメディアへフラッシュ中"
        }
    }

    func writePassFinished(duration: String) -> String {
        switch language {
        case .zhHant: "寫入階段完成，用時 \(duration)"
        case .en: "Write pass finished in \(duration)"
        case .ja: "書き込みパスが \(duration) で完了しました"
        }
    }

    func verifyingExisting(_ count: Int) -> String {
        switch language {
        case .zhHant: "正在驗證 \(count) 個既有 .h2w 檔案"
        case .en: "Verifying \(count) existing .h2w file(s)"
        case .ja: "\(count) 個の既存 .h2w ファイルを検証中"
        }
    }

    var verifyingTestFiles: String {
        switch language {
        case .zhHant: "正在驗證測試檔案"
        case .en: "Verifying test files"
        case .ja: "テストファイルを検証中"
        }
    }

    func verifyingFile(index: Int, total: Int) -> String {
        switch language {
        case .zhHant: "正在驗證檔案 \(index) / \(total)"
        case .en: "Verifying file \(index) of \(total)"
        case .ja: "ファイル \(index) / \(total) を検証中"
        }
    }

    func verifyingFileName(_ name: String) -> String {
        switch language {
        case .zhHant: "正在驗證 \(name)"
        case .en: "Verifying \(name)"
        case .ja: "\(name) を検証中"
        }
    }

    var defectiveMediaMessage: String {
        switch language {
        case .zhHant: "媒體很可能有缺陷。"
        case .en: "The media is likely to be defective."
        case .ja: "メディアに欠陥がある可能性があります。"
        }
    }

    var successMessage: String {
        switch language {
        case .zhHant: "測試完成，沒有發現錯誤。"
        case .en: "Test finished without errors."
        case .ja: "テストは完了し、エラーは見つかりませんでした。"
        }
    }
}
