# @prq/ffmpeg-tools

HarmonyOS FFmpeg 工具库 —— 在鸿蒙中调用 FFmpeg 命令行工具（fftools），最终驱动 FFmpeg.so 执行音视频处理任务。同时提供硬件加速能力，在保证稳定性的前提下显著提升处理效率。

## 安装

```bash
ohpm install @prq/ffmpeg-tools
```

## 特性

本库的核心能力是将 FFmpeg 命令行工具封装为 ArkTS 可调用的 Native 接口，支持：

- 提供统一、可编程的音视频处理能力
- 支持转码、提取、下载等常见场景
- 内置完善的任务管理与进度控制机制
- 提供硬件解码与编码加速能力，在保证稳定性的前提下显著提升处理效率，适合对性能与能耗敏感的音视频场景。
- 最低运行版本 *"compatibleSdkVersion": "5.0.0(12)"*

## 为什么选我

- **体积小巧**：仅 **11.46MB**，在同类工具中体量最小，可有效控制包体积增长。
- **能力灵活且完备**：既支持通过 `FFmpegCommandBuilder` 链式构建自定义 FFmpeg 命令，也在 `FFmpegFactory` 中内置了多种常用命令，开箱即用。
- **性能表现优秀**：支持硬件加速，2 分钟视频加水印仅需 **15.68s**。
- **实现透明、可扩展**：整体原理与核心代码均已开源，并提供完整的实现笔记与文档参考，便于二次开发与问题排查。

## 功能验证

### 1.零拷贝

已测试从网络 MP4 下载并转换为 `mkv`、`avi`、`mp4` 等格式，输出结果正常可用。

**示例执行命令：**

```
ffmpeg -i https://example.com/video.mp4 -c:v copy -c:a copy -f avi -y /data/storage/el2/base/haps/entry/files/output.avi
```

**性能统计：**
- 原视频大小：4981937 字节（约 4.75MB），时长 2 分钟
- MP4 → MP4（copy）：耗时 0.42s，输出 4981937 字节
- MP4 → MKV（copy）：耗时 0.35s，输出 4831.78 KB

**示例结果：**

- 进行多个格式转换
  - ![结果1](./src/main/resources/base/media/pic1.png)
- 提取到电脑上播放
  - ![结果2](./src/main/resources/base/media/pic2.png)

### 2. 硬解硬编

#### 2.1 视频加水印

**示例执行命令：**

```
ffmpeg -i https://sns-video-al.xhscdn.com/stream/110/405/01e583cb6e0fed5a010370038c8ad962fb_405.mp4 
-i /data/storage/el2/base/haps/entry/files/watermark_selected.png -filter_complex [0:v][1:v]overlay=main_w-overlay_w-10:main_h-overlay_h-10[outv] -map [outv] -map 0:a -c:v h264_ohosavcodec -c:a copy -y /data/storage/el2/base/haps/entry/files/watermark_output.mp4
```

- 这里使用的是h264_ohosavcodec进行硬解码和硬编码相关处理

**性能统计：**

- 2分钟时长视频，硬解加水印耗时约15.68S
- [1:41:13 PM]：输出文件大小:90712.12 KB

**示例结果：**

- 提取到电脑上播放
  - ![结果3](./src/main/resources/base/media/pic3.png)



#### 2.2 视频裁剪

**测试素材配置**：

1. 编码：H.264
2. 时长：约 1 分 34 秒
3. 原始大小：4.75 MB

**示例执行命令：**

```
ffmpeg -i /data/storage/el2/base/haps/entry/files/selected_video.mp4
-vf crop=640:360:0:0
-c:v h264_ohosavcodec
-c:a copy
-vsync cfr -fps_mode cfr
-max_muxing_queue_size 1024
-y /data/storage/el2/base/haps/entry/files/crop_output.mp4
```

**执行流程**：

1. 输入视频：H.264
2. 硬解码（GPU）→ 原始 YUV 帧
3. crop 滤镜（CPU）→ 裁剪后的 YUV
4. 硬编码（GPU）→ 输出 H.264 视频

**性能统计：**

