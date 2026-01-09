# Changelog

All notable changes to this project will be documented in this file.

## [2.2.1] - 2026-01-09

### Added

- native层可以正确的返回错误

## [2.2.0] - 2025-12-26

### Added

- **native层日志支持**：默认开启 native 日志
- **降低API版本要求**：将 最低SDK版本从 17 降低到 12，让库可以在更多设备上运行

## [2.1.0] - 2025-12-25

### Added
- **图片处理支持**：新增 13 个图片处理方法
  - `videoToGif()` - 视频转 GIF 动图
  - `videoSnapshot()` - 视频截图（单帧）
  - `videoToImages()` - 视频批量截图
  - `imagesToVideo()` - 图片序列合成视频
  - `imageScale()` - 图片缩放
  - `imageConvert()` - 图片格式转换
  - `imageWatermark()` - 图片添加水印（支持5个位置）
  - `imageHStack()` - 图片横向拼接
  - `imageVStack()` - 图片纵向拼接
  - `imageRotate()` - 图片旋转（90/180/270度）
  - `imageCrop()` - 图片裁剪
  - `imageAddText()` - 图片添加文字

### Fixed
- **修复视频缩放失败问题**：移除输入前的硬解码器指定，避免音频流解析错误
  - 问题：`-c:v h264_ohosavcodec -i input` 导致音频流解码失败
  - 解决：改为 `-i input ... -c:v h264_ohosavcodec` 只在输出时使用硬编码
- **优化音频处理**：视频缩放时音频使用 copy 模式，提升性能

### Changed
- 更新 README 文档，新增图片处理 API 说明
- 优化 FFmpegFactory 代码结构，按功能分类
- 圣诞节快乐

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

