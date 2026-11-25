let
  flavors = import ../constants/flavors.nix;
in
# encodersgpl dropped with FFmpeg 8.0.3: its fftools-ffi (moffatman, FFmpeg 6
# fftools copy, no newer upstream) uses av_stream_new_side_data, removed in
# FFmpeg 8. SuperViewer ships video-full only.
[
  flavors.default
  flavors.full
]
