export declare class JSBind {
  static bindFunction(name: string, callback: Function): number;
}

export interface FFprobeResult {
  code: number;
  output: string;
  error: string;
}

export function executeFFprobe(args: string[]): Promise<FFprobeResult>;
export function executeFFmpegCommandAPP(
  uuid: string, cmdLen: number, argv: string[]
): Promise<number>;
export function showLog(show: boolean): void;
