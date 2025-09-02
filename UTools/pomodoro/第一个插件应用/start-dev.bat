@echo off
title 番茄钟开发环境

echo.
echo 🍅 ===============================================
echo    番茄钟 uTools 插件开发环境
echo 🍅 ===============================================
echo.

REM 检查Node.js是否安装
node --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ❌ 错误: 未找到 Node.js
    echo 📥 请先安装 Node.js: https://nodejs.org/
    pause
    exit /b 1
)

echo ✅ Node.js 已安装
node --version

REM 检查依赖是否已安装
if not exist "node_modules" (
    echo.
    echo 📦 正在安装依赖...
    npm install
    if %ERRORLEVEL% NEQ 0 (
        echo ❌ 依赖安装失败
        pause
        exit /b 1
    )
    echo ✅ 依赖安装完成
)

echo.
echo 🚀 启动开发服务器...
echo 🌐 服务器将在浏览器中自动打开测试页面
echo 💡 按 Ctrl+C 停止服务器
echo.

start "" "http://localhost:3000/test.html"
npm run dev

pause
