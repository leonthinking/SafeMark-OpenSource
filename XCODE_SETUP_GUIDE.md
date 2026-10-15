# Xcode 配置指南

## 模拟器运行

1. 安装 Xcode 16 或更新版本及 iOS Simulator runtime。
2. 在项目根目录执行 `open SafeMark.xcodeproj`。
3. 选择共享 Scheme `SafeMark` 和 iPhone 模拟器，点击 Run。

最低部署系统为 iOS 16.0。模拟器构建不需要作者的账号或签名材料。`SWIFT_VERSION` 是语言兼容模式，不是编译器版本号，本工程使用 `5.0`。

## 真机签名

1. 在 Xcode → Settings → Accounts 添加自己的 Apple 账号。
2. 在 App、单元测试和 UI 测试 Target 的 Signing & Capabilities 中选择自己的 Team。
3. 保留 Automatically manage signing，为三个 Target 设置属于自己的唯一 Bundle ID。
4. 连接设备并按提示开启开发者模式。

默认 App Bundle ID 为 `org.safemark.opensource.SafeMark`，避免覆盖官方 App。个人团队、证书、描述文件和账号配置不要提交到仓库。

## 常见问题

- **No profiles found**：真机需使用自己的 Team 和 Bundle ID；模拟器可以使用 README 中禁用签名的命令。
- **Program License Agreement**：仅当 Xcode 明确提示账号协议未完成时，检查自己的 Apple Developer / App Store Connect 账号。这不是阅读源码或模拟器构建的前置条件。
- **找不到 Scheme**：确认 `SafeMark.xcodeproj/xcshareddata/xcschemes/SafeMark.xcscheme` 存在。
- **没有模拟器**：在 Xcode → Settings → Components 下载 iOS runtime，再创建 iPhone 模拟器。
- **缓存异常**：使用 Product → Clean Build Folder，或改用新的 `-derivedDataPath`；无需删除其他项目的全局缓存。

## 版本与分发

在 App Target → General 修改 Version 和 Build。分发时使用自己的签名身份和 App Store Connect 应用记录。本项目没有自动上传或发布脚本。

模拟器通过不等于完成真机、Archive 或 App Store 验证，分发前按 [发布检查表](APP_STORE_RELEASE_CHECKLIST.md)检查。
