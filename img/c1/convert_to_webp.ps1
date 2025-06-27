# 图片批量转换为WebP格式 PowerShell脚本
# 需要安装FFmpeg

param(
    [string]$InputDir = ".",
    [int]$Quality = 85,
    [switch]$KeepOriginal = $true,
    [switch]$Lossless = $false
)

Write-Host "🖼️  图片批量转换为WebP格式" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green

# 检查FFmpeg是否安装
try {
    $null = Get-Command ffmpeg -ErrorAction Stop
    Write-Host "✅ FFmpeg已安装" -ForegroundColor Green
} catch {
    Write-Host "❌ 未检测到FFmpeg" -ForegroundColor Red
    Write-Host "请先安装FFmpeg:" -ForegroundColor Yellow
    Write-Host "1. 下载: https://ffmpeg.org/download.html" -ForegroundColor Yellow
    Write-Host "2. 或使用包管理器: winget install FFmpeg" -ForegroundColor Yellow
    Write-Host "3. 或使用Chocolatey: choco install ffmpeg" -ForegroundColor Yellow
    Read-Host "按Enter键退出"
    exit 1
}

# 支持的图片格式
$supportedExtensions = @('.jpg', '.jpeg', '.png', '.bmp', '.gif', '.tiff', '.tif')

# 获取所有图片文件
$imageFiles = Get-ChildItem -Path $InputDir -File | Where-Object { 
    $supportedExtensions -contains $_.Extension.ToLower() 
}

if ($imageFiles.Count -eq 0) {
    Write-Host "❌ 在目录 '$InputDir' 中未找到支持的图片文件" -ForegroundColor Red
    Write-Host "支持的格式: $($supportedExtensions -join ', ')" -ForegroundColor Yellow
    Read-Host "按Enter键退出"
    exit 1
}

Write-Host "📁 找到 $($imageFiles.Count) 个图片文件" -ForegroundColor Cyan
Write-Host "🎯 质量设置: $(if ($Lossless) {'无损压缩'} else {"$Quality%"})" -ForegroundColor Cyan
Write-Host "📋 保留原文件: $(if ($KeepOriginal) {'是'} else {'否'})" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Green

$successCount = 0
$totalOriginalSize = 0
$totalNewSize = 0

foreach ($file in $imageFiles) {
    $originalSize = $file.Length
    $totalOriginalSize += $originalSize
    
    $outputFile = Join-Path $file.DirectoryName "$($file.BaseName).webp"
    
    # 检查输出文件是否已存在
    if (Test-Path $outputFile) {
        $response = Read-Host "文件 $($file.BaseName).webp 已存在，是否覆盖？ (y/N)"
        if ($response -ne 'y' -and $response -ne 'Y') {
            Write-Host "⏭️  跳过: $($file.Name)" -ForegroundColor Yellow
            continue
        }
    }
    
    try {
        # 构建FFmpeg命令
        if ($Lossless) {
            $ffmpegArgs = @('-i', $file.FullName, '-c:v', 'libwebp', '-lossless', '1', '-y', $outputFile)
        } else {
            $ffmpegArgs = @('-i', $file.FullName, '-c:v', 'libwebp', '-quality', $Quality, '-y', $outputFile)
        }
        
        # 执行转换
        $process = Start-Process -FilePath 'ffmpeg' -ArgumentList $ffmpegArgs -Wait -NoNewWindow -PassThru
        
        if ($process.ExitCode -eq 0 -and (Test-Path $outputFile)) {
            $newSize = (Get-Item $outputFile).Length
            $totalNewSize += $newSize
            $compressionRatio = (1 - $newSize / $originalSize) * 100
            
            Write-Host "✓ $($file.Name) -> $($file.BaseName).webp" -ForegroundColor Green
            Write-Host "  原始大小: $($originalSize.ToString('N0')) 字节" -ForegroundColor Gray
            Write-Host "  压缩后: $($newSize.ToString('N0')) 字节" -ForegroundColor Gray
            Write-Host "  压缩率: $($compressionRatio.ToString('F1'))%" -ForegroundColor Gray
            Write-Host ""
            
            $successCount++
            
            # 如果不保留原文件，则删除
            if (-not $KeepOriginal) {
                try {
                    Remove-Item $file.FullName -Force
                    Write-Host "🗑️  已删除原文件: $($file.Name)" -ForegroundColor Yellow
                } catch {
                    Write-Host "⚠️  删除原文件失败: $_" -ForegroundColor Red
                }
            }
        } else {
            Write-Host "✗ 转换失败: $($file.Name)" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ 转换失败: $($file.Name) - $_" -ForegroundColor Red
    }
}

# 输出统计信息
Write-Host "================================" -ForegroundColor Green
Write-Host "📊 转换完成统计:" -ForegroundColor Green
Write-Host "   成功转换: $successCount/$($imageFiles.Count) 个文件" -ForegroundColor Cyan

if ($totalOriginalSize -gt 0) {
    $totalCompression = (1 - $totalNewSize / $totalOriginalSize) * 100
    Write-Host "   总原始大小: $($totalOriginalSize.ToString('N0')) 字节 ($([math]::Round($totalOriginalSize/1024/1024, 1)) MB)" -ForegroundColor Cyan
    Write-Host "   总压缩后大小: $($totalNewSize.ToString('N0')) 字节 ($([math]::Round($totalNewSize/1024/1024, 1)) MB)" -ForegroundColor Cyan
    Write-Host "   总压缩率: $($totalCompression.ToString('F1'))%" -ForegroundColor Cyan
}

Read-Host "按Enter键退出" 