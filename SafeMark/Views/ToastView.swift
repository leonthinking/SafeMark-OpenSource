import SwiftUI

enum ToastStyle {
    case success
    case error
    
    var iconName: String {
        switch self {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "xmark.circle.fill"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .success:
            return .green
        case .error:
            return .red
        }
    }
}

struct ToastView: View {
    let message: String
    let style: ToastStyle
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: style.iconName)
                    .foregroundColor(style.iconColor)
                    .font(.system(size: 20))
                
                Text(message)
                    .font(.system(size: 15))
                    .foregroundColor(Color.primary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 2)
        )
        .padding(.horizontal, 16)
        .frame(minWidth: 0, maxWidth: .infinity)
    }
}

struct Toast: ViewModifier {
    @Binding var isShowing: Bool
    let message: String
    let style: ToastStyle
    let duration: TimeInterval
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isShowing {
                VStack {
                    // 从顶部开始，预留一些空间
                    Spacer().frame(height: 60)
                    
                    ToastView(message: message, style: style)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                                withAnimation {
                                    isShowing = false
                                }
                            }
                        }
                    
                    Spacer()
                }
                .animation(.easeInOut, value: isShowing)
                .zIndex(100)
            }
        }
    }
}

extension View {
    func toast(isShowing: Binding<Bool>, message: String, style: ToastStyle, duration: TimeInterval = 3.0) -> some View {
        self.modifier(Toast(isShowing: isShowing, message: message, style: style, duration: duration))
    }
}

// 预览视图
struct ToastView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ToastView(message: NSLocalizedString("已保存到系统相册", comment: ""), style: .success)
                .padding()
            
            ToastView(message: NSLocalizedString("保存失败", comment: ""), style: .error)
                .padding()
        }
    }
}