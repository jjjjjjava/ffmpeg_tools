# Changelog

All notable changes to this project will be documented in this file.

## [2.0.0] - 2025-12-16

### Added
- **硬件加速支持**：新增 `h264_ohosavcodec` 硬解硬编支持
- **FFmpegFactory 重构**：零配置 API，拿来即用
  - `remux()` - 封装格式转换（零拷贝）
  - `cut()` - 视频裁剪（零拷贝）
  - `extractAudio()` - 音频提取
  - `scale()` - 视频缩放（硬解硬编）
  - `watermark()` - 添加水印（硬编码）
  - `transcode()` - 视频转码（硬解硬编）
  - `concat()` - 视频拼接（硬解硬编）
  - `downloadRtsp()` - RTSP 流录制
  - `downloadHls()` - HLS 流下载
- **FFmpegCommandBuilder**：链式 API 构建自定义命令
  - 支持 `hwaccel()`, `hwDecode()`, `hwEncode()` 硬件加速
  - 支持 `scale()`, `fps()`, `filter()` 滤镜
  - 支持 `videoCodec()`, `audioCodec()`, `videoBitrate()` 编码参数
- **ContainerFormat 枚举**：MP4, FLV, MKV, AVI, TS
- **Native 日志控制**：`FFMpegUtils.showLog(true/false)`

### Changed
- 重构 FFmpegFactory，移除旧的 `buildMp42Xxx` 方法
- 默认使用硬件编解码器 `h264_ohosavcodec`
- 更新 README 文档

### Breaking Changes
- `FFmpegFactory` API 完全重构，旧方法已移除
- 需要链接 HarmonyOS 媒体系统库（native_media_codecbase, native_media_core, native_media_vdec, native_media_venc）

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