- 总耗时：10.04 s
- 输出文件大小：约 16.34 MB（16742.76 KB）
- ![结果5](./src/main/resources/base/media/pic5.png)

**示例结果：**对比32s位置，方便大家进行对比观测效果

- 原始画面
  - ![结果6](./src/main/resources/base/media/pic6.png)

- 视频裁剪后画面
  - ![结果7](./src/main/resources/base/media/pic7.png)



#### 2.3 视频转码

**测试素材配置**：

1. 编码：H.264
2. 时长：约 6 分 48 秒
3. 原始大小：49.2 MB
4. 原始码率：1012 kbps

**示例执行命令：**

```
ffmpeg -i /data/storage/el2/base/haps/entry/files/selected_video.mp4
-c:v h264_ohosavcodec -b:v 300k -c:a aac -y
/data/storage/el2/base/haps/entry/files/low_bitrate_300k.mp4

ffmpeg -i /data/storage/el2/base/haps/entry/files/selected_video.mp4
-c:v h264_ohosavcodec -b:v 500k -c:a aac -y
/data/storage/el2/base/haps/entry/files/low_bitrate_500k.mp4
```

**结果统计：**

- 目标码率：500k（粗略设置）
  - 实际输出码率：约 648 kbps
  - 输出文件大小：31.5 MB
  - 相比原始视频体积降低约 36%

- 目标码率：300k（粗略设置）
  - 实际输出码率：约 440 kbps
  - 输出文件大小：21.4 MB
  - 相比原始视频体积降低约 56%

- 耗时：针对时长为 6 分 48 秒的视频，单次转码耗时约 67.77 秒

注：实际输出码率略高于设置值，符合编码器在质量与码率控制之间的正常行为，但整体趋势与预期一致，码率控制已生效。

**示例结果：**

原视频信息：

- 码率
  - ![结果8](./src/main/resources/base/media/pic8.png)

- 大小
  - ![结果9](./src/main/resources/base/media/pic9.png)

粗略设置为300k码率

- 码率
  - ![结果10](./src/main/resources/base/media/pic12.png)

- 帧率
  - ![结果11](./src/main/resources/base/media/pic13.png)



画面对比

- 原画面
  - ![结果15](./src/main/resources/base/media/pic15.png)

- 粗略设置为300k码率
  - ![结果14](./src/main/resources/base/media/pic14.png)

## 快速开始

### 基本使用

```typescript
import { FFmpegManager, FFmpegFactory, ContainerFormat, TaskCallback } from '@prq/ffmpeg-tools';

// 获取管理器实例
const manager = FFmpegManager.getInstance();

// 执行视频格式转换（零拷贝）
const taskId = manager.execute(
  FFmpegFactory.remux(inputPath, outputPath, ContainerFormat.FLV),
  120000, // 超时时间（毫秒）
  {
    onStart: () => console.log('任务开始'),
    onProgress: (progress: number) => console.log(`进度: ${(progress * 100).toFixed(1)}%`),
    onSuccess: () => console.log('转换成功'),
    onFailure: () => console.log('转换失败')
  } as TaskCallback
);

// 取消任务
manager.cancel(taskId);
```

### 开启 Native 日志

```typescript
import { FFMpegUtils } from '@prq/ffmpeg-tools';

// 开启 FFmpeg native 层日志输出
FFMpegUtils.showLog(true);
```

### 零拷贝操作（最快）

```typescript
import { FFmpegFactory, ContainerFormat } from '@prq/ffmpeg-tools';

// 封装格式转换
FFmpegFactory.remux(input, output, ContainerFormat.MP4);  // 默认 MP4
FFmpegFactory.remux(input, output, ContainerFormat.FLV);  // MP4 → FLV
FFmpegFactory.remux(input, output, ContainerFormat.AVI);  // MP4 → AVI
FFmpegFactory.remux(input, output, ContainerFormat.MKV);  // MP4 → MKV
FFmpegFactory.remux(input, output, ContainerFormat.TS);   // MP4 → TS

// 视频裁剪
FFmpegFactory.cut(input, output, '00:00:10', '30');  // 从10秒开始裁剪30秒

// 音频提取
FFmpegFactory.extractAudio(input, output);  // 提取 AAC 音频
```

