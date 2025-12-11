/**
 * @prq/ffmpeg-tools 基本使用示例
 *
 * 本示例展示如何使用 FFmpeg 工具库进行视频格式转换
 */

import { FFmpegManager, FFmpegFactory, TaskCallback, FLog } from '@prq/ffmpeg-tools';

/**
 * 示例1：基本视频转换
 */
function basicConversion() {
  const inputPath = '/path/to/input.mp4';
  const outputPath = '/path/to/output.flv';

  // 获取 FFmpegManager 单例
  const manager = FFmpegManager.getInstance();

  // 使用 FFmpegFactory 构建转换命令
  const commands = FFmpegFactory.buildMp42Flv(inputPath, outputPath);

  // 执行转换任务
  const taskId = manager.execute(
    commands,
    120000, // 超时时间（毫秒）
    {
      onStart: () => {
        console.log('转换开始');
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

  console.log(`任务ID: ${taskId}`);
}

/**
 * 示例2：从网络URL下载并转换
 */
function downloadAndConvert() {
  const videoUrl = buffer.from(
    'aHR0cHM6Ly9zbnMtdmlkZW8tYWwueGhzY2RuLmNvbS9zdHJlYW0vMTEwLzQwNS8wMWU1ODNjYjZlMGZlZDVhMDEwMzcwMDM4YzhhZDk2MmZiXzQwNS5tcDQ=',
    'base64'
  ).toString('binary');

  const outputPath = getContext().filesDir + '/downloaded.mp4';

  const manager = FFmpegManager.getInstance();

  // 使用 copy 模式快速下载（不重新编码）
  const commands = FFmpegFactory.buildMp42Mp4(videoUrl, outputPath);

  manager.execute(commands, 300000, {
    onStart: () => FLog.info('Download', '开始下载'),
    onProgress: (p: number) => FLog.info('Download', `下载进度: ${(p * 100).toFixed(1)}%`),
    onSuccess: () => FLog.info('Download', '下载完成'),
    onFailure: () => FLog.error('Download', '下载失败')
  } as TaskCallback);
}

/**
 * 示例3：提取音频
 */
function extractAudio() {
  const inputPath = '/path/to/video.mp4';
  const outputMp3 = '/path/to/audio.mp3';
  const outputAac = '/path/to/audio.aac';

  const manager = FFmpegManager.getInstance();

  // 提取 MP3
  manager.execute(
    FFmpegFactory.buildExtractMp3(inputPath, outputMp3),
    60000,
    {
      onStart: () => console.log('提取MP3开始'),
      onProgress: (p: number) => console.log(`MP3提取进度: ${(p * 100).toFixed(1)}%`),
      onSuccess: () => console.log('MP3提取成功'),
      onFailure: () => console.log('MP3提取失败')
    } as TaskCallback
  );

  // 提取 AAC
  manager.execute(
    FFmpegFactory.buildExtractAac(inputPath, outputAac),
    60000,
    {
      onStart: () => console.log('提取AAC开始'),
      onProgress: (p: number) => console.log(`AAC提取进度: ${(p * 100).toFixed(1)}%`),
      onSuccess: () => console.log('AAC提取成功'),
      onFailure: () => console.log('AAC提取失败')
    } as TaskCallback
  );
}

/**
 * 示例4：取消任务
 */
function cancelTask() {
  const manager = FFmpegManager.getInstance();

  const taskId = manager.execute(
    FFmpegFactory.buildMp42Mkv('/input.mp4', '/output.mkv'),
    120000,
    {
      onStart: () => console.log('开始'),
      onProgress: (p: number) => console.log(`${(p * 100).toFixed(1)}%`),
      onSuccess: () => console.log('成功'),
      onFailure: () => console.log('失败'),
      onCancelled: () => console.log('已取消')
    } as TaskCallback
  );

  // 5秒后取消任务
  setTimeout(() => {
    const success = manager.cancel(taskId);
    console.log(success ? '取消成功' : '取消失败');
  }, 5000);
}

/**
 * 示例5：支持的格式转换
 */
function supportedFormats() {
  const input = '/input.mp4';

  // 视频格式转换
  FFmpegFactory.buildMp42Flv(input, '/output.flv');  // MP4 → FLV
  FFmpegFactory.buildMp42Avi(input, '/output.avi');  // MP4 → AVI
  FFmpegFactory.buildMp42Mkv(input, '/output.mkv');  // MP4 → MKV
  FFmpegFactory.buildMp42Ts(input, '/output.ts');    // MP4 → TS
  FFmpegFactory.buildMp42Mp4(input, '/output.mp4');  // 视频复制

  // 音频提取
  FFmpegFactory.buildExtractMp3(input, '/output.mp3');  // 提取 MP3
  FFmpegFactory.buildExtractAac(input, '/output.aac');  // 提取 AAC
}
