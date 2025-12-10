#ifndef EXCEPTION_H
#define EXCEPTION_H

#include <setjmp.h>

/** 线程局部存储的跳转缓冲区，避免多线程冲突 */
extern __thread jmp_buf ex_buf__;

#endif // EXCEPTION_H
