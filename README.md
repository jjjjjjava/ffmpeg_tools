# @prq/ffmpeg-tools

HarmonyOS FFmpeg 工具库，提供视频格式转换、音频提取、流媒体处理等功能。

## 安装

```bash
ohpm install @prq/ffmpeg-tools
```

## 特性

- 支持多种视频格式转换（MP4、FLV、AVI、MKV、TS）
- 支持音频提取（MP3、AAC）
- 支持网络流媒体下载
- 优先级任务队列
- 进度回调
- 任务取消

## 快速开始

### 基本使用

```typescript
import { FFmpegManager, FFmpegFactory, TaskCallback } from '@prq/ffmpeg-tools';

// 获取管理器实例
const manager = FFmpegManager.getInstance();

// 执行视频转换
const taskId = manager.execute(
  FFmpegFactory.buildMp42Flv(inputPath, outputPath),
  120000, // 超时时间（毫秒）
  {
    onStart: () => {
      console.log('任务开始');
    },
    onProgress: (progress: number) => {
      console.log(`进度: ${(progress * 100).toFixed(1)}%`);
    },
    onSuccess: () => {
      console.log('转换成功');
    },
    onFailure: () => {
      console.log('转换失败');
    }
  } as TaskCallback
);

// 取消任务
manager.cancel(taskId);
```

### 支持的格式转换

```typescript
import { FFmpegFactory } from '@prq/ffmpeg-tools';

// 视频格式转换
FFmpegFactory.buildMp42Flv(input, output);  // MP4 → FLV
FFmpegFactory.buildMp42Avi(input, output);  // MP4 → AVI
FFmpegFactory.buildMp42Mkv(input, output);  // MP4 → MKV
FFmpegFactory.buildMp42Ts(input, output);   // MP4 → TS
FFmpegFactory.buildMp42Mp4(input, output);  // 视频复制

// 音频提取
FFmpegFactory.buildExtractMp3(input, output);  // 提取 MP3
FFmpegFactory.buildExtractAac(input, output);  // 提取 AAC
```

### 自定义命令

```typescript
import { FFMpegUtils } from '@prq/ffmpeg-tools';

FFMpegUtils.executeFFmpegCommand({
  cmds: ['-i', inputPath, '-c:v', 'libx264', '-c:a', 'aac', outputPath],
  onFFmpegProgress: (progress) => {
    console.log(`进度: ${progress}%`);
  },
  onFFmpegFail: (code, msg) => {
    console.error(`失败: ${code} - ${msg}`);
  },
  onFFmpegSuccess: () => {
    console.log('成功');
  }
});
```

## API

### FFmpegManager

| 方法 | 说明 |
|------|------|
| `getInstance()` | 获取单例实例 |
| `execute(commands, duration, callback)` | 执行任务 |
| `executeWithPriority(commands, duration, priority, callback)` | 带优先级执行 |
| `cancel(taskId)` | 取消任务 |
| `cancelAll()` | 取消所有任务 |
| `getPendingTaskCount()` | 获取等待任务数 |
| `getActiveTaskCount()` | 获取活动任务数 |

### TaskCallback

| 回调 | 说明 |
|------|------|
| `onStart()` | 任务开始 |
| `onProgress(progress)` | 进度更新 (0-1) |
| `onSuccess()` | 任务成功 |
| `onFailure()` | 任务失败 |
| `onCancelled?()` | 任务取消 |
| `onTimeout?()` | 任务超时 |
| `onError?(error)` | 错误信息 |

### TaskPriority

| 优先级 | 说明 |
|--------|------|
| `HIGH` | 高优先级 |
| `NORMAL` | 普通优先级（默认） |
| `LOW` | 低优先级 |

## 注意事项

1. FFmpeg 内部使用全局变量，不支持多线程并发执行，任务会串行处理
2. 仅支持 arm64-v8a 架构
3. 需要 HarmonyOS 5.0+ (API 12+)

## License

MIT
