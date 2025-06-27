@echo off
chcp 65001 >nul
echo 🖼️  图片批量转换为WebP格式
echo =====================================

REM 检查Python是否安装
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ 未检测到Python，请先安装Python
    echo 下载地址: https://www.python.org/downloads/
    pause
    exit /b 1
)

REM 检查并安装Pillow库
echo 📦 检查依赖库...
python -c "import PIL" >nul 2>&1
if %errorlevel% neq 0 (
    echo 📥 正在安装Pillow库...
    pip install Pillow
    if %errorlevel% neq 0 (
        echo ❌ Pillow安装失败，请手动运行: pip install Pillow
        pause
        exit /b 1
    )
)

echo ✅ 依赖检查完成
echo.

REM 运行转换脚本
python convert_to_webp.py %*

echo.
echo 转换完成！按任意键退出...
pause >nul 