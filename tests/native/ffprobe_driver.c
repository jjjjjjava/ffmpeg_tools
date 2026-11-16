/* Runs multiple real FFTools commands in one process to test state cleanup. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "libavutil/mem.h"
#include "ffprobe_embedded.h"
#include "ffmpeg_callbacks.h"

int exe_ffmpeg_cmd(int argc, char **argv, Callbacks *callbacks);

static void save_result(const char *directory, int index, const char *suffix,
                        const char *text)
{
    char path[4096];
    snprintf(path, sizeof(path), "%s/%d.%s", directory, index, suffix);
    FILE *file = fopen(path, "wb");
    if (!file) {
        perror(path);
        exit(2);
    }
    if (text) fwrite(text, 1, strlen(text), file);
    fclose(file);
}

int main(int argc, char **argv)
{
    int index = 0;
    for (int start = 2; start < argc; index++) {
        int end = start;
        while (end < argc && strcmp(argv[end], "--next")) end++;
        if (end < argc) argv[end] = NULL;
        char *output = NULL, *error = NULL;
        int code;
        if (!strcmp(argv[start], "ffmpeg"))
            code = exe_ffmpeg_cmd(end - start, argv + start, NULL);
        else
            code = exe_ffprobe_cmd(end - start, argv + start, &output, &error);
        save_result(argv[1], index, "out", output);
        save_result(argv[1], index, "err", error);
        char status[32];
        snprintf(status, sizeof(status), "%d", code);
        save_result(argv[1], index, "code", status);
        av_free(output);
        av_free(error);
        start = end + 1;
    }
    return 0;
}