### 硬解硬编操作（h264_ohosavcodec）

```typescript
import { FFmpegFactory } from '@prq/ffmpeg-tools';

// 视频缩放
FFmpegFactory.scale(input, output, 1280, 720);  // 缩放到 720p

// 视频转码
FFmpegFactory.transcode(input, output);         // 默认转码
FFmpegFactory.transcode(input, output, '2M');   // 指定码率 2Mbps

// 添加水印（右下角）
FFmpegFactory.watermark(input, watermarkImg, output);

// 视频拼接
FFmpegFactory.concat([video1, video2, video3], output);
```

### 网络流媒体

```typescript
import { FFmpegFactory } from '@prq/ffmpeg-tools';

// RTSP 流录制
FFmpegFactory.downloadRtsp(rtspUrl, output);           // 持续录制
FFmpegFactory.downloadRtsp(rtspUrl, output, 60);       // 录制60秒

// HLS 流下载
FFmpegFactory.downloadHls(hlsUrl, output);
```

### 高级定制（FFmpegCommandBuilder）

```typescript
import { FFmpegCommandBuilder } from '@prq/ffmpeg-tools';

// 链式构建自定义命令
const cmd = new FFmpegCommandBuilder()
  .input(inputPath)
  .hwaccel()                    // 启用硬解硬编
  .scale(1280, 720)             // 缩放
  .fps(30)                      // 帧率
  .videoBitrate('2M')           // 视频码率
  .audioCodec('aac')            // 音频编码
  .audioBitrate('128k')         // 音频码率
  .output(outputPath)
  .build();

// 执行命令
manager.execute(cmd, 180000, callback);
```

## 实现方案

### 总体思路

将 FFmpeg 命令行工具（fftools）封装为 ArkTS 可调用的 Native 库，ArkTS 以 API 形式驱动常见转码/下载任务。

### 跨语言通信

采用 **AKI 框架** 实现 ArkTS（ETS） ⇄ C++ 的双向调用：

- **ETS → Native**：通过 `JSBIND_PFUNCTION` 宏将执行接口注册到 ArkTS；请求进入 Native 后由框架投递到线程池执行
- **Native → ETS**：通过带 `UUID` 的回调机制上报任务进度与最终结果，回调可以把异步状态传回 ETS 层

### FFtools 源码改造

- 原 FFmpeg 在严重错误时会调用 `exit()` 导致进程退出
- 为避免影响宿主进程，已将 `exit_program()` 改为基于 `setjmp/longjmp` 的非局部跳转方案，使出错时能优雅返回错误码并由上层处理（而非终止进程）
- **状态隔离**：Native 层使用 `thread_local` 来尽可能隔离每个任务的局部状态，避免不同任务互相污染

### 并发处理

实测发现：FFmpeg 内部仍大量依赖全局变量与共享状态——因此不适合在同一进程内多线程并发执行多个 FFTools 实例；并发运行会导致互相干扰、崩溃或数据错乱。

**当前策略**：任务调度层通过限制工作线程数量为 1，保证串行执行。

## API

### FFmpegFactory（零配置命令工厂）

#### 视频处理

| 方法 | 说明 |
|------|------|
| `remux(input, output, format?)` | 封装格式转换（零拷贝） |
| `cut(input, output, startTime, duration)` | 视频裁剪（零拷贝） |
| `extractAudio(input, output)` | 提取音频（AAC） |
| `scale(input, output, width, height)` | 视频缩放（硬解硬编） |
| `watermark(input, watermarkImg, output)` | 添加水印（硬编码） |
| `transcode(input, output, bitrate?)` | 视频转码（硬解硬编） |
| `concat(inputFiles, output)` | 视频拼接（硬解硬编） |
| `downloadRtsp(rtspUrl, output, duration?)` | RTSP 流录制 |
| `downloadHls(hlsUrl, output)` | HLS 流下载 |
| videoCrop(   input,   output,   width,   height,   x,   y ) | 视频裁剪（crop + 硬解硬编） |
| videoCropCenter(   input,   output,   width,   height) | 视频居中裁剪（crop + 硬解硬编） |

