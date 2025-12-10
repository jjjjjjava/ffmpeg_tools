/**
 * FFmpeg命令工厂类
 * 职责：构建各种FFmpeg命令
 *
 * @author panruiqi
 * @CreateTime 2025年12月01日
 */

export class FFmpegFactory {
  /**
   * FLV转MP4（直接复制流，最快）
   */
  public static buildFlv2Mp4(inputPath: string, outputPath: string): string[] {
    return [
      'ffmpeg',
      '-i', inputPath,
      '-vcodec', 'copy',
      '-acodec', 'aac',
      '-y',
      outputPath
    ];
  }
  
  /**
   * MP4直接复制
   */
  public static buildMp42Mp4(inputPath: string, outputPath: string): string[] {
    return [
      'ffmpeg',
      '-i', inputPath,
      '-c', 'copy',
      '-y',
      outputPath
    ];
  }

  /**
   * MP4转FLV
   */
  public static buildMp42Flv(inputPath: string, outputPath: string): string[] {
    return [
      'ffmpeg',
      '-i', inputPath,
      '-c:v', 'copy',
      '-c:a', 'aac',
      '-f', 'flv',
      '-y',
      outputPath
    ];
  }

  /**
   * MP4转AVI
   */
  public static buildMp42Avi(inputPath: string, outputPath: string): string[] {
    return [
      'ffmpeg',
      '-i', inputPath,
      '-c:v', 'copy',
      '-c:a', 'copy',
      '-f', 'avi',
      '-y',
      outputPath
    ];
  }

  /**
   * MP4转MKV
   */
  public static buildMp42Mkv(inputPath: string, outputPath: string): string[] {
    return [
      'ffmpeg',
      '-i', inputPath,
      '-c:v', 'copy',
      '-c:a', 'copy',
      '-f', 'matroska',
      '-y',
      outputPath
    ];
  }

  /**
   * MP4转TS
   */
  public static buildMp42Ts(inputPath: string, outputPath: string): string[] {
    return [
      'ffmpeg',
      '-i', inputPath,
      '-c:v', 'copy',
      '-c:a', 'aac',
      '-f', 'mpegts',
      '-y',
      outputPath
    ];
  }

  /**
   * 提取音频为MP3
   */
  public static buildExtractMp3(inputPath: string, outputPath: string): string[] {
    return [
      'ffmpeg',
      '-i', inputPath,
      '-vn',
      '-acodec', 'libmp3lame',
      '-ab', '128k',
      '-y',
      outputPath
    ];
  }

  /**
   * 提取音频为AAC
   */
  public static buildExtractAac(inputPath: string, outputPath: string): string[] {
    return [
      'ffmpeg',
      '-i', inputPath,
      '-vn',
      '-acodec', 'aac',
      '-y',
      outputPath
    ];
  }
  
  /**
   * RTSP转MP4（H265）
   */
  public static buildRtsp2Mp4(inputPath: string, outputPath: string): string[] {
    return [
      'ffmpeg',
      '-rtsp_transport', 'tcp',
      '-i', inputPath,
      '-vcodec', 'copy',
      '-tag:v', 'hvc1',
      '-acodec', 'aac',
      '-f', 'mp4',
      '-y',
      outputPath
    ];
  }
  
  /**
   * 视频缩放
   */
  public static buildScaleVideo(
    inputPath: string,
    outputPath: string,
    width: number,
    height: number
  ): string[] {
    return [
      'ffmpeg',
      '-i', inputPath,
      '-vf', `scale=${width}:${height}`,
      '-y',
      outputPath
    ];
  }
  
  /**
   * 添加水印
   */
  public static buildAddWatermark(
    videoPath: string,
    watermarkPath: string,
    outputPath: string
  ): string[] {
    return [
      'ffmpeg',
      '-i', videoPath,
      '-i', watermarkPath,
      '-filter_complex', 'overlay=(main_w-overlay_w)/2:(main_h-overlay_h)/2',
      '-c:v', 'libx264',
      '-c:a', 'copy',
      '-preset', 'ultrafast',
      '-y',
      outputPath
    ];
  }
  
  /**
   * 视频截取
   */
  public static buildCutVideo(
    inputPath: string,
    outputPath: string,
    startTime: string,
    duration: string
  ): string[] {
    return [
      'ffmpeg',
      '-i', inputPath,
      '-ss', startTime,
      '-t', duration,
      '-vcodec', 'copy',
      '-acodec', 'copy',
      '-y',
      outputPath
    ];
  }
}
