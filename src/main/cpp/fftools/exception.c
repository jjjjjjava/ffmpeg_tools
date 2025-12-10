#include <stdio.h>
#include <setjmp.h>

/** 线程局部存储的跳转缓冲区 */
__thread jmp_buf ex_buf__;
