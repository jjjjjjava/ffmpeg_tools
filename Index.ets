/**
 * @prq/ffmpeg-tools - HarmonyOS FFmpeg 工具库
 *
 * 架构：单工作线程 + 优先级任务队列
 * FFmpeg 内部使用全局变量，不支持多线程并发，必须串行执行
 *
 * @author prq
 * @version 1.0.0
 */

// 核心管理类
export { FFmpegManager } from './src/main/ets/ffmpeg/FFmpegManager';

// 任务相关
export { Task } from './src/main/ets/ffmpeg/Task';
export { TaskConfig, TaskConfigBuilder } from './src/main/ets/ffmpeg/TaskConfig';
export { TaskCallback } from './src/main/ets/ffmpeg/TaskCallback';
export { TaskPriority } from './src/main/ets/ffmpeg/TaskPriority';

// 命令工厂
export { FFmpegFactory } from './src/main/ets/ffmpeg/FFmpegFactory';

// 日志工具
export { FLog } from './src/main/ets/ffmpeg/FLog';

// FFmpeg 原生封装
export { FFMpegUtils, FFmpegCommandOptions } from './src/main/ets/ffmpeg/FFMpegUtils';
