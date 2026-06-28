{lib, pkgs, ...}: {
  home.packages = with pkgs; [
    prismlauncher
    (lib.meta.lowPrio jdk8)
    jdk21
    lunar-client
  ];
}
