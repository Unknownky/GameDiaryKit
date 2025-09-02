# 🍅 番茄钟插件部署指南

## 📋 准备工作

### 1. 环境要求
- [Node.js](https://nodejs.org/) (推荐 LTS 版本)
- [uTools](https://www.u-tools.cn/) 
- [uTools 开发者工具](https://www.u.tools/plugins/detail/uTools%20%E5%BC%80%E5%8F%91%E8%80%85%E5%B7%A5%E5%85%B7/)

### 2. 下载项目
将项目文件下载到本地目录

## 🔧 开发环境设置

### 方法一：使用批处理脚本（推荐 Windows 用户）
1. 双击运行 `start-dev.bat`
2. 脚本会自动安装依赖并启动开发服务器
3. 浏览器会自动打开测试页面

### 方法二：手动命令行
```bash
# 安装依赖
npm install

# 启动开发服务器
npm run dev

# 在浏览器中访问 http://localhost:3000/test.html
```

## 📱 在 uTools 中测试

### 1. 安装开发者工具
- 在 uTools 中输入 `开发者工具` 进行安装

### 2. 添加开发插件
- 打开 uTools 开发者工具
- 点击 "添加插件" 按钮
- 选择项目所在目录
- 确认添加

### 3. 测试插件
- 在 uTools 中输入 `番茄钟` 或 `pomodoro`
- 插件应该正常启动

## 🏗️ 构建生产版本

### 构建命令
```bash
npm run build
```

### 构建输出
- 构建文件将生成在 `dist/` 目录中
- 可以将整个项目目录打包分发

## 📦 打包分发

### 离线安装包
1. 使用 uTools 开发者工具的 "打包" 功能
2. 生成 `.upx` 文件用于离线安装

### 发布到应用市场
1. 在 uTools 开发者工具中点击 "发布"
2. 按照提示填写插件信息
3. 提交审核

## 🔍 故障排除

### 常见问题

#### 1. 依赖安装失败
```bash
# 清除缓存
npm cache clean --force

# 使用 cnpm 或设置镜像源
npm config set registry https://registry.npmmirror.com/
npm install
```

#### 2. uTools 无法加载插件
- 检查 `plugin.json` 配置是否正确
- 确保项目目录结构完整
- 重启 uTools 并重新添加插件

#### 3. 开发服务器启动失败
- 检查端口 3000 是否被占用
- 尝试使用其他端口：`npm run dev -- --port 3001`

#### 4. 插件功能异常
- 打开浏览器开发者工具查看控制台错误
- 检查是否有 JavaScript 报错
- 验证 uTools API 调用是否正确

### 日志查看
- 浏览器：F12 打开开发者工具 → Console 标签
- uTools：在开发者工具中查看插件日志

## 📞 获取帮助

如果遇到问题：
1. 查看 `USAGE.md` 使用说明
2. 检查浏览器控制台错误信息
3. 参考 [uTools 开发文档](https://www.u-tools.cn/docs/developer/)

---

祝您使用愉快！🎉
