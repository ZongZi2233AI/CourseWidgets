#!/usr/bin/env python3
"""
生成符合 Windows 标准的 ICO 图标文件
需要安装 Pillow: pip install Pillow
"""

from PIL import Image
import os

def generate_windows_icon(input_png, output_ico):
    """
    从 PNG 文件生成符合 Windows 标准的 ICO 文件
    包含多个尺寸: 16x16, 32x32, 48x48, 64x64, 128x128, 256x256
    """
    try:
        # 打开原始图片
        img = Image.open(input_png)
        
        # 确保是 RGBA 模式
        if img.mode != 'RGBA':
            img = img.convert('RGBA')
        
        # 定义需要的尺寸
        sizes = [(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
        
        # 创建不同尺寸的图标
        icon_images = []
        for size in sizes:
            resized = img.resize(size, Image.Resampling.LANCZOS)
            icon_images.append(resized)
        
        # 保存为 ICO 文件
        icon_images[0].save(
            output_ico,
            format='ICO',
            sizes=sizes,
            append_images=icon_images[1:]
        )
        
        print(f"✅ 成功生成 Windows 图标: {output_ico}")
        print(f"   包含尺寸: {', '.join([f'{w}x{h}' for w, h in sizes])}")
        
        # 检查文件大小
        file_size = os.path.getsize(output_ico)
        print(f"   文件大小: {file_size / 1024:.2f} KB")
        
        return True
        
    except Exception as e:
        print(f"❌ 生成图标失败: {e}")
        return False

if __name__ == '__main__':
    # 输入和输出路径
    input_png = 'assets/icon.png'
    output_ico = 'windows/runner/resources/app_icon.ico'
    
    # 确保输出目录存在
    os.makedirs(os.path.dirname(output_ico), exist_ok=True)
    
    # 生成图标
    if generate_windows_icon(input_png, output_ico):
        print("\n🎉 Windows 图标生成完成！")
        print(f"   位置: {output_ico}")
        print("\n下一步:")
        print("   1. 取消注释 windows/runner/Runner.rc 中的图标引用")
        print("   2. 运行 flutter build windows --release")
    else:
        print("\n❌ 图标生成失败，请检查错误信息")
