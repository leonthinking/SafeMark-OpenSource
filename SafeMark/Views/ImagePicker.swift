import SwiftUI
import PhotosUI

struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) private var presentationMode
    @Binding var image: UIImage?
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController,
                                  didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let originalImage = info[.originalImage] as? UIImage {
                // 将HEIF格式转换为JPEG，降低压缩质量为0.4（40%）
                if let jpegData = originalImage.jpegData(compressionQuality: 0.4),
                   let convertedImage = UIImage(data: jpegData) {
                    // 降低最大尺寸限制为1500像素
                    let maxDimension: CGFloat = 1500
                    if convertedImage.size.width > maxDimension || convertedImage.size.height > maxDimension {
                        let resizedImage = resizeImage(image: convertedImage, targetSize: calculateAspectRatioFit(
                            sourceWidth: convertedImage.size.width,
                            sourceHeight: convertedImage.size.height,
                            maxWidth: maxDimension,
                            maxHeight: maxDimension
                        ))
                        parent.image = resizedImage
                    } else {
                        parent.image = convertedImage
                    }
                } else {
                    // 如果转换失败，尝试直接缩放原图
                    let maxDimension: CGFloat = 1500
                    if originalImage.size.width > maxDimension || originalImage.size.height > maxDimension {
                        let resizedImage = resizeImage(image: originalImage, targetSize: calculateAspectRatioFit(
                            sourceWidth: originalImage.size.width,
                            sourceHeight: originalImage.size.height,
                            maxWidth: maxDimension,
                            maxHeight: maxDimension
                        ))
                        parent.image = resizedImage
                    } else {
                        parent.image = originalImage
                    }
                }
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
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
} 