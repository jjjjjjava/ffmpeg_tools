/**
 * FFmpeg 工具类 - ArkTS 封装层
 * 提供 Promise 风格的 FFmpeg 命令执行接口
 */

import libAddon from 'libffmpegutils.so'

/**
 * FFmpeg 命令执行选项接口
 */
export interface FFmpegCommandOptions {
  /**
   * FFmpeg 命令参数数组
   * 例如：['-i', 'input.mp4', '-c:v', 'libx264', 'output.mp4']
   */
  cmds: Array<string>;
  
  /**
   * 进度回调函数
   * @param progress 进度百分比 (0-100)
   */
  onFFmpegProgress: (progress: number) => void;
  
  /**
   * 失败回调函数
   * @param code 错误码
   * @param msg 错误消息
   */
  onFFmpegFail: (code: number, msg: string) => void;
  
  /**
   * 成功回调函数
   */
  onFFmpegSuccess: () => void;
}

/**
 * FFmpeg 工具类
 * 提供视频处理、格式转换等功能
 */
export class FFMpegUtils {
  /**
   * 执行 FFmpeg 命令
   * 
   * @param options 命令执行选项
   * @returns Promise，resolve 返回执行结果码（0表示成功），reject 返回错误信息
   * 
   * @example
   * ```typescript
   * // 示例1：视频格式转换
   * FFMpegUtils.executeFFmpegCommand({
   *   cmds: ['-i', 'input.flv', '-c:v', 'libx264', '-c:a', 'aac', 'output.mp4'],
   *   onFFmpegProgress: (progress) => {
   *     console.log(`转换进度: ${progress}%`);
   *   },
   *   onFFmpegFail: (code, msg) => {
   *     console.error(`转换失败: ${code} - ${msg}`);
   *   },
   *   onFFmpegSuccess: () => {
   *     console.log('转换成功！');
   *   }
   * });
   * 
   * // 示例2：从URL下载并转换
   * FFMpegUtils.executeFFmpegCommand({
   *   cmds: ['-i', 'http://example.com/video.flv', '-c', 'copy', 'output.mp4'],
   *   onFFmpegProgress: (progress) => {
   *     console.log(`下载进度: ${progress}%`);
   *   },
   *   onFFmpegFail: (code, msg) => {
   *     console.error(`下载失败: ${code} - ${msg}`);
   *   },
   *   onFFmpegSuccess: () => {
   *     console.log('下载成功！');
   *   }
   * });
   * ```
   */
  static executeFFmpegCommand(options: FFmpegCommandOptions): Promise<number> {
    // 生成唯一标识符（UUID）
    let uuid = FFMpegUtils.generateUUID32();
    
    // 绑定回调函数到全局，供 Native 层调用
    libAddon.JSBind.bindFunction(uuid + "_onFFmpegProgress", options.onFFmpegProgress);
    libAddon.JSBind.bindFunction(uuid + "_onFFmpegFail", options.onFFmpegFail);
    libAddon.JSBind.bindFunction(uuid + "_onFFmpegSuccess", options.onFFmpegSuccess);
    
    // 打印命令（用于调试）
    console.info(`[FFMpegUtils] Executing command: ${options.cmds.join(' ')}`);
    
    // 调用 Native 方法执行 FFmpeg 命令
    return new Promise<number>((resolve, reject) => {
      try {
        libAddon.executeFFmpegCommandAPP(uuid, options.cmds.length, options.cmds)
          .then((code: number) => {
            console.info(`[FFMpegUtils] Command completed with code: ${code}`);
            resolve(code);
          })
          .catch((err: Error) => {
            console.error(`[FFMpegUtils] Command failed:`, err);
            reject(err);
          });
      } catch (e) {
        console.error(`[FFMpegUtils] Exception:`, e);
        reject(e);
      }
    });
  }
  
  /**
   * 启用或禁用 FFmpeg 日志输出
   * 
   * @param show true 显示日志，false 不显示
   */
  static showLog(show: boolean): void {
    try {
      libAddon.showLog(show);
      console.info(`[FFMpegUtils] FFmpeg logging ${show ? 'enabled' : 'disabled'}`);
    } catch (e) {
      console.error(`[FFMpegUtils] Failed to set logging:`, e);
    }
  }
  
  /**
   * 生成32位 UUID
   * @returns UUID 字符串
   */
  private static generateUUID32(): string {
    const chars = '0123456789abcdef';
    let uuid = '';
    for (let i = 0; i < 32; i++) {
      // 替换索引访问为 charAt() 方法
      uuid += chars.charAt(Math.floor(Math.random() * 16));
    }
    return uuid;
  }
  
  /**
   * 便捷方法：视频格式转换
   * 
   * @param inputPath 输入文件路径或URL
   * @param outputPath 输出文件路径
   * @param onProgress 进度回调
   * @returns Promise
   */
  static convertVideo(
    inputPath: string,
    outputPath: string,
    onProgress?: (progress: number) => void
  ): Promise<number> {
    return FFMpegUtils.executeFFmpegCommand({
      cmds: ['-i', inputPath, '-c:v', 'libx264', '-c:a', 'aac', outputPath],
      onFFmpegProgress: onProgress || ((progress) => {
        console.log(`Progress: ${progress}%`);
      }),
      onFFmpegFail: (code, msg) => {
        console.error(`Conversion failed: ${code} - ${msg}`);
      },
      onFFmpegSuccess: () => {
        console.log('Conversion succeeded!');
      }
    });
  }
  
  /**
   * 便捷方法：从URL下载视频并转换
   * 
   * @param url 视频URL
   * @param outputPath 输出文件路径
   * @param onProgress 进度回调
   * @returns Promise
   */
  static downloadAndConvert(
    url: string,
    outputPath: string,
    onProgress?: (progress: number) => void
  ): Promise<number> {
    return FFMpegUtils.executeFFmpegCommand({
      cmds: ['-i', url, '-c', 'copy', outputPath],
      onFFmpegProgress: onProgress || ((progress) => {
        console.log(`Download progress: ${progress}%`);
      }),
      onFFmpegFail: (code, msg) => {
        console.error(`Download failed: ${code} - ${msg}`);
      },
      onFFmpegSuccess: () => {
        console.log('Download succeeded!');
      }
    });
  }
}
