/**
 * FFmpeg 命令工厂类
 *
 * 设计原则：零配置，拿来即用
 * - 所有方法默认使用 h264_ohosavcodec 硬解硬编
 * - 需要定制请使用 FFmpegCommandBuilder
 *
 * @author panruiqi
 * @version 2.0.0
 */

/**
 * 容器格式
 */
export enum ContainerFormat {
  MP4 = 'mp4',
  FLV = 'flv',
  MKV = 'matroska',
  AVI = 'avi',
  TS = 'mpegts'
}

/**
 * FFmpeg 命令工厂
 */
export class FFmpegFactory {
  /** 硬件编解码器 */
  private static readonly HW_CODEC: string = 'h264_ohosavcodec';

  // ============================================================
  // 零拷贝类（不需要解码，最快）
  // ============================================================

  /**
   * 封装格式转换（零拷贝）
   */
  public static remux(input: string, output: string, format: ContainerFormat = ContainerFormat.MP4): string[] {
    const audioCodec = format === ContainerFormat.FLV ? 'aac' : 'copy';
    return ['ffmpeg', '-i', input, '-c:v', 'copy', '-c:a', audioCodec, '-f', format, '-y', output];
  }

  /**
   * 视频裁剪（零拷贝）
   */
  public static cut(input: string, output: string, startTime: string, duration: string): string[] {
    return ['ffmpeg', '-ss', startTime, '-i', input, '-t', duration, '-c:v', 'copy', '-c:a', 'copy', '-avoid_negative_ts', 'make_zero', '-y', output];
  }

  /**
   * 提取音频（AAC）
   */
  public static extractAudio(input: string, output: string): string[] {
    return ['ffmpeg', '-i', input, '-vn', '-c:a', 'aac', '-b:a', '128k', '-y', output];
  }

  // ============================================================
  // 需解码类（硬解硬编）
  // ============================================================

  /**
   * 视频缩放
   */
  public static scale(input: string, output: string, width: number, height: number): string[] {
    return [
      'ffmpeg',
      '-c:v', FFmpegFactory.HW_CODEC,
      '-i', input,
      '-vf', `scale=${width}:${height}`,
      '-c:v', FFmpegFactory.HW_CODEC,
      '-c:a', 'copy',
      '-y', output
    ];
  }

  /**
   * 添加水印（右下角）
   * 注意：overlay 滤镜需要软解码，硬编码输出
   */
  public static watermark(input: string, watermarkImg: string, output: string): string[] {
    return [
      'ffmpeg',
      '-i', input,
      '-i', watermarkImg,
      '-filter_complex', '[0:v][1:v]overlay=main_w-overlay_w-10:main_h-overlay_h-10[outv]',
      '-map', '[outv]',
      '-map', '0:a',
      '-c:v', FFmpegFactory.HW_CODEC,
      '-c:a', 'copy',
      '-y', output
    ];
  }

  /**
   * 视频转码
   */
  public static transcode(input: string, output: string, bitrate?: string): string[] {
    const cmd: string[] = [
      'ffmpeg',
      '-i', input,
      '-c:v', FFmpegFactory.HW_CODEC
    ];
    if (bitrate !== undefined) {
      cmd.push('-b:v', bitrate);
    }
    cmd.push('-c:a', 'aac', '-y', output);
    return cmd;
  }

  /**
   * 视频拼接
   */
  public static concat(inputFiles: string[], output: string): string[] {
    const cmd: string[] = ['ffmpeg', '-c:v', FFmpegFactory.HW_CODEC];

    for (let i = 0; i < inputFiles.length; i++) {
      cmd.push('-i', inputFiles[i]);
    }

    let filterInputs = '';
    for (let i = 0; i < inputFiles.length; i++) {
      filterInputs += `[${i}:v][${i}:a]`;
    }

    cmd.push(
      '-filter_complex', `${filterInputs}concat=n=${inputFiles.length}:v=1:a=1[outv][outa]`,
      '-map', '[outv]',
      '-map', '[outa]',
      '-c:v', FFmpegFactory.HW_CODEC,
      '-c:a', 'aac',
      '-y', output
    );
    return cmd;
  }

  // ============================================================
  // 网络流媒体
  // ============================================================

  /**
   * RTSP 流录制
   */
  public static downloadRtsp(rtspUrl: string, output: string, duration?: number): string[] {
    const cmd: string[] = ['ffmpeg', '-rtsp_transport', 'tcp', '-i', rtspUrl, '-c:v', 'copy', '-c:a', 'aac'];
    if (duration !== undefined) {
      cmd.push('-t', duration.toString());
    }
    cmd.push('-tag:v', 'hvc1', '-f', 'mp4', '-y', output);
    return cmd;
  }

  /**
   * HLS 流下载
   */
  public static downloadHls(hlsUrl: string, output: string): string[] {
    return ['ffmpeg', '-i', hlsUrl, '-c:v', 'copy', '-c:a', 'copy', '-y', output];
  }
}
