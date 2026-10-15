import UIKit
import SwiftUI

struct ImageRenderer {
    // 添加一个固定的随机数生成器，确保相同位置的水印每次生成都有相同的偏移
    private static var randomGenerator = SeededRandomGenerator(seed: 12345)
    
    static func render(image: UIImage, settings: WatermarkSettings, repeatingMode: Bool = true) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        
        return renderer.image { context in
            // 绘制原始图片
            image.draw(at: .zero)
            
            // 准备文字属性和加粗字体
            let fontWeight: UIFont.Weight = .bold
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: settings.fontSize, weight: fontWeight),
                .foregroundColor: UIColor(settings.color).withAlphaComponent(settings.opacity)
            ]
            
            let text = settings.text
            let textSize = text.size(withAttributes: attributes)
            
            // 计算一个中文字符宽度作为间距基准
            let chineseCharWidth = ("啊" as NSString).size(withAttributes: attributes).width
            
            if repeatingMode {
                // 使用context的保存状态，便于统一应用旋转
                context.cgContext.saveGState()
                
                // 将原点移动到图片中心，以便围绕中心旋转
                context.cgContext.translateBy(x: image.size.width / 2, y: image.size.height / 2)
                
                // 应用全局旋转角度
                let rotationAngle = settings.angle * .pi / 180.0
                context.cgContext.rotate(by: CGFloat(rotationAngle))
                
                // 计算对角线长度，用于确定水印分布范围
                let step = sqrt(pow(image.size.width, 2) + pow(image.size.height, 2))
                
                // 根据间距和文本宽度计算水印在x轴上的分布数量
                let margin = chineseCharWidth
                let width = textSize.width
                let xCount = Int(ceil(step / (width + margin)))
                
                // 根据间距系数和字体大小计算水印在y轴上的分布数量
                let yCount = Int(ceil(step / (settings.space * settings.fontSize)) / 2)
                
                // 在计算的范围内分布水印
                for i in -xCount...xCount {
                    for j in -yCount...yCount {
                        let x = CGFloat(i) * (width + margin)
                        let y = settings.space * settings.fontSize * CGFloat(j)
                        
                        let textRect = CGRect(
                            x: x,
                            y: y,
                            width: textSize.width,
                            height: textSize.height
                        )
                        
                        text.draw(in: textRect, withAttributes: attributes)
                    }
                }
                
                // 恢复绘图状态
                context.cgContext.restoreGState()
            } else {
                // 单个水印模式 - 放在中心位置
                let textRect = CGRect(
                    x: (image.size.width - textSize.width) / 2 + settings.position.width,
                    y: (image.size.height - textSize.height) / 2 + settings.position.height,
                    width: textSize.width,
                    height: textSize.height
                )
                
                // 对单个水印应用旋转
                context.cgContext.saveGState()
                context.cgContext.translateBy(x: textRect.midX, y: textRect.midY)
                context.cgContext.rotate(by: CGFloat(settings.angle * .pi / 180.0))
                context.cgContext.translateBy(x: -textRect.midX, y: -textRect.midY)
                
                text.draw(in: textRect, withAttributes: attributes)
                
                context.cgContext.restoreGState()
            }
        }
    }
}

// 添加一个有种子的随机数生成器，确保相同种子产生相同的随机序列
class SeededRandomGenerator {
    private var seed: UInt64
    private let multiplier: UInt64 = 6364136223846793005
    private let increment: UInt64 = 1442695040888963407
    
    init(seed: UInt64) {
        self.seed = seed
    }
    
    func reset() {
        seed = 12345 // 重置为初始种子
    }
    
    func next() -> UInt64 {
        seed = seed &* multiplier &+ increment
        return seed
    }
    
    func nextCGFloat(min: CGFloat, max: CGFloat) -> CGFloat {
        let randomValue = CGFloat(next() % 1000) / 1000.0
        return min + (max - min) * randomValue
    }
} 