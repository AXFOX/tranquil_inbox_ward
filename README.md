# 静域信驿 Tranquil Inbox Ward

一个为 PMail 邮件系统设计的智能邮件分类服务。通过集成 Ollama 模型和本地黑名单过滤，提供高效的邮件自动分类功能。

## 功能特性

- 🤖 **AI 驱动分类**：集成 Ollama 模型，使用 Few-shot Learning 进行邮件智能分类
- 🚫 **黑名单过滤**：支持本地黑名单词汇库，快速过滤垃圾邮件
- 📊 **三分类标准**：将邮件分为「普通」、「广告」、「垃圾」三类
- 🔄 **灵活架构**：支持多种分类策略的组合，可优雅降级到关键词匹配
- 📝 **详细日志**：完整的 HTTP 请求日志中间件，便于调试和监控
- ⚡ **高性能**：基于 Shelf 框架，轻量级 HTTP 服务器

## 项目结构

```
tranquil_inbox_ward/
├── bin/
│   └── tranquil_inbox_ward.dart    # 应用入口点
├── lib/
│   ├── server.dart                 # 路由和请求处理
│   ├── classifier.dart             # 邮件分类核心逻辑
│   ├── ollama_client.dart          # Ollama 模型调用
│   └── logging_middleware.dart     # HTTP 日志中间件
├── test/
│   ├── tranquil_inbox_ward_test.dart
│   └── test_classify.sh
├── blackworlds.json                # 黑名单词汇库
└── pubspec.yaml                    # 项目依赖配置
```

## API 端点

### POST `/classify`

邮件分类请求端点。

**请求格式**（符合 PMail 标准）：
```json
{
  "instances": [
    {
      "token": ["邮件内容文本"]
    }
  ]
}
```

**响应格式**：
```json
{
  "predictions": [
    [1.0, 0.0, 0.0]
  ]
}
```

其中响应数组表示 `[普通, 广告, 垃圾]` 的置信度得分。

### GET `/health`

健康检查端点，返回 `OK`。

## 使用方式

### 前提条件

- Dart SDK >= 3.11.5
- Ollama 本地服务（可选，如果启用 Ollama 分类）

### 安装依赖

```bash
dart pub get
```

### 运行服务

```bash
dart run bin/tranquil_inbox_ward.dart
```

默认监听 `http://0.0.0.0:9800`。可通过环境变量 `PORT` 自定义端口：

```bash
PORT=8080 dart run bin/tranquil_inbox_ward.dart
```

### 运行测试
使用 Shell 脚本：

```bash
bash test/test_classify.sh
```

## 分类策略

邮件分类采用多层策略，优先级如下：

1. **黑名单过滤**（可选）默认关闭：检查邮件是否包含黑名单词汇 → 返回「垃圾」
2. **Ollama 模型分类**（可选）默认开启：调用本地 Ollama 模型进行分类
3. **关键词降级**：当 Ollama 不可用或不启用时，使用关键词匹配 → 默认返回「普通」

## 配置选项

在 `classifyEmail()` 函数中可配置：

- `enableOllama`：是否启用 Ollama 模型分类，默认 `true`
- `enableBlackwords`：是否启用黑名单过滤，默认 `false`
- `blackwordsPath`：黑名单 JSON 文件路径，默认 `./blackwords.json`

## 黑名单格式

`blackwords.json` 文件格式：

```json
{
  "blackwords": [
    "spam",
    "fake",
    "click here"
  ]
}
```

## 日志功能

服务集成了详细的请求日志中间件，会打印：
- HTTP 方法和请求 URI
- 请求头信息
- 请求体内容
- 响应状态

## 依赖项

- **shelf** - HTTP 服务框架
- **shelf_router** - 路由管理
- **ollama_dart** - Ollama 模型调用库
- **path** - 文件路径处理

## 开发

### 主要文件说明

- `server.dart`：定义 `/classify` 和 `/health` 路由，处理 JSON 解析和响应格式转换
- `classifier.dart`：实现邮件分类逻辑和黑名单加载
- `ollama_client.dart`：调用 Ollama API，使用 Few-shot Learning 引导模型输出格式
- `logging_middleware.dart`：捕获和打印完整的 HTTP 请求内容

## 许可证

GNU General Public License 3

## 贡献

欢迎提交 Issue 和 Pull Request！
