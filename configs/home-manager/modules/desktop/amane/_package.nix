{
  amaneSource,
  lib,
  rustPlatform,
  pkg-config,
  expat,
  fontconfig,
  freetype,
  libpulseaudio,
  libxkbcommon,
  linux-pam,
  vulkan-loader,
  wayland,
}:
rustPlatform.buildRustPackage {
  pname = "amane-shell";
  version = "0.1.0";

  src = ./shell;
  cargoLock.lockFile = ./shell/Cargo.lock;

  # The shell builds against the pinned flake input, the same library the amane CLI ships.
  # The patch makes a dead Wayland connection exit instead of spinning, so systemd restarts it.
  postUnpack = ''
    cp -r ${amaneSource} "$sourceRoot/amane"
    chmod -R u+w "$sourceRoot/amane"
    patch -d "$sourceRoot/amane" -p1 < ${./amane-exit-on-protocol-error.patch}
  '';

  nativeBuildInputs = [pkg-config];

  # The libraries amane's own flake links.
  buildInputs = [
    expat
    fontconfig
    freetype
    libpulseaudio
    libxkbcommon
    linux-pam
    vulkan-loader
    wayland
  ];

  # 32 parallel release builds of vello and wgpu ran this 30 GB machine out of memory.
  preBuild = ''
    if [ "$NIX_BUILD_CORES" -gt 8 ]; then
      NIX_BUILD_CORES=8
    fi
  '';

  # wgpu and wayland-backend dlopen these.
  postFixup = ''
    patchelf --add-rpath ${lib.makeLibraryPath [vulkan-loader wayland]} $out/bin/amane-shell
  '';

  meta.mainProgram = "amane-shell";
}
