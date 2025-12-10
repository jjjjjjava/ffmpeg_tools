/**
 * 日志工具类（HarmonyOS版本）
 * 使用 hilog 替代 Android 的 Log
 *
 * @author panruiqi
 * @CreateTime 2025年12月01日
 */

import hilog from '@ohos.hilog';

export class FLog {
  private static DEBUG: boolean = true;
  private static DOMAIN: number = 0x0000;  // 日志域，需要根据实际项目配置
  
  public static setDebug(debug: boolean): void {
    FLog.DEBUG = debug;
  }
  
  public static setDomain(domain: number): void {
    FLog.DOMAIN = domain;
  }
  
  public static info(tag: string, msg: string): void {
    if (FLog.DEBUG) {
      hilog.info(FLog.DOMAIN, tag, msg);
    }
  }
  
  public static error(tag: string, msg: string): void {
    if (FLog.DEBUG) {
      hilog.error(FLog.DOMAIN, tag, msg);
    }
  }
  
  public static debug(tag: string, msg: string): void {
    if (FLog.DEBUG) {
      hilog.debug(FLog.DOMAIN, tag, msg);
    }
  }
  
  public static warn(tag: string, msg: string): void {
    if (FLog.DEBUG) {
      hilog.warn(FLog.DOMAIN, tag, msg);
    }
  }
}
