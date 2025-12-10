/**
 * 任务对象
 * 职责：
 * 1. 封装任务的所有信息
 * 2. 维护任务状态
 * 3. 不依赖静态变量
 *
 * @author panruiqi
 * @CreateTime 2025年12月01日
 */

import { TaskConfig } from './TaskConfig';
import { TaskCallback } from './TaskCallback';
import { TaskPriority } from './TaskPriority';

export class Task {
  private id: string;
  private commands: string[];
  private duration: number;
  private config: TaskConfig;
  private callback: TaskCallback;
  private createTime: number;
  
  private cancelled: boolean = false;
  private progress: number = 0;
  private priority: TaskPriority = TaskPriority.NORMAL;
  
  constructor(
    id: string,
    commands: string[],
    duration: number,
    config: TaskConfig,
    callback: TaskCallback
  ) {
    this.id = id;
    this.commands = commands;
    this.duration = duration;
    this.config = config;
    this.callback = callback;
    this.createTime = Date.now();
  }
  
  // ==================== Getters ====================
  
  public getId(): string {
    return this.id;
  }
  
  public getCommands(): string[] {
    return this.commands;
  }
  
  public getDuration(): number {
    return this.duration;
  }
  
  public getConfig(): TaskConfig {
    return this.config;
  }
  
  public getCallback(): TaskCallback {
    return this.callback;
  }
  
  public getCreateTime(): number {
    return this.createTime;
  }
  
  public getPriority(): TaskPriority {
    return this.priority;
  }
  
  public setPriority(priority: TaskPriority): void {
    this.priority = priority;
  }
  
  // ==================== 状态管理 ====================
  
  public isCancelled(): boolean {
    return this.cancelled;
  }
  
  public cancel(): void {
    this.cancelled = true;
  }
  
  public getProgress(): number {
    return this.progress;
  }
  
  public updateProgress(newProgress: number): void {
    this.progress = newProgress;
  }
  
  public toString(): string {
    return `Task{id='${this.id}', priority=${this.priority}, progress=${this.progress}, cancelled=${this.cancelled}}`;
  }
}
