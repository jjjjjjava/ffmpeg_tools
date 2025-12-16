/**
 * FFmpeg 命令构建器
 * 链式 API 构建复杂的 FFmpeg 命令，供高级用户定制使用
 *
 * @author panruiqi
 * @version 2.0.0
 */

/**
 * FFmpeg 命令构建器
 *
 * @example
 * ```typescript
 * const cmd = new FFmpegCommandBuilder()
 *   .input('/path/to/input.mp4')
 *   .hwaccel()
 *   .filter('scale=1280:720')
 *   .videoCodec('libx264')
 *   .videoBitrate('2M')
 *   .output('/path/to/output.mp4')
 *   .build();
 * ```
 */
export class FFmpegCommandBuilder {
  private static readonly HW_CODEC: string = 'h264_ohosavcodec';

  private inputFiles: string[] = [];
  private outputPath: string = '';
  private useHwDecode: boolean = false;
  private useHwEncode: boolean = false;
  private filters: string[] = [];
  private vCodec: string = '';
  private aCodec: string = '';
  private vBitrate: string = '';
  private aBitrate: string = '';
  private presetValue: string = '';
  private crfValue: number = -1;
  private formatValue: string = '';
  private durationValue: string = '';
  private startTimeValue: string = '';
  private extraArgs: string[] = [];

  /** 添加输入文件 */
  public input(path: string): FFmpegCommandBuilder {
    this.inputFiles.push(path);
    return this;
  }

  /** 设置输出文件 */
  public output(path: string): FFmpegCommandBuilder {
    this.outputPath = path;
    return this;
  }

  /** 启用硬件加速（硬解+硬编） */
  public hwaccel(): FFmpegCommandBuilder {
    this.useHwDecode = true;
    this.useHwEncode = true;
    return this;
  }

  /** 启用硬件解码 */
  public hwDecode(): FFmpegCommandBuilder {
    this.useHwDecode = true;
    return this;
  }

  /** 启用硬件编码 */
  public hwEncode(): FFmpegCommandBuilder {
    this.useHwEncode = true;
    return this;
  }

  /** 添加视频滤镜 */
  public filter(filterExpr: string): FFmpegCommandBuilder {
    this.filters.push(filterExpr);
    return this;
  }

  /** 设置视频编码器 */
  public videoCodec(codec: string): FFmpegCommandBuilder {
    this.vCodec = codec;
    return this;
  }

  /** 设置音频编码器 */
  public audioCodec(codec: string): FFmpegCommandBuilder {
    this.aCodec = codec;
    return this;
  }

  /** 设置视频码率 */
  public videoBitrate(bitrate: string): FFmpegCommandBuilder {
    this.vBitrate = bitrate;
    return this;
  }

  /** 设置音频码率 */
  public audioBitrate(bitrate: string): FFmpegCommandBuilder {
    this.aBitrate = bitrate;
    return this;
  }

  /** 设置 x264 预设 */
  public preset(value: string): FFmpegCommandBuilder {
    this.presetValue = value;
    return this;
  }

  /** 设置 CRF 质量 */
  public crf(value: number): FFmpegCommandBuilder {
    this.crfValue = value;
    return this;
  }

  /** 设置输出格式 */
  public format(fmt: string): FFmpegCommandBuilder {
    this.formatValue = fmt;
    return this;
  }

  /** 设置开始时间 */
  public startTime(time: string): FFmpegCommandBuilder {
    this.startTimeValue = time;
    return this;
  }

  /** 设置持续时长 */
  public duration(time: string): FFmpegCommandBuilder {
    this.durationValue = time;
    return this;
  }

  /** 视频缩放 */
  public scale(width: number, height: number): FFmpegCommandBuilder {
    return this.filter(`scale=${width}:${height}`);
  }

  /** 帧率设置 */
  public fps(value: number): FFmpegCommandBuilder {
    return this.filter(`fps=${value}`);
  }

  /** 添加额外参数 */
  public arg(key: string, value?: string): FFmpegCommandBuilder {
    this.extraArgs.push(key);
    if (value !== undefined) {
      this.extraArgs.push(value);
    }
    return this;
  }

  /** 构建命令数组 */
  public build(): string[] {
    if (this.inputFiles.length === 0) {
      throw new Error('At least one input is required');
    }
    if (this.outputPath === '') {
      throw new Error('Output path is required');
    }

    const cmd: string[] = ['ffmpeg'];

    // 硬解码
    if (this.useHwDecode) {
      cmd.push('-c:v', FFmpegCommandBuilder.HW_CODEC);
    }

    // 开始时间
    if (this.startTimeValue !== '') {
      cmd.push('-ss', this.startTimeValue);
    }

    // 输入文件
    for (let i = 0; i < this.inputFiles.length; i++) {
      cmd.push('-i', this.inputFiles[i]);
    }

    // 持续时长
    if (this.durationValue !== '') {
      cmd.push('-t', this.durationValue);
    }

    // 视频滤镜
    if (this.filters.length > 0) {
      cmd.push('-vf', this.filters.join(','));
    }

    // 视频编码
    if (this.useHwEncode) {
      cmd.push('-c:v', FFmpegCommandBuilder.HW_CODEC);
    } else if (this.vCodec !== '') {
      cmd.push('-c:v', this.vCodec);
    }

    // 视频码率
    if (this.vBitrate !== '') {
      cmd.push('-b:v', this.vBitrate);
    }

    // CRF
    if (this.crfValue >= 0) {
      cmd.push('-crf', this.crfValue.toString());
    }

    // 预设
    if (this.presetValue !== '') {
      cmd.push('-preset', this.presetValue);
    }

    // 音频编码
    if (this.aCodec !== '') {
      cmd.push('-c:a', this.aCodec);
    }

    // 音频码率
    if (this.aBitrate !== '') {
      cmd.push('-b:a', this.aBitrate);
    }

    // 输出格式
    if (this.formatValue !== '') {
      cmd.push('-f', this.formatValue);
    }

    // 额外参数
    for (let i = 0; i < this.extraArgs.length; i++) {
      cmd.push(this.extraArgs[i]);
    }

    // 覆盖输出
    cmd.push('-y', this.outputPath);

    return cmd;
  }

  /** 构建命令字符串（调试用） */
  public buildString(): string {
    return this.build().join(' ');
  }

  /** 重置构建器 */
  public reset(): FFmpegCommandBuilder {
    this.inputFiles = [];
    this.outputPath = '';
    this.useHwDecode = false;
    this.useHwEncode = false;
    this.filters = [];
    this.vCodec = '';
    this.aCodec = '';
    this.vBitrate = '';
    this.aBitrate = '';
    this.presetValue = '';
    this.crfValue = -1;
    this.formatValue = '';
    this.durationValue = '';
    this.startTimeValue = '';
    this.extraArgs = [];
    return this;
  }
}
