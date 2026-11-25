# Patches

Applied in `nix/packages/mk-pkg-*/default.nix`. On an upgrade: change the pins
in `packages.lock.nix`, run `git apply --check` for each patch below against
the new source, and re-port only the ones that fail.

Pinned: mpv 0.41.0, FFmpeg 8.0.3, libplacebo 7.360.1.

## mpv

| Patch | Origin | Purpose | Drop when |
|---|---|---|---|
| `mpv-sv-pcm-tap.patch` | SuperViewer | Copies the final post-filter PCM (after HRIR) for the visualizer; new file `audio/out/sv_pcm_tap.c`, one hook in `ao_post_process_data()`. | Never (ours). |
| `mpv-audiounit-shared-session.patch` | Inherited (fork) | Reference-counts the iOS AVAudioSession so one player's uninit doesn't silence another; adds `--audiounit-skip-session-management`. | Upstream stops deactivating the session in `uninit`. |
| `mpv-sv-avsbuf.patch` | SuperViewer | `--vo=avsbuf`: AVSampleBufferDisplayLayer video output for iOS/tvOS (PiP, background, 10-bit/HDR). New file `video/out/vo_avsbuf.m`, one `vo.c` entry, one meson option and block. | Never (ours). |
| `mpv-fix-missing-objc.patch` | Inherited (fork) | Adds the objc language where `.m` sources are added; 0.41.0 only does it when it detects a macOS SDK. | Upstream adds objc for iOS cross builds. |

## FFmpeg

| Patch | Origin | Purpose | Drop when |
|---|---|---|---|
| `ffmpeg-fix-dash-base-url-escape.patch` | Inherited (fork) | Escapes BaseURL text before `xmlNodeSetContent()` so `&` in a query isn't cut off. | FFmpeg 9.x (fixed upstream). |

## Other

| Patch | Origin | Purpose | Drop when |
|---|---|---|---|
| `ltmain-target-passthrough.patch` | Inherited (fork) | libtool target flags pass-through (libass build). | Unchanged by this upgrade. |

## Removed with the mpv 0.41.0 / FFmpeg 8.0.3 move (Nov 2026)

- `ffmpeg-fix-hls-mp4-seek.patch`: fixed upstream (`hls_read_seek` resets `cur_init_section`).
- `ffmpeg-fix-vp9-hwaccel.patch`: upstream has VP9 VideoToolbox with `vp9_superframe_split`; the rest only worked around an Intel-Mac hang.
- `ffmpeg-fix-ios-hdr-texture.patch`: forced 10-bit video to 8-bit BGRA for OpenGL ES; dropped so 10-bit/HDR frames reach the AVSampleBufferDisplayLayer video output.
- `mpv-remove-libass.patch`: only for the audio-only variant, which is no longer built.
