# Changelog

All notable changes to this project will be documented in this file.
## [1.0.2] - 2025-12-10

### Added
- 完善 README 文档：相关文档

## [1.0.1] - 2025-12-10

### Added
- 添加 `homepage` 字段
- 添加 `example` 示例目录
- 完善 README 文档：实现方案、功能验证、使用注意事项

### Fixed
- 修复 `repository` 链接

## [1.0.0] - 2025-12-10

### Added
- 初始版本发布
- FFmpegManager：单工作线程 + 优先级任务队列架构
- FFmpegFactory：预置常用格式转换命令
- FFMpegUtils：底层 FFmpeg 命令执行封装
- 支持视频格式转换：MP4、FLV、AVI、MKV、TS
- 支持音频提取：MP3、AAC
- 支持网络流媒体下载
- 任务优先级支持（HIGH、NORMAL、LOW）
- 进度回调支持
- 任务取消支持
- 完整的错误处理机制
