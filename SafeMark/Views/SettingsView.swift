import SwiftUI

// 语言选择管理器
class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var selectedLanguage: String = "auto"
    
    private let userDefaults = UserDefaults.standard
    private let selectedLanguageKey = "SelectedLanguage"
    
    private init() {
        selectedLanguage = userDefaults.string(forKey: selectedLanguageKey) ?? "auto"
    }
    
    func setLanguage(_ languageCode: String) {
        selectedLanguage = languageCode
        userDefaults.set(languageCode, forKey: selectedLanguageKey)
        
        if languageCode == "auto" {
            // 恢复系统默认语言
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        } else {
            // 设置应用语言
            UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
        }
        
        UserDefaults.standard.synchronize()
    }
    
    func getLanguageDisplayName(_ code: String) -> String {
        switch code {
        case "auto":
            return NSLocalizedString("自动", comment: "")
        case "en":
            return "English"
        case "zh-Hans":
            return "简体中文"
        case "zh-Hant":
            return "繁体中文"
        case "ja":
            return "日本語"
        case "ko":
            return "한국어"
        default:
            return code
        }
    }
}

// 语言选择视图
struct LanguageSelectionView: View {
    @ObservedObject private var languageManager = LanguageManager.shared
    @Environment(\.presentationMode) var presentationMode
    @State private var showRestartAlert = false
    
    let languages = [
        ("auto", "自动"),
        ("en", "English"),
        ("zh-Hans", "简体中文"),
        ("zh-Hant", "繁体中文"),
        ("ja", "日本語"),
        ("ko", "한국어")
    ]
    
    var body: some View {
        List {
            Section(footer: Text(NSLocalizedString("更改语言后需要重启应用才能生效", comment: ""))) {
                ForEach(languages, id: \.0) { language in
                    HStack {
                        Text(language.1)
                        Spacer()
                        if languageManager.selectedLanguage == language.0 {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        HapticFeedback.light()
                        languageManager.setLanguage(language.0)
                        showRestartAlert = true
                    }
                }
            }
        }
        .navigationTitle(NSLocalizedString("多语言", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .alert(NSLocalizedString("语言已切换", comment: ""), isPresented: $showRestartAlert) {
            Button(NSLocalizedString("立即退出", comment: "")) {
                // 退出应用，用户需要手动重新打开
                exit(0)
            }
            Button(NSLocalizedString("稍后重启", comment: ""), role: .cancel) {
                // 不做任何操作，用户稍后手动重启
            }
        } message: {
            Text(NSLocalizedString("请退出应用并重新打开以生效", comment: ""))
        }
    }
}

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                // 主要内容列表
                List {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(NSLocalizedString("SafeMark 安全水印", comment: ""))
                                .font(.headline)
                            Text(NSLocalizedString("图片处理均在本地完成，保护你的隐私", comment: ""))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    Section(header: Text(NSLocalizedString("语言", comment: ""))) {
                        NavigationLink(destination: LanguageSelectionView()) {
                            HStack {
                                Text(NSLocalizedString("多语言", comment: ""))
                                Spacer()
                                Text(LanguageManager.shared.getLanguageDisplayName(LanguageManager.shared.selectedLanguage))
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 15))
                            }
                        }
                    }
                    
                    Section(header: Text(NSLocalizedString("支持", comment: ""))) {
                        Link(destination: ProjectLinks.feedback) {
                            Label(NSLocalizedString("建议与反馈", comment: ""), systemImage: "arrow.up.right")
                        }
                        .accessibilityIdentifier("githubFeedback")
                    }
                    
                    Section(header: Text(NSLocalizedString("关于", comment: ""))) {
                        Link(destination: ProjectLinks.repository) {
                            Label(NSLocalizedString("源代码", comment: ""), systemImage: "arrow.up.right")
                        }
                        .accessibilityIdentifier("sourceCode")

                        NavigationLink(destination: TermsView(title: NSLocalizedString("隐私协议", comment: ""), contentKey: "privacy")) {
                            Text(NSLocalizedString("隐私协议", comment: ""))
                        }
                    }
                    
                    // 底部空白区域，为底部信息腾出空间
                    Section {
                        Color.clear.frame(height: 60)
                            .listRowBackground(Color.clear)
                    }
                }
                .listStyle(InsetGroupedListStyle())
                
                // 底部版权信息
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Text("© 2025 SafeMark")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        
                        Text(" | ")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        
                        // 显示App版本信息
                        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
                        Link("Version \(version)", destination: URL(string: "https://apps.apple.com/cn/app/safemark/id6744825189")!)
                            .font(.footnote)
                    }
                    
                    HStack(spacing: 4) {
                        Text("Created by")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        
                        Link("即刻@iLeon", destination: URL(string: "https://okjk.co/UteTjA")!)
                            .font(.footnote)
                    }
                }
                .padding(.bottom, 30) // 增加底部间距，更接近Home Indicator
                .padding(.top, 12)
                .frame(maxWidth: .infinity)
                .background(
                    Rectangle()
                        .fill(Color(UIColor.systemGroupedBackground))
                        .edgesIgnoringSafeArea(.bottom)
                )
            }
            .navigationTitle(NSLocalizedString("设置", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        HapticFeedback.light()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text(NSLocalizedString("完成", comment: ""))
                    }
                }
            }
        }
    }
}

struct TermsView: View {
    var title: String
    var contentKey: String // "terms" 或 "privacy"
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("SafeMark 隐私协议")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.bottom, 4)
                
                Text("欢迎使用 SafeMark 安全水印应用。本应用致力于为你提供在本地为图片添加水印的功能，保护你的图片隐私与安全。在使用本应用前，请阅读并理解以下内容。")
                
                Text("1. 协议条款")
                    .fontWeight(.bold)
                Text("使用本应用即表示你已阅读并同意本协议的全部内容。")
                
                Text("2. 应用功能")
                    .fontWeight(.bold)
                Text("SafeMark 仅在本地设备上运行，为图片添加水印。你的任何图片或数据不会上传至服务器，所有操作均在本地完成。")
                
                Text("3. 照片权限")
                    .fontWeight(.bold)
                Text("为便于你选择图片并保存水印结果，SafeMark 需要访问你的照片库。我们不会收集、存储或传输你的照片，所有权限请求仅用于完成所需功能。")
                
                Text("4. 信息收集")
                    .fontWeight(.bold)
                Text("本应用不收集你的任何个人信息。我们坚持本地处理、不联网、不追踪的原则，确保你的隐私不被侵犯。")
                
                Text("5. 数据安全")
                    .fontWeight(.bold)
                Text("所有数据处理均在你的设备本地完成，数据安全由你的设备保障。请确保你的设备安全设置和操作系统为最新状态。")
                
                Text("6. 免责声明")
                    .fontWeight(.bold)
                Text("SafeMark 不对你使用本应用处理后的图片在任何非法用途下的传播或使用承担责任。你应对自己的使用行为负责，并遵守相关法律法规。")
                
                Text("⸻")
                
                Text("如果你继续使用 SafeMark，即表示你同意上述协议内容。若你不同意，请停止使用本应用。")
            }
            .padding()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
