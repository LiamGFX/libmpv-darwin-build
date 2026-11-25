{
  pkgs ? import ../../utils/default/pkgs.nix,
}:

let
  name = "all";
  version = import ../../utils/version/default.nix { inherit pkgs; };

  pname = import ../../utils/name/output.nix name;
  flavors = import ../../utils/default/flavors.nix;
  variants = import ../../utils/default/variants.nix;
  # macOS targets skipped for now: mpv 0.41.0 requires its Swift build
  # whenever Cocoa is on (player/clipboard/clipboard-mac.m and
  # osdep/mac/app_bridge.m include the generated osdep/mac/swift.h), and
  # SuperViewer stays on v0.0.1-sv4 for macOS until iOS works on sv5.
  # Remove the filter when macOS moves to this fork's newer releases.
  oses = import ../../utils/constants/oses.nix;
  targets = builtins.filter (target: target.os != oses.macos) (
    import ../mk-out-archive/targets.nix
  );
  archives = builtins.concatMap (
    target:
    builtins.concatMap (
      variant:
      builtins.map (
        flavor:
        let
          format = target.format;
          os = target.os;
          arch = target.arch;
        in
        import ../mk-out-archive/default.nix {
          inherit
            pkgs
            format
            os
            arch
            variant
            flavor
            ;
        }
      ) flavors
    ) variants
  ) targets;
in

pkgs.stdenvNoCC.mkDerivation {
  name = "${pname}";
  pname = pname;
  inherit version;
  dontUnpack = true;
  enableParallelBuilding = true;
  buildPhase = ''
    mkdir build

    ARCHIVES="${pkgs.lib.concatStringsSep " " archives}"
    for ARCHIVE in $ARCHIVES; do
      echo $ARCHIVE
      cp --no-preserve=mode \
        $ARCHIVE/*.tar.gz \
        $ARCHIVE/*.zip \
        build/
    done
  '';
  installPhase = ''
    cp -r build $out
  '';
}
