import SwiftUI
import Photos
import UIKit
import Combine

// 将EditorView的逻辑部分移到类中，以便使用@objc
class ImageSaver: NSObject {
    var onSuccess: () -> Void = {}
    var onFailure: (Error) -> Void = { _ in }
    
    @objc func saveImage(_ image: UIImage) {
        // 先将图片压缩并转换为JPEG格式
        if let jpegData = image.jpegData(compressionQuality: 0.6),
           let compressedImage = UIImage(data: jpegData) {
            // 检查图片尺寸，如果过大则进一步缩小
            let maxDimension: CGFloat = 2000
            let finalImage: UIImage
            
            if compressedImage.size.width > maxDimension || compressedImage.size.height > maxDimension {
                finalImage = resizeImage(image: compressedImage, targetSize: calculateAspectRatioFit(
                    sourceWidth: compressedImage.size.width,
                    sourceHeight: compressedImage.size.height,
                    maxWidth: maxDimension,
                    maxHeight: maxDimension
                ))
            } else {
                finalImage = compressedImage
            }
            
            // 保存压缩后的图片
            UIImageWriteToSavedPhotosAlbum(finalImage, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        } else {
            // 如果压缩失败，尝试直接保存原图
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            onFailure(error)
        } else {
            onSuccess()
        }
    }
    
    // 计算等比例缩放的目标尺寸
    private func calculateAspectRatioFit(sourceWidth: CGFloat, sourceHeight: CGFloat, maxWidth: CGFloat, maxHeight: CGFloat) -> CGSize {
        var targetWidth = sourceWidth
        var targetHeight = sourceHeight
        let widthRatio = maxWidth / sourceWidth
        let heightRatio = maxHeight / sourceHeight
        
        if sourceWidth > maxWidth || sourceHeight > maxHeight {
            let minRatio = min(widthRatio, heightRatio)
            targetWidth = sourceWidth * minRatio
            targetHeight = sourceHeight * minRatio
        }
        
        return CGSize(width: targetWidth, height: targetHeight)
    }
    
    // 调整图片尺寸
    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}

struct EditorView: View {
    var originalImage: UIImage
    
    @StateObject private var settings = WatermarkSettings()
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastStyle: ToastStyle = .success
    @State private var watermarkedImage: UIImage?
    @State private var showRepeatingMode = true
    
    // 创建图片保存器
    private let imageSaver = ImageSaver()
    
    // 防抖动计时器和预览刷新状态
    @StateObject private var debouncer = DebouncedUpdater()
    
    var body: some View {
        ZStack {
            // 渐变背景
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground),
                    Color(.systemGroupedBackground)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // 图片预览
                    ZStack {
                        ImagePreviewView(image: watermarkedImage ?? originalImage)
                        
                        if debouncer.isUpdating {
                            // 更新指示器
                            VStack {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    
                                    Text(NSLocalizedString("更新预览中...", comment: ""))
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .background(
                                    Capsule()
                                        .fill(Color.black.opacity(0.7))
                                        .background(
                                            Capsule()
                                                .fill(.ultraThinMaterial)
                                        )
                                )
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                            .padding(.bottom, 20)
                        }
                    }
                    
                    // 设置区域
                    WatermarkSettingsView(
                        settings: settings,
                        showRepeatingMode: $showRepeatingMode,
                        updateWatermark: { 
                            debouncer.debouncedUpdate { [self] in
                                updateWatermark()
                            }
                        },
                        updateWatermarkImmediate: updateWatermark
                    )
                    .padding(.bottom, 32)
                }
                .padding(.top, 16)
            }
        }
        .onAppear {
            updateWatermark()
            
            // 设置保存成功和失败的回调
            imageSaver.onSuccess = {
                DispatchQueue.main.async {
                    toastMessage = NSLocalizedString("已保存到系统相册", comment: "")
                    toastStyle = .success
                    showToast = true
                }
            }
            
            imageSaver.onFailure = { _ in
                DispatchQueue.main.async {
                    toastMessage = NSLocalizedString("保存失败", comment: "")
                    toastStyle = .error
                    showToast = true
                }
            }
        }
        .navigationTitle(NSLocalizedString("编辑水印", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(NSLocalizedString("保存", comment: "")) {
                    HapticFeedback.success()
                    debouncer.cancelUpdate() // 取消任何挂起的更新
                    updateWatermark() // 确保保存之前使用最新设置
                    saveImageToPhotoLibrary()
                }
                .fontWeight(.medium)
            }
        }
        .toast(isShowing: $showToast, message: toastMessage, style: toastStyle)
    }
    
    private func updateWatermark() {
        watermarkedImage = ImageRenderer.render(
            image: originalImage,
            settings: settings,
            repeatingMode: showRepeatingMode
        )
    }
    
    private func saveImageToPhotoLibrary() {
        guard let image = watermarkedImage else { return }
        
        // 检查权限
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    // 保存图片
                    self.imageSaver.saveImage(image)
                case .denied, .restricted:
                    // 权限被拒绝，显示错误提示
                    toastMessage = NSLocalizedString("无法访问相册，请在设置中授予权限", comment: "")
                    toastStyle = .error
                    showToast = true
                case .notDetermined:
                    // 权限尚未确定，这种情况应该不会出现，因为我们已经请求了授权
                    break
                @unknown default:
                    break
                }
            }
        }
    }
}

