import Testing
import UIKit
@testable import SafeMark

@Suite(.serialized)
@MainActor
struct SafeMarkTests {
    @Test(arguments: [false, true])
    func watermarkChangesPixelsAndExportsJPEG(repeating: Bool) throws {
        let previousText = UserDefaults.standard.object(forKey: "userWatermarkText")
        defer {
            if let previousText {
                UserDefaults.standard.set(previousText, forKey: "userWatermarkText")
            } else {
                UserDefaults.standard.removeObject(forKey: "userWatermarkText")
            }
        }
        let source = UIGraphicsImageRenderer(size: CGSize(width: 400, height: 300)).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 400, height: 300))
        }
        let settings = WatermarkSettings()
        settings.text = ""
        let blank = ImageRenderer.render(image: source, settings: settings, repeatingMode: repeating)
        settings.text = "SAMPLE"
        settings.color = .black
        settings.opacity = 1
        let result = ImageRenderer.render(image: source, settings: settings, repeatingMode: repeating)
        #expect(result.size == source.size)
        let renderedPNG = try #require(result.pngData())
        let blankPNG = try #require(blank.pngData())
        #expect(renderedPNG != blankPNG)
        let encoded = try #require(result.jpegData(compressionQuality: 0.6))
        let decoded = try #require(UIImage(data: encoded))
        #expect(decoded.cgImage?.width == result.cgImage?.width)
        #expect(decoded.cgImage?.height == result.cgImage?.height)
    }
}
