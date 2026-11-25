# libplacebo: required by mpv since 0.37 (mpv links it even when only the
# libmpv OpenGL render API is used). Built as a static library so it is
# linked into libmpv itself and the frameworks packaging needs no new dylib.
#
# GPU backends are all off: on Apple, mpv draws through its own OpenGL ES
# code (media_kit) or our sample-buffer video output, not libplacebo's
# Vulkan/OpenGL renderers. With OpenGL off, the glad loader isn't needed.
#
# The release tarball has no git submodules, so the two build-time pieces
# they provide come from nixpkgs instead:
#   - jinja2 + markupsafe (Python): libplacebo preprocesses its GLSL
#     templates with them at build time.
#   - fast_float (header-only): used by src/convert.cc; copied to the path
#     src/meson.build looks for (3rdparty/fast_float/include).
#   - Vulkan-Headers (header-only, Apache-2.0 / MIT): needed by the Vulkan
#     stubs even with Vulkan off; nothing from it is linked.
# None ends up in the shipped binary except fast_float's inlined code
# (MIT / Apache-2.0 / BSL-1.0, all fine next to LGPL).
{
  pkgs ? import ../../utils/default/pkgs.nix,
  os ? import ../../utils/default/os.nix,
  arch ? pkgs.callPackage ../../utils/default/arch.nix { },
}:

let
  name = "libplacebo";
  packageLock = (import ../../../packages.lock.nix).${name};
  inherit (packageLock) version;

  callPackage = pkgs.lib.callPackageWith { inherit pkgs os arch; };
  nativeFile = callPackage ../../utils/native-file/default.nix { };
  crossFile = callPackage ../../utils/cross-file/default.nix { };

  pname = import ../../utils/name/package.nix name;
  src = callPackage ../../utils/fetch-tarball/default.nix {
    name = "${pname}-source-${version}";
    inherit (packageLock) url sha256;
  };
  patchedSource = pkgs.runCommand "${pname}-patched-source-${version}" { } ''
    cp -r ${src} src
    chmod -R 777 src
    mkdir -p src/3rdparty/fast_float
    cp -r ${pkgs.fast-float}/include src/3rdparty/fast_float/include
    # Vulkan headers: src/vulkan/stubs.c (built even with -Dvulkan=disabled)
    # includes <libplacebo/vulkan.h>, which includes <vulkan/vulkan.h>.
    # src/vulkan/meson.build prefers 3rdparty/Vulkan-Headers/include.
    mkdir -p src/3rdparty/Vulkan-Headers
    cp -r ${pkgs.vulkan-headers}/include src/3rdparty/Vulkan-Headers/include
    cp -r src $out
  '';

  # Python with jinja2/markupsafe for the GLSL preprocessor. libplacebo's
  # meson.build runs it with import('python').find_installation(), which is
  # the Python meson itself runs on (nixpkgs' meson wrapper), not one from
  # nativeBuildInputs, so the modules are handed over via PYTHONPATH
  # (meson's python_env appends to the inherited PYTHONPATH).
  pythonEnv = pkgs.python3.withPackages (ps: [
    ps.jinja2
    ps.markupsafe
  ]);
in

pkgs.stdenvNoCC.mkDerivation {
  name = "${pname}-${os}-${arch}-${version}";
  pname = pname;
  inherit version;
  src = patchedSource;
  dontUnpack = true;
  enableParallelBuilding = true;
  nativeBuildInputs = [
    pkgs.meson
    pkgs.ninja
    pkgs.pkg-config
    pythonEnv
  ];
  configurePhase = ''
    meson setup build $src \
      --native-file ${nativeFile} \
      --cross-file ${crossFile} \
      --prefix=$out \
      -Ddefault_library=static \
      -Dvulkan=disabled \
      -Dvk-proc-addr=disabled \
      -Dopengl=disabled \
      -Dgl-proc-addr=disabled \
      -Dd3d11=disabled \
      -Dglslang=disabled \
      -Dshaderc=disabled \
      -Dlcms=disabled \
      -Dlibdovi=disabled \
      -Dunwind=disabled \
      -Dxxhash=disabled \
      -Ddemos=false \
      -Dtests=false \
      -Dbench=false \
      -Dfuzz=false
  '';
  buildPhase = ''
    export PYTHONPATH=${pythonEnv}/${pkgs.python3.sitePackages}
    meson compile -vC build
  '';
  installPhase = ''
    meson install -C build
  '';
}
