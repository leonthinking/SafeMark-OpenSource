//
//  AppDelegate.swift
//  SafeMark
//
//  Created by Leon Zhang on 2025/5/7.
//

import UIKit
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        // 仅支持竖屏方向
        return .portrait
    }
} 