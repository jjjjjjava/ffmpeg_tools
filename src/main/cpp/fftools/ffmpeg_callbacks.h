#ifndef FFMPEG_CALLBACKS_H
#define FFMPEG_CALLBACKS_H

#ifdef __cplusplus
extern "C" {
#endif

/**
 * FFmpeg 进度回调函数类型
 * @param progress 进度百分比 (0-100)
 */
typedef void (*OnFFmpegProgressCallback)(int progress);

/**
 * FFmpeg 失败回调函数类型
 * @param code 错误码
 * @param message 错误消息
 */
typedef void (*OnFFmpegFailCallback)(int code, const char* message);

/**
 * FFmpeg 成功回调函数类型
 */
typedef void (*OnFFmpegSuccessCallback)(void);

/**
 * 回调函数结构体
 * 用于在 FFmpeg 执行过程中向上层报告状态
 */
typedef struct Callbacks {
    OnFFmpegProgressCallback onFFmpegProgress;  // 进度回调
    OnFFmpegFailCallback onFFmpegFail;          // 失败回调
    OnFFmpegSuccessCallback onFFmpegSuccess;    // 成功回调
} Callbacks;

#ifdef __cplusplus
}
#endif

#endif // FFMPEG_CALLBACKS_H