#### 图片处理

| 方法 | 说明 |
|------|------|
| `videoToGif(input, output, fps?, width?)` | 视频转 GIF（默认 10fps, 320px 宽） |
| `videoSnapshot(input, output, time?)` | 视频截图（默认第1秒） |
| `videoToImages(input, outputPattern, fps?)` | 视频批量截图（默认每秒1张） |
| `imagesToVideo(inputPattern, output, fps?)` | 图片序列合成视频（默认 25fps） |
| `imageScale(input, output, width, height?)` | 图片缩放（height=-1 保持宽高比） |
| `imageConvert(input, output, quality?)` | 图片格式转换（quality: 1-31，默认2） |
| `imageWatermark(input, watermark, output, position?)` | 图片添加水印（支持5个位置） |
| `imageHStack(inputs, output)` | 图片横向拼接 |
| `imageVStack(inputs, output)` | 图片纵向拼接 |
| `imageRotate(input, output, angle)` | 图片旋转（90/180/270度） |
| `imageCrop(input, output, width, height, x?, y?)` | 图片裁剪 |
| `imageAddText(input, output, text, fontSize?, color?, x?, y?)` | 图片添加文字 |

### FFmpegCommandBuilder（高级定制）

| 方法 | 说明 |
|------|------|
| `input(path)` | 添加输入文件 |
| `output(path)` | 设置输出文件 |
| `hwaccel()` | 启用硬件加速（硬解+硬编） |
| `hwDecode()` | 仅启用硬件解码 |
| `hwEncode()` | 仅启用硬件编码 |
| `filter(expr)` | 添加视频滤镜 |
| `scale(width, height)` | 视频缩放 |
| `fps(value)` | 设置帧率 |
| `videoCodec(codec)` | 设置视频编码器 |
| `audioCodec(codec)` | 设置音频编码器 |
| `videoBitrate(bitrate)` | 设置视频码率 |
| `audioBitrate(bitrate)` | 设置音频码率 |
| `preset(value)` | 设置 x264 预设 |
| `crf(value)` | 设置 CRF 质量 |
| `format(fmt)` | 设置输出格式 |
| `startTime(time)` | 设置开始时间 |
| `duration(time)` | 设置持续时长 |
| `arg(key, value?)` | 添加额外参数 |
| `build()` | 构建命令数组 |
| `buildString()` | 构建命令字符串（调试用） |

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

### FFMpegUtils

| 方法 | 说明 |
|------|------|
| `executeFFmpegCommand(options)` | 执行 FFmpeg 命令（底层接口） |
| `showLog(show)` | 开启/关闭 Native 层日志 |

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

### ContainerFormat

| 格式 | 说明 |
|------|------|
| `MP4` | MP4 格式 |
| `FLV` | FLV 格式 |
| `MKV` | MKV 格式 |
| `AVI` | AVI 格式 |
| `TS` | MPEG-TS 格式 |

### TaskPriority

| 优先级 | 说明 |
|--------|------|
| `HIGH` | 高优先级 |
| `NORMAL` | 普通优先级（默认） |
| `LOW` | 低优先级 |

## 使用注意事项

1. **网络权限**：访问网络 URL 需要在 `module.json5` 中添加权限：
   ```json5
   "requestPermissions": [
     { "name": "ohos.permission.INTERNET" }
   ]
   ```

