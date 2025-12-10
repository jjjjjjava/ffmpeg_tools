/**
 * FFmpeg 鸿蒙 NAPI 绑定层
 * 实现 C++ 与 ArkTS 之间的交互，通过 aki::JSBind 框架
 * 
 * 注意：FFmpeg 内部使用大量全局变量，不支持多线程并发执行
 * 任务调度层应确保串行执行
 */

#include <aki/jsbind.h>
#include <string>
#include <vector>
#include <cstring>

#include "hilog/log.h"

// 引入 FFmpeg 相关头文件（C 语言）
// 注意：不引入 fftools/ffmpeg.h 避免 C++ 关键字 'class' 冲突
extern "C" {
#include "fftools/ffmpeg_callbacks.h"
#include "libavutil/error.h"
#include "libavformat/avformat.h"
#include "libavutil/log.h"

// 前向声明 FFmpeg 命令执行函数
int exe_ffmpeg_cmd(int argc, char **argv, Callbacks *callbacks);
}

#undef LOG_DOMAIN
#undef LOG_TAG
#define LOG_DOMAIN 0x3200
#define LOG_TAG "FFmpegNAPI"

// ============================================
// CallBackInfo - 存储 ArkTS 回调函数指针
// ============================================

struct CallBackInfo {
    // 用于处理 FFmpeg 命令执行进度的回调函数
    const aki::JSFunction *onFFmpegProgress;
    
    // 用于处理 FFmpeg 命令执行失败的回调函数
    const aki::JSFunction *onFFmpegFail;
    
    // 用于处理 FFmpeg 命令执行成功的回调函数
    const aki::JSFunction *onFFmpegSuccess;
};

// 当前正在执行的回调信息（线程局部存储，支持多线程）
static thread_local CallBackInfo* g_currentCallback = nullptr;

// ============================================
// 辅助函数：vector<string> 转 char**
// ============================================

char** vector_to_argv(const std::vector<std::string>& argv) {
    char** result = (char**)malloc(sizeof(char*) * argv.size());
    if (!result) {
        OH_LOG_ERROR(LOG_APP, "malloc failed for argv");
        return nullptr;
    }
    
    for (size_t i = 0; i < argv.size(); ++i) {
        result[i] = strdup(argv[i].c_str());
        if (!result[i]) {
            // 清理已分配的内存
            for (size_t j = 0; j < i; ++j) {
                free(result[j]);
            }
            free(result);
            OH_LOG_ERROR(LOG_APP, "strdup failed for argv[%zu]", i);
            return nullptr;
        }
    }
    
    return result;
}

// ============================================
// C 回调桥接函数 - 从 C 调用到 C++ 再到 ArkTS
// ============================================

/**
 * 进度回调桥接函数
 * 由 FFmpeg C 代码调用，然后转发到 ArkTS
 */
void onFFmpegProgress(int progress) {
    if (g_currentCallback && g_currentCallback->onFFmpegProgress) {
        try {
            g_currentCallback->onFFmpegProgress->Invoke<void>(progress);
            OH_LOG_INFO(LOG_APP, "Progress callback invoked: %d%%", progress);
        } catch (const std::exception& e) {
            OH_LOG_ERROR(LOG_APP, "Error invoking progress callback: %{public}s", e.what());
        }
    }
}

/**
 * 失败回调桥接函数
 */
void onFFmpegFail(int code, const char* message) {
    if (g_currentCallback && g_currentCallback->onFFmpegFail) {
        try {
            std::string msg = message ? message : "Unknown error";
            g_currentCallback->onFFmpegFail->Invoke<void>(code, msg);
            OH_LOG_ERROR(LOG_APP, "Fail callback invoked: code=%d, msg=%{public}s", code, msg.c_str());
        } catch (const std::exception& e) {
            OH_LOG_ERROR(LOG_APP, "Error invoking fail callback: %{public}s", e.what());
        }
    }
}

/**
 * 成功回调桥接函数
 */
void onFFmpegSuccess(void) {
    if (g_currentCallback && g_currentCallback->onFFmpegSuccess) {
        try {
            g_currentCallback->onFFmpegSuccess->Invoke<void>();
            OH_LOG_INFO(LOG_APP, "Success callback invoked");
        } catch (const std::exception& e) {
            OH_LOG_ERROR(LOG_APP, "Error invoking success callback: %{public}s", e.what());
        }
    }
}

