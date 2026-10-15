# SafeMark

一款在 iPhone 本地为图片添加文字水印的 SwiftUI 应用。选图、预览和导出都在设备上完成，无需登录或后端服务。

## 功能

- 从相册选择一张图片，添加单个或重复排列的文字水印。
- 调整文字、字号（30–100）、透明度（10%–100%）和颜色。
- 将结果保存到系统相册；图片会经过缩放和 JPEG 压缩，不保证保留原始画质。
- 记住上次的水印文字，提供简体中文、繁体中文、英文、日文和韩文界面资源。
- 通过系统打开 GitHub 反馈和源码链接，不在应用内加载网页，不随链接发送图片或水印文字。

## 构建

需要 macOS、Xcode 16 或更新版本及 iOS SDK。最低部署目标 iOS 16.0。工程使用 Swift 5 语言模式，测试使用 Swift Testing。

```sh
git clone https://github.com/leonthinking/SafeMark-OpenSource.git
cd SafeMark-OpenSource
open SafeMark.xcodeproj
```

选择共享 Scheme **SafeMark** 和一个 iPhone 模拟器，点击 Run。模拟器构建不需要作者的 Apple Developer 账号或签名材料。

```sh
xcodebuild -project SafeMark.xcodeproj -scheme SafeMark \
  -configuration Debug -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO build
```

真机运行时，请选择自己的 Team，并为 App 与测试 Target 设置自己的唯一 Bundle ID。开源版默认使用 `org.safemark.opensource.SafeMark`，与官方 App 分开。详见 [Xcode 配置指南](XCODE_SETUP_GUIDE.md)。

## 测试

在 Xcode 中使用 Product → Test，或通过 `xcrun simctl list devices available` 找到模拟器，再执行：

```sh
xcodebuild -project SafeMark.xcodeproj -scheme SafeMark \
  -destination 'platform=iOS Simulator,id=SIMULATOR_UDID' \
  -derivedDataPath build/DerivedData CODE_SIGNING_ALLOWED=NO test
```

单元测试覆盖水印渲染的输出与导出编码，UI 测试覆盖设置入口和隐私页面。发布前还应验证选图、调整水印、保存及照片权限拒绝场景。

## 项目与文档

- `SafeMark/`：应用入口、模型、页面、图像处理与语言资源。
- `SafeMark.xcodeproj/`：工程与共享 Scheme。
- `SafeMarkTests/`、`SafeMarkUITests/`：渲染与界面回归测试。
- [功能与版本记录](docs/Feature_and_Changelog.md)
- [国际化说明](国际化说明.md)
- [发布检查表](APP_STORE_RELEASE_CHECKLIST.md)

这是从源码快照整理的独立开源版本，不包含原私有项目的 Git 历史、实验分支、个人配置或旧截图。应用版本沿用 1.2.9，历史文档不表示旧功能仍在当前版本中。

版本号由 Xcode 的 Version / Build 管理，不运行自动递增脚本，也不收集构建者用户名或机器名。

## 反馈与贡献

[提交问题或建议](https://github.com/leonthinking/SafeMark-OpenSource/issues) · [贡献说明](CONTRIBUTING.md)

Fork 后请修改 `SafeMark/ProjectLinks.swift` 中的仓库地址。反馈请使用虚构测试图片，勿公开身份证件、个人照片或其他敏感内容。

## 许可证与素材

代码、文档和本仓库的原创 App 图标均采用 [MIT License](LICENSE)。图标由项目作者原创，详见 [素材说明](ASSETS.md)。衍生版本请清楚注明维护者，并保留适用的版权及许可证声明。
