/**
 * 任务回调接口
 * 职责：
 * 1. 定义任务的生命周期回调
 * 2. 所有回调都在主线程执行
 *
 * @author panruiqi
 * @CreateTime 2025年12月01日
 */

export interface TaskCallback {
  /**
   * 任务开始执行
   */
  onStart(): void;
  
  /**
   * 进度更新
   * @param progress 进度值，范围0.0-1.0
   */
  onProgress(progress: number): void;
  
  /**
   * 任务成功完成
   */
  onSuccess(): void;
  
  /**
   * 任务失败
   */
  onFailure(): void;
  
  /**
   * 任务被取消（可选实现）
   */
  onCancelled?(): void;
  
  /**
   * 任务超时（可选实现）
   */
  onTimeout?(): void;
  
  /**
   * 发生错误（可选实现）
   * @param error 错误信息
   */
  onError?(error: Error): void;
}
