//
//  ContentView.swift
//  SafeMark
//
//  Created by Leon Zhang on 2025/4/17.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showSettingsView = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // 图片预览区域
                if let image = selectedImage {
                    // 使用固定4:3比例的图片预览组件
                    HomeImagePreviewView(image: image)
                } else {
                    // 空图片占位区域 - 也使用4:3比例
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.1))
                        
                        VStack(spacing: 16) {
                            Image(systemName: "photo")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            
                            Text(NSLocalizedString("请从相册选择图片", comment: ""))
                                .foregroundColor(.gray)
                        }
                    }
                    .aspectRatio(4/3, contentMode: .fit)
                    .padding(.horizontal, 16)
                    .padding(.top, 0)
                    .padding(.bottom, 8)
                }
                
                // 按钮区域
                VStack(spacing: 16) {
                    Button(action: {
                        HapticFeedback.light()
                        showImagePicker = true
                    }) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                            Text(NSLocalizedString("选择图片", comment: ""))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    
                    if selectedImage != nil {
                        NavigationLink(destination: EditorView(originalImage: selectedImage!)) {
                            HStack {
                                Image(systemName: "pencil")
                                Text(NSLocalizedString("添加水印", comment: ""))
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                        }
                        .simultaneousGesture(TapGesture().onEnded {
                            HapticFeedback.medium()
                        })
                    }
                }
                
                Spacer()
            }
            .padding(.top, 16)
            .navigationTitle("SafeMark")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        HapticFeedback.light()
                        showSettingsView = true
                    }) {
                        Image(systemName: "gear")
                    }
                    .accessibilityLabel(NSLocalizedString("设置", comment: ""))
                    .accessibilityIdentifier("openSettings")
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .sheet(isPresented: $showSettingsView) {
                SettingsView()
            }
        }
    }
}

// 首页图片预览视图组件
struct HomeImagePreviewView: View {
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

#Preview {
    ContentView()
}
