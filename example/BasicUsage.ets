/**
 * FFmpegTools 使用示例
 */

import {
  FFmpegManager,
  FFmpegFactory,
  FFmpegCommandBuilder,
  TaskCallback,
  ContainerFormat
} from '../Index';

export class BasicUsageExample {
  private manager: FFmpegManager = FFmpegManager.getInstance();

  // ============================================================
  // 零拷贝（最快）
  // ============================================================

  /** 封装格式转换 */
  remux(): void {
    const cmd = FFmpegFactory.remux('/input.mp4', '/output.mkv', ContainerFormat.MKV);
    this.run(cmd);
  }

  /** 视频裁剪 */
  cut(): void {
    const cmd = FFmpegFactory.cut('/input.mp4', '/clip.mp4', '00:01:00', '30');
    this.run(cmd);
  }

  /** 提取音频 */
  extractAudio(): void {
    const cmd = FFmpegFactory.extractAudio('/video.mp4', '/audio.aac');
    this.run(cmd);
  }

  // ============================================================
  // 硬解硬编（零配置）
  // ============================================================

  /** 视频缩放 */
  scale(): void {
    const cmd = FFmpegFactory.scale('/input.mp4', '/720p.mp4', 1280, 720);
    this.run(cmd);
  }

  /** 添加水印 */
  watermark(): void {
    const cmd = FFmpegFactory.watermark('/input.mp4', '/logo.png', '/output.mp4');
    this.run(cmd);
  }

  /** 视频转码 */
  transcode(): void {
    const cmd = FFmpegFactory.transcode('/input.mp4', '/output.mp4', '2M');
    this.run(cmd);
  }

  /** 视频拼接 */
  concat(): void {
    const cmd = FFmpegFactory.concat(['/p1.mp4', '/p2.mp4', '/p3.mp4'], '/merged.mp4');
    this.run(cmd);
  }

  // ============================================================
  // 网络流
  // ============================================================

  /** RTSP 录制 */
  rtsp(): void {
    const cmd = FFmpegFactory.downloadRtsp('rtsp://192.168.1.100/stream', '/record.mp4', 60);
    this.run(cmd);
  }

  /** HLS 下载 */
  hls(): void {
    const cmd = FFmpegFactory.downloadHls('https://example.com/playlist.m3u8', '/download.mp4');
    this.run(cmd);
  }

  // ============================================================
  // 高级定制（Builder）
  // ============================================================

  /** 自定义命令 */
  custom(): void {
    const cmd = new FFmpegCommandBuilder()
      .input('/input.mp4')
      .hwaccel()
      .scale(1280, 720)
      .fps(30)
      .videoBitrate('2M')
      .audioCodec('aac')
      .audioBitrate('128k')
      .output('/output.mp4')
      .build();

    console.info('命令: ' + cmd.join(' '));
    this.run(cmd);
  }

  /** 软编码（x264） */
  softEncode(): void {
    const cmd = new FFmpegCommandBuilder()
      .input('/input.mp4')
      .hwDecode()
      .scale(1280, 720)
      .videoCodec('libx264')
      .crf(23)
      .preset('fast')
      .audioCodec('aac')
      .output('/output.mp4')
      .build();

    this.run(cmd);
  }

  // ============================================================
  // 工具方法
  // ============================================================

  private run(cmd: string[]): void {
    const callback: TaskCallback = {
      onStart: (): void => { console.info('开始'); },
      onProgress: (p: number): void => { console.info(`进度: ${(p * 100).toFixed(1)}%`); },
      onSuccess: (): void => { console.info('成功'); },
      onFailure: (): void => { console.info('失败'); }
    };
    this.manager.execute(cmd, 120000, callback);
  }
}
