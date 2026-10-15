import Foundation

/// Public project destinations. Forks should replace the repository URL with their own.
enum ProjectLinks {
    static let repository = URL(string: "https://github.com/leonthinking/SafeMark-OpenSource")!
    static let feedback = repository.appendingPathComponent("issues")
}
