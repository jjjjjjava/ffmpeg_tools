/**
 * FFmpeg 管理器 - 核心入口类（重构版）
 * 
 * 架构说明：
 * - FFmpeg 内部使用大量全局变量，不支持多线程并发执行
 * - 采用单工作线程 + 优先级任务队列的架构
 * - 工作线程阻塞等待任务，避免轮询浪费资源
 * 
 * 流程：应用层 → FFmpegManager.execute() → 任务入队 → 工作线程消费 → Native执行
 *
 * @author panruiqi
 * @CreateTime 2025年12月01日
 */

import { Task } from './Task';
import { TaskConfig } from './TaskConfig';
import { TaskCallback } from './TaskCallback';
import { TaskPriority } from './TaskPriority';
import { FFMpegUtils } from './FFMpegUtils';
import { FLog } from './FLog';
import util from '@ohos.util';

export class FFmpegManager {
  private static TAG: string = 'FFmpegManager';
  private static instance: FFmpegManager | null = null;
  
  // 优先级任务队列
  private taskQueue: Task[] = [];
  
  // 活动任务记录（用于取消）
  private activeTasks: Map<string, Task> = new Map();
  
  // 当前正在执行的任务
  private currentTask: Task | null = null;
  
  // 工作线程控制
  private isRunning: boolean = true;
  private taskResolver: (() => void) | null = null;
  
  private constructor() {
    FLog.info(FFmpegManager.TAG, 'FFmpegManager initialized');
    // 启动工作线程
    this.startWorkerLoop();
  }
  
  /**
   * 获取单例实例
   */
  public static getInstance(): FFmpegManager {
    if (FFmpegManager.instance === null) {
      FFmpegManager.instance = new FFmpegManager();
    }
    return FFmpegManager.instance;
  }
  
  /**
   * 执行FFmpeg任务（使用默认配置）
   */
  public execute(commands: string[], duration: number, callback: TaskCallback): string {
    return this.executeWithConfig(commands, duration, TaskConfig.defaultConfig(), callback);
  }
  
  /**
   * 执行FFmpeg任务（完整版本）
   */
  public executeWithConfig(
    commands: string[], 
    duration: number, 
    config: TaskConfig, 
    callback: TaskCallback
  ): string {
    const taskId = util.generateRandomUUID(true);
    const task = new Task(taskId, commands, duration, config, callback);
    
    // 记录活动任务
    this.activeTasks.set(taskId, task);
    
    // 按优先级入队
    this.enqueueByPriority(task);
    
    // 唤醒工作线程
    this.notifyWorker();
    
    FLog.info(FFmpegManager.TAG, `Task enqueued: ${taskId}`);
    return taskId;
  }
  
  /**
   * 执行FFmpeg任务（带优先级）
   */
  public executeWithPriority(
    commands: string[], 
    duration: number, 
    priority: TaskPriority,
    callback: TaskCallback
  ): string {
    const taskId = util.generateRandomUUID(true);
    const task = new Task(taskId, commands, duration, TaskConfig.defaultConfig(), callback);
    task.setPriority(priority);
    
    this.activeTasks.set(taskId, task);
    this.enqueueByPriority(task);
    this.notifyWorker();
    
    FLog.info(FFmpegManager.TAG, `Task enqueued with priority ${priority}: ${taskId}`);
    return taskId;
  }
  
  /**
   * 取消指定任务
   */
  public cancel(taskId: string): boolean {
    const task = this.activeTasks.get(taskId);
    if (!task) {
      FLog.warn(FFmpegManager.TAG, `Cancel failed: task not found - ${taskId}`);
      return false;
    }
    
    task.cancel();
    
    // 从队列中移除（如果还在队列中）
    const index = this.taskQueue.findIndex(t => t.getId() === taskId);
    if (index !== -1) {
      this.taskQueue.splice(index, 1);
      this.dispatchCallback(task, 'cancelled');
    }
    
    FLog.info(FFmpegManager.TAG, `Task cancelled: ${taskId}`);
    return true;
  }
  
  /**
   * 取消所有任务
   */
  public cancelAll(): void {
    FLog.info(FFmpegManager.TAG, 'Cancelling all tasks...');
    
    // 取消队列中的任务
    this.taskQueue.forEach(task => {
      task.cancel();
      this.dispatchCallback(task, 'cancelled');
    });
    this.taskQueue = [];
    
    // 取消当前执行的任务
    if (this.currentTask) {
      this.currentTask.cancel();
    }
    
    this.activeTasks.clear();
  }
  
  /**
   * 获取等待中的任务数量
   */
  public getPendingTaskCount(): number {
    return this.taskQueue.length;
  }
  
  /**
   * 获取活动任务数量（包括执行中和等待中）
   */
  public getActiveTaskCount(): number {
    return this.activeTasks.size;
  }
  
  /**
   * 销毁管理器
   */
  public destroy(): void {
    FLog.info(FFmpegManager.TAG, 'Destroying FFmpegManager...');
    
    this.isRunning = false;
    this.cancelAll();
    this.notifyWorker(); // 唤醒工作线程使其退出
    
    FFmpegManager.instance = null;
  }
  
  // ==================== 私有方法 ====================
  