// 防抖动更新处理器
class DebouncedUpdater: ObservableObject {
    @Published var isUpdating = false
    private var updateTask: DispatchWorkItem?
    private let debounceDelay: TimeInterval = 0.3 // 300毫秒延迟
    
    func debouncedUpdate(action: @escaping () -> Void) {
        self.isUpdating = true
        
        // 取消之前的任务
        updateTask?.cancel()
        
        // 创建新的任务
        let task = DispatchWorkItem { [weak self] in
            action()
            DispatchQueue.main.async {
                self?.isUpdating = false
            }
        }
        
        self.updateTask = task
        
        // 延迟执行
        DispatchQueue.main.asyncAfter(deadline: .now() + debounceDelay, execute: task)
    }
    
    func cancelUpdate() {
        updateTask?.cancel()
        updateTask = nil
        isUpdating = false
    }
}

// 图片预览视图组件
struct ImagePreviewView: View {
    let image: UIImage
    
    var body: some View {
        ZStack {
            // 背景容器 - 固定4:3比例
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemGray6))
            
            // 图片 - 保持原始比例，在容器内居中显示
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .clipped()
        }
        .aspectRatio(4/3, contentMode: .fit)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
        .padding(.top, 0)
        .padding(.bottom, 8)
    }
}

// 设置区域视图组件
struct WatermarkSettingsView: View {
    @ObservedObject var settings: WatermarkSettings
    @Binding var showRepeatingMode: Bool
    let updateWatermark: () -> Void
    let updateWatermarkImmediate: () -> Void // 立即更新的版本，用于切换开关等操作
    
    var body: some View {
        VStack(spacing: 20) {
            // 水印文字输入框
            TextInputGroupBox(text: $settings.text, updateWatermark: updateWatermarkImmediate)
            
            // 滑块设置区域
            SlidersGroupBox(settings: settings, updateWatermark: updateWatermark)
            
            // 颜色选择区域
            ColorSelectionGroupBox(selectedColor: $settings.color, updateWatermark: updateWatermarkImmediate)
            
            // 重复水印模式开关
            ToggleGroupBox(showRepeatingMode: $showRepeatingMode, updateWatermark: updateWatermarkImmediate)
        }
        .padding(.horizontal, 16)
    }
}

// 水印文字输入框组件
struct TextInputGroupBox: View {
    @Binding var text: String
    let updateWatermark: () -> Void
    @State private var isFocused: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            HStack(spacing: 8) {
                Image(systemName: "textformat")
                    .foregroundColor(.blue)
                    .font(.system(size: 16, weight: .medium))
                Text(NSLocalizedString("水印文字", comment: ""))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            // 文字输入区域
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topLeading) {
                    TextField("", text: $text)
                        .padding(16)
                        .font(.system(size: 16))
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(UIColor.secondarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isFocused ? Color.blue : Color.gray.opacity(0.2), lineWidth: isFocused ? 2 : 1)
                        )
                        .onChange(of: text) { _ in
                            updateWatermark()
                        }
                        .onTapGesture {
                            isFocused = true
                        }
                        .onSubmit {
                            isFocused = false
                        }
                    
                    if text.isEmpty {
                        Text(NSLocalizedString("输入水印文字", comment: ""))
                            .foregroundColor(.gray.opacity(0.6))
                            .font(.system(size: 16))
                            .padding(.leading, 16)
                            .padding(.top, 16)
                    }
                }
                
                // 文字计数和说明
                HStack {
                    Spacer()
                    
                    Text("\(text.count)/30")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(text.count > 20 ? .orange : .secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(UIColor.tertiarySystemFill))
                        )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// 水印模式开关组件
