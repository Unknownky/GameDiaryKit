@echo off
echo 🍅 开始构建番茄钟插件...

REM 检查node_modules是否存在
if not exist "node_modules" (
    echo 📦 安装依赖...
    npm install
)

REM 构建项目
echo 🔨 构建项目...
npm run build

REM 检查构建是否成功
if %ERRORLEVEL% EQU 0 (
    echo ✅ 构建成功！
    echo 📁 构建文件位于 dist/ 目录
    echo.
    echo 🚀 下一步：
    echo 1. 在uTools中安装开发者工具
    echo 2. 将当前目录添加为开发插件
    echo 3. 在uTools中输入 '番茄钟' 测试插件
) else (
    echo ❌ 构建失败！
    pause
    exit /b 1
)

pause