  /**
   * 按优先级插入任务队列
   */
  private enqueueByPriority(task: Task): void {
    const priorityValue = this.getPriorityValue(task.getPriority());
    let inserted = false;
    
    for (let i = 0; i < this.taskQueue.length; i++) {
      if (priorityValue > this.getPriorityValue(this.taskQueue[i].getPriority())) {
        this.taskQueue.splice(i, 0, task);
        inserted = true;
        break;
      }
    }
    
    if (!inserted) {
      this.taskQueue.push(task);
    }
  }
  
  /**
   * 获取优先级数值
   */
  private getPriorityValue(priority: TaskPriority): number {
    switch (priority) {
      case TaskPriority.HIGH: return 3;
      case TaskPriority.NORMAL: return 2;
      case TaskPriority.LOW: return 1;
      default: return 2;
    }
  }
  
  /**
   * 唤醒工作线程
   */
  private notifyWorker(): void {
    if (this.taskResolver) {
      this.taskResolver();
      this.taskResolver = null;
    }
  }
  
  /**
   * 等待任务（阻塞）
   */
  private waitForTask(): Promise<Task | null> {
    return new Promise<Task | null>((resolve) => {
      // 如果队列有任务，直接返回
      if (this.taskQueue.length > 0) {
        resolve(this.taskQueue.shift() || null);
        return;
      }
      
      // 没有任务，阻塞等待
      this.taskResolver = () => {
        resolve(this.taskQueue.shift() || null);
      };
    });
  }
  
  /**
   * 工作线程主循环
   */
  private async startWorkerLoop(): Promise<void> {
    FLog.info(FFmpegManager.TAG, 'Worker loop started');
    
    while (this.isRunning) {
      // 1. 等待任务（阻塞）
      const task = await this.waitForTask();
      
      if (!task || !this.isRunning) {
        continue;
      }
      
      // 2. 检查任务是否已取消
      if (task.isCancelled()) {
        FLog.info(FFmpegManager.TAG, `Task already cancelled: ${task.getId()}`);
        continue;
      }
      
      // 3. 执行任务
      this.currentTask = task;
      await this.executeTask(task);
      this.currentTask = null;
      
      // 4. 清理
      this.activeTasks.delete(task.getId());
    }
    
    FLog.info(FFmpegManager.TAG, 'Worker loop stopped');
  }
  
  /**
   * 执行单个任务
   * 注意：taskFailed/failCode/failMsg 必须是局部变量，确保多任务环境下状态隔离
   */
  private async executeTask(task: Task): Promise<void> {
    FLog.info(FFmpegManager.TAG, `Executing task: ${task.getId()}`);
    
    // 回调：开始
    this.dispatchCallback(task, 'start');
    
    // 任务级别的状态变量（局部变量，确保多任务状态隔离）
    let taskFailed = false;
    let failCode = 0;
    let failMsg = '';
    
    try {
      const commands = task.getCommands();
      
      await FFMpegUtils.executeFFmpegCommand({
        cmds: commands,
        
        onFFmpegProgress: (progress: number) => {
          if (!task.isCancelled()) {
            task.updateProgress(progress / 100);
            this.dispatchCallback(task, 'progress', progress / 100);
          }
        },
        
        onFFmpegFail: (code: number, msg: string) => {
          FLog.error(FFmpegManager.TAG, `Task failed: ${task.getId()}, code=${code}, msg=${msg}`);
          taskFailed = true;
          failCode = code;
          failMsg = msg;
        },
        
        onFFmpegSuccess: () => {
          FLog.info(FFmpegManager.TAG, `Task success: ${task.getId()}`);
        }
      });
      
      // 根据实际执行结果分发回调
      if (task.isCancelled()) {
        this.dispatchCallback(task, 'cancelled');
      } else if (taskFailed) {
        this.dispatchCallback(task, 'failure');
        this.dispatchCallback(task, 'error', new Error(`FFmpeg error: code=${failCode}, msg=${failMsg}`));
      } else {
        this.dispatchCallback(task, 'success');
      }
      
    } catch (error) {
      FLog.error(FFmpegManager.TAG, `Task error: ${task.getId()}, ${error}`);
      
      if (!task.isCancelled()) {
        this.dispatchCallback(task, 'failure');
        this.dispatchCallback(task, 'error', error as Error);
      }
    }
  }
  
  /**
   * 分发回调到主线程
   */
  private dispatchCallback(task: Task, type: string, data?: number | Error): void {
    // 使用 setTimeout 切换到主线程
    setTimeout(() => {
      try {
        const callback = task.getCallback();
        
        switch (type) {
          case 'start':
            callback.onStart();
            break;
          case 'progress':
            callback.onProgress(data as number);
            break;
          case 'success':
            callback.onSuccess();
            break;
          case 'failure':
            callback.onFailure();
            break;
          case 'cancelled':
            callback.onCancelled?.();
            break;
          case 'timeout':
            callback.onTimeout?.();
            break;
          case 'error':
            callback.onError?.(data as Error);
            break;
        }
      } catch (e) {
        FLog.error(FFmpegManager.TAG, `Callback error: ${e}`);
      }
    }, 0);
  }
}
