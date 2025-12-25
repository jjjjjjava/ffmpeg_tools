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

  // ============================================================
  // 图片处理
  // ============================================================

  /**
   * 视频转 GIF
   * @param input 输入视频路径
   * @param output 输出 GIF 路径
   * @param fps 帧率，默认 10
   * @param width 宽度，默认 320（保持宽高比）
   */
  public static videoToGif(input: string, output: string, fps: number = 10, width: number = 320): string[] {
    return [
      'ffmpeg',
      '-i', input,
      '-vf', `fps=${fps},scale=${width}:-1:flags=lanczos`,
      '-y', output
    ];
  }

  /**
   * 视频截图（单帧）
   * @param input 输入视频路径
   * @param output 输出图片路径
   * @param time 截图时间点，格式 "00:00:05"
   */
  public static videoSnapshot(input: string, output: string, time: string = '00:00:01'): string[] {
    return [
      'ffmpeg',
      '-ss', time,
      '-i', input,
      '-vframes', '1',
      '-q:v', '2',
      '-y', output
    ];
  }

  /**
   * 视频批量截图
   * @param input 输入视频路径
   * @param outputPattern 输出图片路径模式，如 "/path/frame_%04d.jpg"
   * @param fps 每秒截取帧数，默认 1（每秒1张）
   */
  public static videoToImages(input: string, outputPattern: string, fps: number = 1): string[] {
    return [
      'ffmpeg',
      '-i', input,
      '-vf', `fps=${fps}`,
      '-q:v', '2',
      '-y', outputPattern
    ];
  }

  /**
   * 图片序列合成视频
   * @param inputPattern 输入图片路径模式，如 "/path/frame_%04d.jpg"
   * @param output 输出视频路径
   * @param fps 视频帧率，默认 25
   */
  public static imagesToVideo(inputPattern: string, output: string, fps: number = 25): string[] {
    return [
      'ffmpeg',
      '-framerate', fps.toString(),
      '-i', inputPattern,
      '-c:v', FFmpegFactory.HW_CODEC,
      '-pix_fmt', 'yuv420p',
      '-y', output
    ];
  }

  /**
   * 图片缩放
   * @param input 输入图片路径
   * @param output 输出图片路径
   * @param width 目标宽度
   * @param height 目标高度（-1 表示保持宽高比）
   */
  public static imageScale(input: string, output: string, width: number, height: number = -1): string[] {
    return [
      'ffmpeg',
      '-i', input,
      '-vf', `scale=${width}:${height}`,
      '-q:v', '2',
      '-y', output
    ];
  }

  /**
   * 图片格式转换
   * @param input 输入图片路径
   * @param output 输出图片路径
   * @param quality 质量 1-31（数字越小质量越高），默认 2
   */
  public static imageConvert(input: string, output: string, quality: number = 2): string[] {
    return [
      'ffmpeg',
      '-i', input,
      '-q:v', quality.toString(),
      '-y', output
    ];
  }

  /**
   * 图片添加水印
   * @param input 输入图片路径
   * @param watermark 水印图片路径
   * @param output 输出图片路径
   * @param position 位置：'top-left' | 'top-right' | 'bottom-left' | 'bottom-right' | 'center'
   */
  public static imageWatermark(
    input: string,
    watermark: string,
    output: string,
    position: string = 'bottom-right'
  ): string[] {
    let overlay = '';
    switch (position) {
      case 'top-left':
        overlay = '10:10';
        break;
      case 'top-right':
        overlay = 'main_w-overlay_w-10:10';
        break;
      case 'bottom-left':
        overlay = '10:main_h-overlay_h-10';
        break;
      case 'bottom-right':
        overlay = 'main_w-overlay_w-10:main_h-overlay_h-10';
        break;
      case 'center':
        overlay = '(main_w-overlay_w)/2:(main_h-overlay_h)/2';
        break;
      default:
        overlay = 'main_w-overlay_w-10:main_h-overlay_h-10';
    }

    return [
      'ffmpeg',
      '-i', input,
      '-i', watermark,
      '-filter_complex', `[0:v][1:v]overlay=${overlay}`,
      '-q:v', '2',
      '-y', output
    ];
  }

  /**
   * 图片拼接（横向）
   * @param inputs 输入图片路径数组
   * @param output 输出图片路径
   */
  public static imageHStack(inputs: string[], output: string): string[] {
    const cmd: string[] = ['ffmpeg'];
    
    for (const input of inputs) {
      cmd.push('-i', input);
    }

    let filterInputs = '';
    for (let i = 0; i < inputs.length; i++) {
      filterInputs += `[${i}:v]`;
    }

    cmd.push(
      '-filter_complex', `${filterInputs}hstack=inputs=${inputs.length}`,
      '-q:v', '2',
      '-y', output
    );
    return cmd;
  }

  /**
   * 图片拼接（纵向）
   * @param inputs 输入图片路径数组
   * @param output 输出图片路径
   */
  public static imageVStack(inputs: string[], output: string): string[] {
    const cmd: string[] = ['ffmpeg'];
    
    for (const input of inputs) {
      cmd.push('-i', input);
    }

    let filterInputs = '';
    for (let i = 0; i < inputs.length; i++) {
      filterInputs += `[${i}:v]`;
    }

    cmd.push(
      '-filter_complex', `${filterInputs}vstack=inputs=${inputs.length}`,
      '-q:v', '2',
      '-y', output
    );
    return cmd;
  }

  /**
   * 图片旋转
   * @param input 输入图片路径
   * @param output 输出图片路径
   * @param angle 旋转角度：90, 180, 270
   */
  public static imageRotate(input: string, output: string, angle: number): string[] {
    let transpose = '';
    switch (angle) {
      case 90:
        transpose = 'transpose=1'; // 顺时针 90°
        break;
      case 180:
        transpose = 'transpose=1,transpose=1'; // 180°
        break;
      case 270:
        transpose = 'transpose=2'; // 逆时针 90°
        break;
      default:
        transpose = 'transpose=1';
    }

    return [
      'ffmpeg',
      '-i', input,
      '-vf', transpose,
      '-q:v', '2',
      '-y', output
    ];
  }

  /**
   * 图片裁剪
   * @param input 输入图片路径
   * @param output 输出图片路径
   * @param width 裁剪宽度
   * @param height 裁剪高度
   * @param x 起始 X 坐标
   * @param y 起始 Y 坐标
   */
  public static imageCrop(
    input: string,
    output: string,
    width: number,
    height: number,
    x: number = 0,
    y: number = 0
  ): string[] {
    return [
      'ffmpeg',
      '-i', input,
      '-vf', `crop=${width}:${height}:${x}:${y}`,
      '-q:v', '2',
      '-y', output
    ];
  }

  /**
   * 图片添加文字
   * @param input 输入图片路径
   * @param output 输出图片路径
   * @param text 文字内容
   * @param fontSize 字体大小，默认 24
   * @param color 文字颜色，默认白色 'white'
   * @param x X 坐标，默认 10
   * @param y Y 坐标，默认 10
   */
  public static imageAddText(
    input: string,
    output: string,
    text: string,
    fontSize: number = 24,
    color: string = 'white',
    x: number = 10,
    y: number = 10
  ): string[] {
    return [
      'ffmpeg',
      '-i', input,
      '-vf', `drawtext=text='${text}':fontsize=${fontSize}:fontcolor=${color}:x=${x}:y=${y}`,
      '-q:v', '2',
      '-y', output
    ];
  }
}