2. **包体积优化**：当前 `libffmpegutils.so` 约 70MB（依赖完整 FFmpeg 库）
   - 建议在 `module.json5` 中开启压缩：`"compressNativeLibs": true`
   - 可参考华为官方方案进行拆分与裁剪：[华为开发者博客](https://developer.huawei.com/consumer/cn/blog/topic/03171278604140060)

3. **架构支持**：仅支持 arm64-v8a 架构

4. **系统要求**：HarmonyOS 5.0+ (API 12+)

5. **并发限制**：FFmpeg 内部使用全局变量，不支持多线程并发执行，任务会串行处理

6. **当前优化：**

   1. 优化包体积管理，aki通过依赖引入，其自带了多个架构的so文件，nativeLib 配置来过滤无用的架构

      ```
      "buildOption": {
          "napiLibFilterOption": {
            "excludes": [
              "**/armeabi-v7a/**",
              "**/x86_64/**"
            ]
          }
        },
      ```

## 相关文档

- [FFmpegUtils 实现思路](https://blog.csdn.net/qq_35829566/article/details/155782443?sharetype=blogdetail&sharerId=155782443&sharerefer=PC&sharesource=qq_35829566&spm=1011.2480.3001.8118) 
- [鸿蒙下 FFmpeg 编译流程](https://blog.csdn.net/qq_35829566/article/details/155781896?sharetype=blogdetail&sharerId=155781896&sharerefer=PC&sharesource=qq_35829566&spm=1011.2480.3001.8118) 

## 🍎贡献代码与技术交流

- 使用过程中如发现问题，欢迎通过 [Issue](https://github.com/jjjjjjava/ffmpeg_tools/issues) 提交反馈；
- 也非常欢迎感兴趣的开发者提交 [PR](https://github.com/jjjjjjava/ffmpeg_tools/pulls)，共同完善项目；
- 若遇到较复杂的问题，建议开启 **native 层日志**，并携带相关日志信息反馈，我会尽快协助排查和处理。

## 后续更新计划

- 针对 [#issue5](https://github.com/jjjjjjava/ffmpeg_tools/issues/5)：设置了目标码率后，输出视频始终以较高码率生成，码率参数未生效的问题。
  - 已向官方 FFmpeg（OpenHarmony）仓库提交 Issue：
    https://gitee.com/openharmony-tpc-incubate/FFmpeg/issues/IDMF3P
  - 已整理并提交 MR，将本次修改合入官方源码
- 解决 [#issue7](https://github.com/jjjjjjava/ffmpeg_tools/issues/7)，丰富FFmpeg的能力

## 版本更新说明

### v2.0.0

提供硬件解码与编码加速能力，在保证稳定性的前提下显著提升处理效率，适合对性能与能耗敏感的音视频场景。

### v2.1.0

1.修复视频缩放场景下音频流未正确写入的问题

2.解决 [#issue1](https://github.com/jjjjjjava/ffmpeg_tools/issues/1)，新增图片处理相关能力

### v2.2.0

1.默认开启 native 日志

2.降低 API 版本要求：将 最低SDK版本从 17 降低到 12，让库可以在更多设备上运行

### v2.2.1

1.native层可以正确的返回错误

### v2.2.2

1.解决 [#issue2](https://github.com/jjjjjjava/ffmpeg_tools/issues/2)，修复 HAR 包缺少 libaki_jsbind.so 导致的 "Cannot read property JSBind of undefined" 错误

### v2.2.3

1.解决 [#issue3](https://github.com/jjjjjjava/ffmpeg_tools/issues/3)，新增视频裁剪相关能力

### v2.2.4

1.解决 [#issue5](https://github.com/jjjjjjava/ffmpeg_tools/issues/5)，解决显式设置了目标码率后，输出视频始终以较高码率生成，码率参数未生效的问题。

### v2.2.5

1.README 样式优化

### v2.2.6

1解决 [#issue6](https://github.com/jjjjjjava/ffmpeg_tools/issues/6)，解决直接使用execute方法导致崩溃

## 问题根因分析与修复方案（Root Cause & Fix）

### 1.[#issue5](https://github.com/jjjjjjava/ffmpeg_tools/issues/5)：码率设置失效

#### 01.问题现象（Issue Description）

在使用 FFmpeg 进行视频转码时，即使显式设置了目标码率（如 -b:v 300k / 500k），
输出视频始终以较高码率生成，码率参数未生效。

#### 02.根因定位（Root Cause）

经排查确认，该问题并非调用方式错误，而是 OHOS 版本 FFmpeg 源码实现缺失导致：
在 OHOS 平台的视频输出配置逻辑中
相关代码位置虽然进行了编码参数初始化
但未将用户设置的码率参数写入编码配置中

对应源码位置如下（未设置码率）：
![结果16](./src/main/resources/base/media/pic16.png)

#### 03.解决方案（Solution）

3.1 源码修改
在对应的视频编码配置逻辑中，补充码率参数设置，使其正确传递到编码器。

修改示例如下：
![结果17](./src/main/resources/base/media/pic17.png)

3.2 重新编译 FFmpeg

基于修改后的源码，重新编译 OHOS 平台 FFmpeg：
![结果18](./src/main/resources/base/media/pic18.png)

3.3 替换产物

将重新编译生成的 FFmpeg 相关产物替换到运行环境中：
![结果19](./src/main/resources/base/media/pic19.png)

### 2.[#issue6](https://github.com/jjjjjjava/ffmpeg_tools/issues/6)：直接使用execute方法导致崩溃

#### 01.问题现象（Issue Description）

执行 `FFmpegManager.getInstance().execute(["ffmpeg", "-version"], 30000, callback)` 时， 应用概率性崩溃，触发 SIGSEGV(SEGV_MAPERR) 信号。

崩溃堆栈如下：

```
#00 pc strnlen
#01 pc printf_core+2160
#02 pc vfprintf+172
#03 pc log_callback_help+76        (libffmpegutils.so)
#04 pc av_log+164                  (libffmpegutils.so)
#05 pc ffmpeg_parse_options+92     (libffmpegutils.so)
#06 pc exe_ffmpeg_cmd+192          (libffmpegutils.so)
```

成功时日志也可观察到异常：option 参数显示为乱码： `matched as option 'version' (show version) with argument '�L�['`

#### 02.根因定位（Root Cause）

问题出在 NAPI 绑定层的 `vector_to_argv()` 函数（napi_ffmpeg.cpp:58-79）。

该函数将 `std::vector<std::string>` 转换为 C 风格的 `char**` 时， 仅分配了 `argv.size()` 个元素，**未在末尾添加 NULL 终止符**。

标准 C 的 argv 约定要求 `argv[argc] == NULL`。FFmpeg 内部多处依赖此约定：

1. `cmdutils.c:761` — `OPT_EXIT` 选项（如 `-version`、`-h`）直接读取 `argv[optindex++]` 作为可选参数，不检查边界：

   ```c
   if (po->flags & OPT_EXIT) {
       arg = argv[optindex++];  // 越界读取 argv[2]，期望为 NULL
   }
   ```

2. `cmdutils.c:741` — `GET_ARG` 宏通过 `if (!arg)` 检测参数是否存在，依赖 NULL 哨兵值

3. `cmdutils.c:775` — `if (argv[optindex])` 检查，同样依赖 NULL 终止

由于缺少 NULL 终止符，`argv[argc]` 读取到堆上的随机数据：

- 若恰好指向可读内存 → 成功但日志显示乱码（如 `'�L�['`）
- 若指向未映射内存 → SIGSEGV 崩溃

这就是"概率性成功/崩溃"的原因。

#### 03.解决方案（Solution）

修改 `napi_ffmpeg.cpp` 中的 `vector_to_argv()` 函数，多分配一个位置并设置 NULL 终止符：

修改前：

```cpp
char** result = (char**)malloc(sizeof(char*) * argv.size());
// ... 填充 result[0] ~ result[size-1] ...
return result;
```

修改后：

![结果20](./src/main/resources/base/media/pic20.png)

修改文件：`lib_ffmpeg_utils/src/main/cpp/napi_ffmpeg.cpp`，`vector_to_argv()` 函数。

#### 04.影响范围（Impact）

此问题影响所有 FFmpeg 命令的执行，不仅限于 `-version`。 任何带 `OPT_EXIT` 标志的选项（`-version`、`-h`、`-help`、`-buildconf` 等） 以及 AVOption 解析路径都可能触发越界读取。

修复后所有 FFmpeg 命令执行均可稳定运行，不再出现概率性崩溃。

## 鸣谢

感谢 **zpswz、FXY970610、magicalapp、peerless2012** 提出的相关 issue，帮助我更好地完善和验证了本项目。

## License

MIT
