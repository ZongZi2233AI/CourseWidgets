#!/usr/bin/env python3
"""
版本同步脚本
从Dart常量文件同步版本号到所有配置文件
"""

import re
import os

def read_dart_version():
    """读取Dart版本常量"""
    version_file = "lib/constants/version.dart"
    with open(version_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 解析版本号
    app_version = re.search(r"const String appVersion = '([^']+)'", content)
    build_number = re.search(r"const int buildNumber = (\d+)", content)
    
    if app_version and build_number:
        return app_version.group(1), int(build_number.group(1))
    else:
        raise ValueError("无法解析Dart版本常量")

def update_android_config(version, build_number):
    """更新Android配置"""
    android_file = "android/app/build.gradle.kts"
    with open(android_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 替换版本号
    content = re.sub(r'versionCode = \d+', f'versionCode = {build_number}', content)
    content = re.sub(r'versionName = "[^"]+"', f'versionName = "{version}"', content)
    
    with open(android_file, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"✓ Android配置已更新: {version} ({build_number})")

def update_windows_config(version, build_number):
    """更新Windows配置"""
    windows_file = "windows/runner/Runner.rc"
    with open(windows_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 解析版本号为x,y,z,w格式
    version_parts = version.split('.')
    while len(version_parts) < 4:
        version_parts.append('0')
    
    # 替换版本号
    content = re.sub(
        r'#define VERSION_AS_NUMBER [\d,]+',
        f'#define VERSION_AS_NUMBER {",".join(version_parts)}',
        content
    )
    content = re.sub(
        r'#define VERSION_AS_STRING "[^"]+"',
        f'#define VERSION_AS_STRING "{version}"',
        content
    )
    
    # 替换公司名称和版权信息
    content = re.sub(
        r'VALUE "CompanyName", "[^"]+"',
        f'VALUE "CompanyName", "CourseWidgets"',
        content
    )
    content = re.sub(
        r'VALUE "LegalCopyright", "[^"]+"',
        f'VALUE "LegalCopyright", "Copyright (C) 2025 CourseWidgets. All rights reserved."',
        content
    )
    content = re.sub(
        r'VALUE "OriginalFilename", "[^"]+"',
        f'VALUE "OriginalFilename", "CourseWidgets.exe"',
        content
    )
    content = re.sub(
        r'VALUE "ProductName", "[^"]+"',
        f'VALUE "ProductName", "CourseWidgets"',
        content
    )
    
    with open(windows_file, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"✓ Windows配置已更新: {version} ({build_number})")

def update_pubspec(version, build_number):
    """更新pubspec.yaml"""
    pubspec_file = "pubspec.yaml"
    with open(pubspec_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 替换版本号
    content = re.sub(
        r'version: [\d.]+\+\d+',
        f'version: {version}+{build_number}',
        content
    )
    
    with open(pubspec_file, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"✓ pubspec.yaml已更新: {version}+{build_number}")

def main():
    """主函数"""
    print("开始同步版本号...")
    
    try:
        # 读取Dart版本
        version, build_number = read_dart_version()
        print(f"从Dart常量读取: {version} ({build_number})")
        
        # 更新各配置文件
        update_android_config(version, build_number)
        update_windows_config(version, build_number)
        update_pubspec(version, build_number)
        
        print("\n✅ 版本同步完成！")
        
    except Exception as e:
        print(f"❌ 同步失败: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())
