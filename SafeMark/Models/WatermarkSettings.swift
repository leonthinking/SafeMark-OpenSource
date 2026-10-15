import SwiftUI
import Combine

class WatermarkSettings: ObservableObject, Equatable {
    // UserDefaults键值
    private static let userTextKey = "userWatermarkText"
    private static let defaultText = "仅用于申请 xx 信用卡使用，他用无效"
    
    @Published var text: String {
        didSet {
            // 当文本被修改时，保存到UserDefaults
            if text != oldValue {
                saveTextToUserDefaults()
            }
        }
    }
    @Published var fontSize: CGFloat = 60
    @Published var opacity: Double = 0.5
    @Published var color: Color = .white
    @Published var position: CGSize = .zero
    @Published var angle: Double = -45  // 水印旋转角度，单位为度
    @Published var space: CGFloat = 6 // 水印间距系数
    
    // 预设颜色选项
    static let colorOptions: [Color] = [.white, .black, .red, .blue]
    
    // 字体大小范围
    static let fontSizeRange: ClosedRange<CGFloat> = 30...100
    
    // 透明度范围
    static let opacityRange: ClosedRange<Double> = 0.1...1.0
    
    // 角度范围
    static let angleRange: ClosedRange<Double> = -45...45
    
    // 间距范围
    static let spaceRange: ClosedRange<CGFloat> = 3...12
    
    // 初始化，读取存储的文本或使用默认值
    init() {
        // 从UserDefaults加载保存的文本，如果没有则使用默认值
        self.text = UserDefaults.standard.string(forKey: WatermarkSettings.userTextKey) ?? WatermarkSettings.defaultText
    }
    
    // 保存文本到UserDefaults
    private func saveTextToUserDefaults() {
        UserDefaults.standard.set(text, forKey: WatermarkSettings.userTextKey)
    }
    
    // 重置为默认设置
    func resetToDefault() {
        text = WatermarkSettings.defaultText
        fontSize = 60
        opacity = 0.5
        color = .white
        position = .zero
        angle = -45
        space = 6
    }
    
    // 实现Equatable协议
    static func == (lhs: WatermarkSettings, rhs: WatermarkSettings) -> Bool {
        return lhs.text == rhs.text &&
               lhs.fontSize == rhs.fontSize &&
               lhs.opacity == rhs.opacity &&
               lhs.color == rhs.color &&
               lhs.position == rhs.position &&
               lhs.angle == rhs.angle &&
               lhs.space == rhs.space
    }
} 
