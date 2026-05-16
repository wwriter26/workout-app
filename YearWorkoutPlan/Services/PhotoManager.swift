import UIKit
import Foundation

// MARK: - Photo Side
/// The three angles captured for each progress photo entry.
enum PhotoSide: String, CaseIterable {
    case front, side, back
}

// MARK: - PhotoManager
/// Static helpers for persisting and retrieving progress photos.
///
/// Design decisions:
/// - Stored in the app's Documents directory (not Library/Caches) because progress
///   photos are user-generated data that should survive low-storage purges. The
///   "progress/" sub-directory keeps them isolated from any future document exports.
/// - JPEG at 0.8 compression is a good trade-off: visually lossless for a 12MP
///   photo at display size, while keeping per-photo size to ~300-500 KB.
/// - Returns the absolute path string rather than a URL so it round-trips cleanly
///   through Codable's String fields in PhotoEntry without a custom encoder.
/// - This is intentionally a pure-static namespace (not a class/actor) because
///   the operations are atomic file I/O with no shared mutable state. Concurrency
///   safety comes from the fact that each file path is unique per side+date combo.
enum PhotoManager {

    // MARK: - Errors

    enum Error: Swift.Error, LocalizedError {
        case imageEncodingFailed
        case documentsDirectoryUnavailable

        var errorDescription: String? {
            switch self {
            case .imageEncodingFailed:
                return "Failed to encode image as JPEG."
            case .documentsDirectoryUnavailable:
                return "Cannot access the app's Documents directory."
            }
        }
    }

    // MARK: - Save

    /// Saves a UIImage to `<Documents>/progress/{yyyy-MM-dd}_{side}.jpg`.
    /// Returns the absolute file path string for storage in `PhotoEntry`.
    static func saveProgressPhoto(
        _ image: UIImage,
        side: PhotoSide,
        date: Date
    ) throws -> String {
        let progressDir = try progressDirectory()

        let dateString = isoDateString(from: date)
        let filename = "\(dateString)_\(side.rawValue).jpg"
        let fileURL = progressDir.appendingPathComponent(filename)

        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw Error.imageEncodingFailed
        }
        try data.write(to: fileURL, options: .atomic)
        return fileURL.path
    }

    // MARK: - Load

    /// Loads a UIImage from a stored absolute path string.
    /// Returns nil silently if the file doesn't exist (e.g. after a reinstall).
    static func load(fromPath path: String) -> UIImage? {
        UIImage(contentsOfFile: path)
    }

    // MARK: - Delete

    /// Removes the file at `path`. Throws if deletion fails for any reason other
    /// than the file not existing (missing file is a no-op, not an error).
    static func delete(path: String) throws {
        let fm = FileManager.default
        guard fm.fileExists(atPath: path) else { return }
        try fm.removeItem(atPath: path)
    }

    // MARK: - Private Helpers

    /// Returns the progress/ sub-directory URL, creating it if needed.
    private static func progressDirectory() throws -> URL {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        guard let docs = urls.first else {
            throw Error.documentsDirectoryUnavailable
        }
        let progressDir = docs.appendingPathComponent("progress", isDirectory: true)

        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: progressDir.path,
                                                    isDirectory: &isDirectory)
        if !exists || !isDirectory.boolValue {
            try FileManager.default.createDirectory(
                at: progressDir,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
        return progressDir
    }

    /// ISO 8601 date string (`yyyy-MM-dd`) used in filenames so they sort
    /// chronologically and remain locale-independent.
    private static func isoDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
}
