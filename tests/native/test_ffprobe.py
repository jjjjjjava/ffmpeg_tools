#!/usr/bin/env python3
"""Behavior tests against real FFmpeg libraries, with multiple calls per process.

Usage: python3 tests/native/test_ffprobe.py --source <configured host FFmpeg 6.1.2>
The source directory must already contain built static libraries and ffmpeg/ffprobe.
Only the platform logger is stubbed; parsing, decoding and output use real code.
"""
import argparse
import json
from pathlib import Path
import shutil
import subprocess
import wave


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, required=True)
    args = parser.parse_args()
    source = args.source.resolve()
    root = Path(__file__).resolve().parents[2]
    work = root / '.test/ffprobe-host'
    embedded = work / 'embedded'
    embedded.mkdir(parents=True, exist_ok=True)
    for path in (root / 'src/main/cpp/fftools').iterdir():
        if path.suffix in ('.c', '.h'):
            shutil.copy(path, embedded / path.name)
    shutil.copy(source / 'config.h', embedded / 'config.h')
    (embedded / 'hilog').mkdir(exist_ok=True)
    (embedded / 'hilog/log.h').write_text(
        '#define LOG_APP 0\n#define LOG_INFO 0\n#define OH_LOG_Print(...) ((void)0)\n')

    names = ['ffmpeg', 'ffprobe', 'cmdutils', 'exception', 'ffmpeg_opt',
             'ffmpeg_filter', 'ffmpeg_hw', 'ffmpeg_demux', 'ffmpeg_mux',
             'ffmpeg_mux_init', 'opt_common', 'sync_queue', 'objpool', 'thread_queue']
    includes = ['-I' + str(embedded), '-I' + str(source)]
    with (work / 'embedded-build.log').open('w') as log:
        for name in names:
            command = ['cc', '-g', '-O1', '-Wno-deprecated-declarations',
                       '-Wno-pointer-sign', *includes, '-c',
                       str(embedded / (name + '.c')), '-o', str(embedded / (name + '.o'))]
            if name == 'ffmpeg':
                command.append('-Dmain=embedded_ffmpeg_main')
            subprocess.run(command, stdout=log, stderr=log, check=True)
        libs = ['avdevice', 'avfilter', 'avformat', 'avcodec', 'swresample', 'swscale', 'avutil']
        subprocess.run(['cc', '-g', *includes, str(root / 'tests/native/ffprobe_driver.c'),
                        *[str(embedded / (name + '.o')) for name in names],
                        *[str(source / f'lib{name}/lib{name}.a') for name in libs],
                        '-lm', '-lpthread', '-o', str(work / 'driver')],
                       stdout=log, stderr=log, check=True)

    audio = work / '音频 sample.wav'
    with wave.open(str(audio), 'wb') as file:
        file.setparams((1, 2, 16000, 0, 'NONE', 'not compressed'))
        file.writeframes(b'\0\0' * 16000)
    raw = work / 'frame.yuv'
    raw.write_bytes(bytes([100] * 256 + [128] * 128) * 3)
    video = work / '视频 sample.mp4'
    subprocess.run([str(source / 'ffmpeg'), '-v', 'error', '-y', '-f', 'rawvideo',
                    '-pixel_format', 'yuv420p', '-video_size', '16x16', '-framerate', '10',
                    '-i', str(raw), '-c:v', 'mpeg4', str(video)], check=True)
    converted = work / 'converted.wav'
    output_file = work / 'probe-output.json'
    common = ['ffprobe', '-v', 'error', '-of', 'json']
    full = common + ['-show_format', '-show_streams', str(audio)]
    cases = [
        ('audio', full),
        ('entries', common + ['-show_entries', 'format=duration', str(audio)]),
        ('invalid-option', ['ffprobe', '-invalid_option']),
        ('recover-option', full),
        ('missing-file', common + ['-show_error', str(work / 'missing.wav')]),
        ('invalid-writer', ['ffprobe', '-of', 'json:bad_option=1', str(audio)]),
        ('invalid-interval', common + ['-read_intervals', 'invalid', str(audio)]),
        ('recover-errors', full),
        ('select-none', common + ['-select_streams', 'v', '-show_streams', str(audio)]),
        ('selection-reset', full),
        ('count-frames', common + ['-count_frames', '-show_streams', str(audio)]),
        ('count-reset', full),
        ('video', common + ['-show_format', '-show_streams', str(video)]),
        ('version', ['ffprobe', '-version']),
        ('help', ['ffprobe', '-h']),
        ('file-output', full[:-1] + ['-o', str(output_file), str(audio)]),
        ('output-reset', full),
        ('transcode', ['ffmpeg', '-nostdin', '-v', 'error', '-y', '-i', str(audio),
                       '-c:a', 'pcm_s16le', str(converted)]),
        ('probe-transcoded', common + ['-show_streams', str(converted)]),
        ('transcode-again', ['ffmpeg', '-nostdin', '-v', 'error', '-y', '-i', str(audio),
                             '-c:a', 'pcm_s16le', str(converted)]),
        ('last-probe', full),
    ]
    results = work / 'results'
    results.mkdir(exist_ok=True)
    # Clear only prior result records so a crashing run cannot reuse stale evidence.
    for path in results.iterdir():
        if path.suffix in ('.out', '.err', '.code'):
            path.unlink()
    command = [str(work / 'driver'), str(results)]
    for index, (_, arguments) in enumerate(cases):
        if index:
            command.append('--next')
        command.extend(arguments)
    subprocess.run(command, capture_output=True, text=True, check=True, timeout=60)
    outputs = {}
    errors = {'invalid-option', 'missing-file', 'invalid-writer', 'invalid-interval'}
    for index, (name, _) in enumerate(cases):
        code = int((results / f'{index}.code').read_text())
        error = (results / f'{index}.err').read_text()
        outputs[name] = (results / f'{index}.out').read_text()
        assert (code != 0) == (name in errors), (name, code, error)
        assert bool(error) == (name in errors), (name, error)

    original = json.loads(outputs['audio'])
    reference = json.loads(subprocess.check_output(
        [str(source / 'ffprobe'), *full[1:]], text=True))
    assert original == reference
    for name in ('recover-option', 'recover-errors', 'selection-reset', 'count-reset',
                 'output-reset', 'last-probe'):
        assert json.loads(outputs[name]) == original, name
    assert json.loads(outputs['entries']) == {'format': {'duration': '1.000000'}}
    assert json.loads(outputs['select-none'])['streams'] == []
    assert int(json.loads(outputs['count-frames'])['streams'][0]['nb_read_frames']) > 0
    assert json.loads(outputs['missing-file'])['error']['code'] < 0
    video_info = json.loads(outputs['video'])
    video_ref = json.loads(subprocess.check_output(
        [str(source / 'ffprobe'), '-v', 'error', '-show_format', '-show_streams',
         '-of', 'json', str(video)], text=True))
    assert video_info == video_ref
    assert video_info['streams'][0]['width'] == 16
    assert outputs['version'].startswith('ffprobe version ')
    assert '-show_streams' in outputs['help']
    assert outputs['file-output'] == ''
    assert json.loads(output_file.read_text()) == original
    stream = json.loads(outputs['probe-transcoded'])['streams'][0]
    assert stream['sample_rate'] == '16000' and stream['channels'] == 1
    print(f'PASS: {len(cases)} sequential commands; JSON matches reference ffprobe for audio/video.')


if __name__ == '__main__':
    main()
