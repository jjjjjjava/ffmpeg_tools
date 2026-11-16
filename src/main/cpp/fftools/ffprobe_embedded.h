#ifndef FFTOOLS_FFPROBE_EMBEDDED_H
#define FFTOOLS_FFPROBE_EMBEDDED_H

/* argc/argv include the program name. Caller serializes with FFmpeg.
 * output and error are UTF-8 strings owned by the caller; free with av_free().
 * The caller restores its log callback after this function returns. */
int exe_ffprobe_cmd(int argc, char **argv, char **output, char **error);

#endif