struct ToggleGroupBox: View {
    @Binding var showRepeatingMode: Bool
    let updateWatermark: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题
            HStack(spacing: 8) {
                Image(systemName: "rectangle.grid.2x2")
                    .foregroundColor(.blue)
                    .font(.system(size: 16, weight: .medium))
                Text(NSLocalizedString("重复水印模式", comment: ""))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            // 开关
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(showRepeatingMode ? NSLocalizedString("已开启", comment: "") : NSLocalizedString("已关闭", comment: ""))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(NSLocalizedString("在整个图片上重复显示水印", comment: ""))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Toggle("", isOn: $showRepeatingMode)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .scaleEffect(0.9)
                    .onChange(of: showRepeatingMode) { _ in
                        HapticFeedback.selection()
                        updateWatermark()
                    }
            }
            .padding(.vertical, 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// 滑块设置区域组件
struct SlidersGroupBox: View {
    @ObservedObject var settings: WatermarkSettings
    let updateWatermark: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题
            HStack(spacing: 8) {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.blue)
                    .font(.system(size: 16, weight: .medium))
                Text(NSLocalizedString("调整参数", comment: ""))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            // 滑块组
            VStack(spacing: 24) {
                // 字体大小
                SliderView(
                    title: NSLocalizedString("字体大小", comment: ""), 
                    icon: "textformat.size", 
                    value: $settings.fontSize, 
                    range: WatermarkSettings.fontSizeRange,
                    displayValue: "\(Int(settings.fontSize))",
                    onChange: updateWatermark
                )
                
                // 透明度
                DoubleSliderView(
                    title: NSLocalizedString("透明度", comment: ""), 
                    icon: "slider.horizontal.below.rectangle", 
                    value: $settings.opacity, 
                    range: WatermarkSettings.opacityRange,
                    displayValue: "\(Int(settings.opacity * 100))%",
                    onChange: updateWatermark
                )
                
                // 旋转角度
                DoubleSliderView(
                    title: NSLocalizedString("旋转角度", comment: ""), 
                    icon: "rotate.right", 
                    value: $settings.angle, 
                    range: WatermarkSettings.angleRange,
                    displayValue: "\(Int(settings.angle))°",
                    onChange: updateWatermark
                )
                
                // 水印间距
                SliderView(
                    title: NSLocalizedString("间距", comment: ""), 
                    icon: "rectangle.split.3x1", 
                    value: $settings.space, 
                    range: WatermarkSettings.spaceRange,
                    displayValue: "\(Int(settings.space))",
                    onChange: updateWatermark
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// 颜色选择组件
struct ColorSelectionGroupBox: View {
    @Binding var selectedColor: Color
    let updateWatermark: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题
            HStack(spacing: 8) {
                Image(systemName: "paintpalette")
                    .foregroundColor(.blue)
                    .font(.system(size: 16, weight: .medium))
                Text(NSLocalizedString("颜色选择", comment: ""))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            // 颜色选择器
            VStack(spacing: 12) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 55), spacing: 12)], spacing: 12) {
                    ForEach(WatermarkSettings.colorOptions, id: \.self) { color in
                        ColorButton(color: color, selectedColor: $selectedColor)
                            .frame(height: 45)
                            .onChange(of: selectedColor) { _ in
                                updateWatermark()
                            }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

// CGFloat类型的滑块组件
struct SliderView: View {
    var title: String
    var icon: String
    @Binding var value: CGFloat
    var range: ClosedRange<CGFloat>
    var displayValue: String
    var onChange: () -> Void
    
    // 添加防抖变量
    @State private var lastFeedbackTime: TimeInterval = 0
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .foregroundColor(.blue)
                        .font(.system(size: 14, weight: .medium))
                        .frame(width: 20)
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text(displayValue)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.1))
                    )
            }
            
            Slider(value: $value, in: range)
                .accentColor(.blue)
                .onChange(of: value) { _ in
                    onChange()
                    
                    // 只在滑动结束或间隔足够长时提供触觉反馈
                    let currentTime = Date().timeIntervalSince1970
                    if currentTime - lastFeedbackTime > 0.3 { // 300毫秒防抖
                        HapticFeedback.selection()
                        lastFeedbackTime = currentTime
                    }
                }
        }
        .padding(.horizontal, 4)
    }
}

// Double类型的滑块组件
struct DoubleSliderView: View {
    var title: String
    var icon: String
    @Binding var value: Double
    var range: ClosedRange<Double>
    var displayValue: String
    var onChange: () -> Void
    
    // 添加防抖变量
    @State private var lastFeedbackTime: TimeInterval = 0
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .foregroundColor(.blue)
                        .font(.system(size: 14, weight: .medium))
                        .frame(width: 20)
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text(displayValue)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.1))
                    )
            }
            
            Slider(value: $value, in: range)
                .accentColor(.blue)
                .onChange(of: value) { _ in
                    onChange()
                    
                    // 只在滑动结束或间隔足够长时提供触觉反馈
                    let currentTime = Date().timeIntervalSince1970
                    if currentTime - lastFeedbackTime > 0.3 { // 300毫秒防抖
                        HapticFeedback.selection()
                        lastFeedbackTime = currentTime
                    }
                }
        }
        .padding(.horizontal, 4)
    }
}

struct ColorButton: View {
    let color: Color
    @Binding var selectedColor: Color
    
    var body: some View {
        Button(action: {
            HapticFeedback.selection()
            selectedColor = color
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                if color == selectedColor {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue, lineWidth: 3)
                    
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 18, height: 18)
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(color == selectedColor ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: color == selectedColor)
    }
}


