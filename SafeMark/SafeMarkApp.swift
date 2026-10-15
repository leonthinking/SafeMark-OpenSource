//
//  SafeMarkApp.swift
//  SafeMark
//
//  Created by Leon Zhang on 2025/4/17.
//

import SwiftUI

@main
struct SafeMarkApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .accentColor(Color.blue) // 设置应用主题色为iOS标准蓝色
        }
    }
}
