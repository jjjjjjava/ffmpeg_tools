# FFmpeg 鸿蒙集成 - CMakeLists.txt

cmake_minimum_required(VERSION 3.5.0)
project(lib_ffmpeg_util)

set(CMAKE_CXX_STANDARD 17)

# ============================================
# 设置路径变量
# ============================================

# FFmpeg 预编译库路径
set(FFMPEG_DIR ${CMAKE_CURRENT_SOURCE_DIR}/ffmpeg/arm64-v8a)
set(FFMPEG_INCLUDE ${FFMPEG_DIR}/include)
set(FFMPEG_LIB ${FFMPEG_DIR}/lib)

# FFmpeg 源码文件路径
set(FFTOOLS_DIR ${CMAKE_CURRENT_SOURCE_DIR}/fftools)

# ============================================
# 添加 AKI 框架
# ============================================

# AKI 实际安装路径（解决 ohpm 符号链接问题）
set(AKI_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../../../../../oh_modules/.ohpm/@ohos+aki@1.2.24/oh_modules/@ohos/aki)

# 如果上述路径不存在，尝试使用模块本地路径
if(NOT EXISTS ${AKI_ROOT_PATH})
    set(AKI_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../../../oh_modules/@ohos/aki)
endif()

# 将 AKI 路径添加到 CMAKE_MODULE_PATH
set(CMAKE_MODULE_PATH ${AKI_ROOT_PATH})

# 查找 AKI 包
find_package(aki REQUIRED)

# ============================================
# 包含头文件目录
# ============================================

include_directories(
    ${FFMPEG_INCLUDE}           # FFmpeg 头文件
    ${FFTOOLS_DIR}              # FFmpeg 命令行工具源码
    ${CMAKE_CURRENT_SOURCE_DIR} # 当前目录
)

# ============================================
# 编译 Native 库
# ============================================

add_library(ffmpegutils SHARED
    # NAPI 绑定层
    napi_ffmpeg.cpp
    
    # FFmpeg 命令行工具完整源码
    ${FFTOOLS_DIR}/ffmpeg.c
    ${FFTOOLS_DIR}/cmdutils.c
    ${FFTOOLS_DIR}/exception.c
    ${FFTOOLS_DIR}/ffmpeg_opt.c
    ${FFTOOLS_DIR}/ffmpeg_filter.c
    ${FFTOOLS_DIR}/ffmpeg_hw.c
    ${FFTOOLS_DIR}/ffmpeg_demux.c
    ${FFTOOLS_DIR}/ffmpeg_mux.c
    ${FFTOOLS_DIR}/ffmpeg_mux_init.c
    ${FFTOOLS_DIR}/opt_common.c
    ${FFTOOLS_DIR}/sync_queue.c
    ${FFTOOLS_DIR}/objpool.c
    ${FFTOOLS_DIR}/thread_queue.c
    # 注意：不包含 ffplay.c 和 ffprobe.c（独立工具）
)

# ============================================
# 链接库
# ============================================

target_link_libraries(ffmpegutils PRIVATE
    # ----------------------------------------
    # FFmpeg 静态库（注意链接顺序很重要！）
    # ----------------------------------------
    ${FFMPEG_LIB}/libavdevice.a
    ${FFMPEG_LIB}/libavfilter.a
    ${FFMPEG_LIB}/libavformat.a
    ${FFMPEG_LIB}/libavcodec.a
    ${FFMPEG_LIB}/libswresample.a
    ${FFMPEG_LIB}/libswscale.a
    ${FFMPEG_LIB}/libavutil.a
    
    # ----------------------------------------
    # FFmpeg 依赖库（OpenSSL + librtmp）
    # ----------------------------------------
    ${FFMPEG_LIB}/librtmp.a     # RTMP 协议支持
    ${FFMPEG_LIB}/libssl.a      # SSL/TLS 支持
    ${FFMPEG_LIB}/libcrypto.a   # 加密库
    
    # ----------------------------------------
    # 鸿蒙系统库
    # ----------------------------------------
    libace_napi.z.so            # NAPI 接口
    libhilog_ndk.z.so           # 日志系统
    
    # ----------------------------------------
    # AKI 框架（跨语言绑定）
    # ----------------------------------------
    Aki::libjsbind
    
    # ----------------------------------------
    # 系统依赖库
    # ----------------------------------------
    -lpthread                   # 线程支持
    -lm                         # 数学库
    -lz                         # 压缩库
    -ldl                        # 动态链接库支持（OpenSSL需要）
)

# ============================================
# 编译选项
# ============================================

target_compile_features(ffmpegutils PRIVATE cxx_std_17)

# 添加编译选项
target_compile_options(ffmpegutils PRIVATE
    -Wall                       # 开启所有警告
    -Wno-deprecated-declarations # 忽略废弃声明警告
    -Wno-unused-variable        # 忽略未使用变量警告（FFmpeg 源码可能有）
    -Wno-unused-function        # 忽略未使用函数警告
)

# 添加宏定义（如果需要）
target_compile_definitions(ffmpegutils PRIVATE
    # __HARMONYOS__             # 标识鸿蒙平台（如果需要）
)
