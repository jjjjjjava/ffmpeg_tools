/**
 * 任务配置
 * 职责：
 * 1. 封装任务的所有配置参数
 * 2. 支持硬件解码、超时、重试等
 *
 * @author panruiqi
 * @CreateTime 2025年12月01日
 */

export class TaskConfig {
  private useHardwareDecoder: boolean;
  private timeoutMs: number;
  private retryCount: number;
  
  public  constructor(builder: TaskConfigBuilder) {
    this.useHardwareDecoder = builder.useHardwareDecoder;
    this.timeoutMs = builder.timeoutMs;
    this.retryCount = builder.retryCount;
  }
  
  /**
   * 默认配置
   */
  public static defaultConfig(): TaskConfig {
    return new TaskConfigBuilder().build();
  }
  
  // ==================== Getters ====================
  
  public isUseHardwareDecoder(): boolean {
    return this.useHardwareDecoder;
  }
  
  public getTimeoutMs(): number {
    return this.timeoutMs;
  }
  
  public getRetryCount(): number {
    return this.retryCount;
  }
  
  public toString(): string {
    return `TaskConfig{useHardwareDecoder=${this.useHardwareDecoder}, timeoutMs=${this.timeoutMs}, retryCount=${this.retryCount}}`;
  }
}

/**
 * TaskConfig Builder
 */
export class TaskConfigBuilder {
  public useHardwareDecoder: boolean = false;  // 默认软解
  public timeoutMs: number = 0;                // 默认不超时
  public retryCount: number = 0;               // 默认不重试
  
  public setHardwareDecoder(useHardwareDecoder: boolean): TaskConfigBuilder {
    this.useHardwareDecoder = useHardwareDecoder;
    return this;
  }
  
  public setTimeout(timeoutMs: number): TaskConfigBuilder {
    if (timeoutMs < 0) {
      throw new Error('timeoutMs must be >= 0');
    }
    this.timeoutMs = timeoutMs;
    return this;
  }
  
  public setRetryCount(retryCount: number): TaskConfigBuilder {
    if (retryCount < 0) {
      throw new Error('retryCount must be >= 0');
    }
    this.retryCount = retryCount;
    return this;
  }
  
  public build(): TaskConfig {
    return new TaskConfig(this);
  }
}
