{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    prismlauncher
    jdk8
    jdk21
    lunar-client
  ];
}
