/**
 * @prq/ffmpeg-tools - HarmonyOS FFmpeg 工具库
 *
 * @author prq
 * @version 2.0.0
 */

// 核心管理类
export { FFmpegManager } from './src/main/ets/ffmpeg/FFmpegManager';

// 任务相关
export { Task } from './src/main/ets/ffmpeg/Task';
export { TaskConfig, TaskConfigBuilder } from './src/main/ets/ffmpeg/TaskConfig';
export { TaskCallback } from './src/main/ets/ffmpeg/TaskCallback';
export { TaskPriority } from './src/main/ets/ffmpeg/TaskPriority';

// 命令工厂（简单易用）
export { FFmpegFactory, ContainerFormat } from './src/main/ets/ffmpeg/FFmpegFactory';

// 命令构建器（高级定制）
export { FFmpegCommandBuilder } from './src/main/ets/ffmpeg/FFmpegCommandBuilder';

// 日志工具
export { FLog } from './src/main/ets/ffmpeg/FLog';

// FFmpeg 原生封装
export { FFMpegUtils, FFmpegCommandOptions } from './src/main/ets/ffmpeg/FFMpegUtils';