// ============================================
// 主执行函数 - 对 ArkTS 暴露
// ============================================

/**
 * 执行 FFmpeg 命令
 * 
 * @param uuid 唯一标识符，用于绑定回调函数
 * @param cmdLen 命令参数个数
 * @param argv 命令参数数组
 * @return 执行结果码，0表示成功
 */
int executeFFmpegCommandAPP(std::string uuid, int cmdLen, std::vector<std::string> argv) {
    OH_LOG_INFO(LOG_APP, "executeFFmpegCommandAPP called with UUID: %{public}s, cmdLen: %d", 
                uuid.c_str(), cmdLen);
    
    // 打印命令行
    std::string cmdStr;
    for (const auto& arg : argv) {
        cmdStr += arg + " ";
    }
    OH_LOG_INFO(LOG_APP, "FFmpeg command: %{public}s", cmdStr.c_str());
    
    // 1. 转换参数格式
    char **argv1 = vector_to_argv(argv);
    if (!argv1) {
        OH_LOG_ERROR(LOG_APP, "Failed to convert argv");
        return -1;
    }
    
    // 2. 创建局部回调信息并获取 ArkTS 回调函数
    CallBackInfo onActionListener;
    onActionListener.onFFmpegProgress = aki::JSBind::GetJSFunction(uuid + "_onFFmpegProgress");
    onActionListener.onFFmpegFail = aki::JSBind::GetJSFunction(uuid + "_onFFmpegFail");
    onActionListener.onFFmpegSuccess = aki::JSBind::GetJSFunction(uuid + "_onFFmpegSuccess");
    
    // 3. 设置当前线程的回调指针
    g_currentCallback = &onActionListener;
    
    // 4. 构建 C 回调结构体
    Callbacks callbacks = {
        .onFFmpegProgress = onFFmpegProgress,
        .onFFmpegFail = onFFmpegFail,
        .onFFmpegSuccess = onFFmpegSuccess
    };
    
    // 5. 执行 FFmpeg 命令
    OH_LOG_INFO(LOG_APP, "Starting FFmpeg execution...");
    int ret = exe_ffmpeg_cmd(cmdLen, argv1, &callbacks);
    OH_LOG_INFO(LOG_APP, "FFmpeg execution completed with code: %d", ret);
    
    // 6. 根据结果调用回调
    if (ret != 0) {
        // 失败
        char err[1024] = {0};
        av_strerror(ret, err, sizeof(err));
        onActionListener.onFFmpegFail->Invoke<void>(ret, err);
    } else {
        // 成功
        onActionListener.onFFmpegSuccess->Invoke<void>();
    }
    
    // 7. 清理内存
    for (int i = 0; i < cmdLen; ++i) {
        free(argv1[i]);
    }
    free(argv1);
    
    // 8. 清空当前回调指针
    g_currentCallback = nullptr;
    
    return ret;
}

// ============================================
// 日志控制函数（可选）
// ============================================

/**
 * FFmpeg 日志回调函数
 */
void log_call_back(void *ptr, int level, const char *fmt, va_list vl) {
    static int print_prefix = 1;
    static char prev[1024];
    char line[1024];
    
    av_log_format_line(ptr, level, fmt, vl, line, sizeof(line), &print_prefix);
    strcpy(prev, line);
    OH_LOG_ERROR(LOG_APP, "========> %{public}s", line);
}

/**
 * 控制是否显示 FFmpeg 日志
 * 
 * @param show true 显示日志，false 不显示
 */
void showLog(bool show) {
    if (show) {
        av_log_set_callback(log_call_back);
    }
}

// ============================================
// JSBind 模块注册
// ============================================

/**
 * 注册 FFmpeg 工具模块
 */
JSBIND_ADDON(ffmpegutils)

/**
 * 注册全局函数到 ArkTS
 */
JSBIND_GLOBAL() {
    JSBIND_PFUNCTION(executeFFmpegCommandAPP);  // 异步函数
    JSBIND_FUNCTION(showLog);                   // 同步函数
}
