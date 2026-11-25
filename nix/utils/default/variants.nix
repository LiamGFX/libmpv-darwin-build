let
  variants = import ../constants/variants.nix;
in
# Video only: the audio-only variant was dropped with mpv 0.41.0 (its
# mpv-remove-libass.patch no longer applies, and SuperViewer ships video).
[
  variants.video
]
