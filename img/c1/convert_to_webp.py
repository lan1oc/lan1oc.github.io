#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
图片批量转换为WebP格式脚本
支持常见图片格式：jpg, jpeg, png, bmp, gif, tiff
"""

import os
import sys
from PIL import Image
import argparse

def convert_to_webp(input_path, output_path=None, quality=85, lossless=False):
    """
    将图片转换为WebP格式
    
    Args:
        input_path: 输入图片路径
        output_path: 输出路径，如果为None则自动生成
        quality: 压缩质量 (1-100)，仅在lossy模式下有效
        lossless: 是否使用无损压缩
    """
    try:
        # 打开图片
        with Image.open(input_path) as img:
            # 如果输出路径为空，则自动生成
            if output_path is None:
                base_name = os.path.splitext(os.path.basename(input_path))[0]
                output_path = os.path.join(os.path.dirname(input_path), f"{base_name}.webp")
            
            # 转换为RGB模式（WebP不支持RGBA的某些情况）
            if img.mode in ('RGBA', 'LA'):
                # 保持透明度
                img = img.convert('RGBA')
            elif img.mode not in ('RGB', 'RGBA'):
                img = img.convert('RGB')
            
            # 保存为WebP格式
            if lossless:
                img.save(output_path, format='WebP', lossless=True)
            else:
                img.save(output_path, format='WebP', quality=quality, method=6)
            
            # 获取文件大小信息
            original_size = os.path.getsize(input_path)
            new_size = os.path.getsize(output_path)
            compression_ratio = (1 - new_size / original_size) * 100
            
            print(f"✓ {os.path.basename(input_path)} -> {os.path.basename(output_path)}")
            print(f"  原始大小: {original_size:,} 字节")
            print(f"  压缩后: {new_size:,} 字节")
            print(f"  压缩率: {compression_ratio:.1f}%")
            print()
            
            return True
            
    except Exception as e:
        print(f"✗ 转换失败 {input_path}: {str(e)}")
        return False

def batch_convert(directory=".", quality=85, lossless=False, keep_original=True):
    """
    批量转换目录下的所有图片
    
    Args:
        directory: 目标目录
        quality: 压缩质量
        lossless: 是否无损压缩
        keep_original: 是否保留原始文件
    """
    # 支持的图片格式
    supported_formats = ('.jpg', '.jpeg', '.png', '.bmp', '.gif', '.tiff', '.tif')
    
    # 获取所有图片文件
    image_files = []
    for file in os.listdir(directory):
        if file.lower().endswith(supported_formats):
            image_files.append(os.path.join(directory, file))
    
    if not image_files:
        print("❌ 未找到支持的图片文件")
        print(f"支持的格式: {', '.join(supported_formats)}")
        return
    
    print(f"📁 找到 {len(image_files)} 个图片文件")
    print(f"🎯 质量设置: {'无损压缩' if lossless else f'{quality}%'}")
    print(f"📋 保留原文件: {'是' if keep_original else '否'}")
    print("=" * 50)
    
    success_count = 0
    total_original_size = 0
    total_new_size = 0
    
    for image_file in image_files:
        # 检查是否已经是webp格式
        if image_file.lower().endswith('.webp'):
            print(f"⏭️  跳过已是WebP格式的文件: {os.path.basename(image_file)}")
            continue
            
        original_size = os.path.getsize(image_file)
        total_original_size += original_size
        
        if convert_to_webp(image_file, quality=quality, lossless=lossless):
            success_count += 1
            
            # 获取转换后的文件大小
            webp_file = os.path.splitext(image_file)[0] + '.webp'
            if os.path.exists(webp_file):
                total_new_size += os.path.getsize(webp_file)
                
                # 如果不保留原文件，则删除
                if not keep_original:
                    try:
                        os.remove(image_file)
                        print(f"🗑️  已删除原文件: {os.path.basename(image_file)}")
                    except Exception as e:
                        print(f"⚠️  删除原文件失败: {str(e)}")
    
    # 输出统计信息
    print("=" * 50)
    print(f"📊 转换完成统计:")
    print(f"   成功转换: {success_count}/{len(image_files)} 个文件")
    if total_original_size > 0:
        total_compression = (1 - total_new_size / total_original_size) * 100
        print(f"   总原始大小: {total_original_size:,} 字节 ({total_original_size/1024/1024:.1f} MB)")
        print(f"   总压缩后大小: {total_new_size:,} 字节 ({total_new_size/1024/1024:.1f} MB)")
        print(f"   总压缩率: {total_compression:.1f}%")

def main():
    parser = argparse.ArgumentParser(description='批量转换图片为WebP格式')
    parser.add_argument('-d', '--directory', default='.', help='目标目录 (默认: 当前目录)')
    parser.add_argument('-q', '--quality', type=int, default=85, choices=range(1, 101), 
                       help='压缩质量 1-100 (默认: 85)')
    parser.add_argument('-l', '--lossless', action='store_true', help='使用无损压缩')
    parser.add_argument('--remove-original', action='store_true', help='删除原始文件')
    
    args = parser.parse_args()
    
    if not os.path.exists(args.directory):
        print(f"❌ 目录不存在: {args.directory}")
        sys.exit(1)
    
    print("🖼️  图片批量转换为WebP格式")
    print("=" * 50)
    
    batch_convert(
        directory=args.directory,
        quality=args.quality,
        lossless=args.lossless,
        keep_original=not args.remove_original
    )

if __name__ == "__main__":
    main() 