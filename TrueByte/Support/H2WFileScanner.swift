import Foundation

struct H2WFile {
    var url: URL
    var index: Int?
    var size: UInt64
}

enum H2WFileScanner {
    static func allH2WFiles(in directory: URL) throws -> [H2WFile] {
        let urls = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        )

        return try urls.compactMap { url in
            let name = url.lastPathComponent.lowercased()
            guard name.hasSuffix(".h2w") else { return nil }

            let values = try url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
            guard values.isRegularFile == true else { return nil }

            let baseName = String(name.dropLast(4))
            return H2WFile(
                url: url,
                index: Int(baseName),
                size: UInt64(values.fileSize ?? 0)
            )
        }
        .sorted { lhs, rhs in
            switch (lhs.index, rhs.index) {
            case let (left?, right?): left < right
            case (_?, nil): true
            case (nil, _?): false
            case (nil, nil): lhs.url.lastPathComponent < rhs.url.lastPathComponent
            }
        }
    }

    static func numberedFiles(in directory: URL) throws -> [H2WFile] {
        try allH2WFiles(in: directory).filter { $0.index != nil }
    }
}
