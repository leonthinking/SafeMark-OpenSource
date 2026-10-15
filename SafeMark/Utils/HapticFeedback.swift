import UIKit
import SwiftUI

/// 提供轻柔的震动反馈体验
class HapticFeedback {
    /// 轻度触感反馈（适用于轻点操作）
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// 中度触感反馈（适用于确认操作）
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// 重度触感反馈（适用于重要操作）
    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// 成功触感反馈
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
    
    /// 警告触感反馈
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }
    
    /// 错误触感反馈
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }
    
    /// 选择触感反馈
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}

// 提供 ViewModifier 用于更方便地在视图中使用触感反馈
struct HapticButtonModifier: ViewModifier {
    let feedbackStyle: HapticFeedbackStyle
    
    enum HapticFeedbackStyle {
        case light, medium, heavy, success, warning, error, selection
    }
    
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                switch feedbackStyle {
                case .light:
                    HapticFeedback.light()
                case .medium:
                    HapticFeedback.medium()
                case .heavy:
                    HapticFeedback.heavy()
                case .success:
                    HapticFeedback.success()
                case .warning:
                    HapticFeedback.warning()
                case .error:
                    HapticFeedback.error()
                case .selection:
                    HapticFeedback.selection()
                }
            }
    }
}

// 扩展 View 以提供方便的修饰器
extension View {
    func hapticFeedback(_ style: HapticButtonModifier.HapticFeedbackStyle) -> some View {
        self.modifier(HapticButtonModifier(feedbackStyle: style))
    }
} 