{pkgs, ...}: {
  home.packages = [
    pkgs.typst
  ];

  home.file.".local/share/typst/packages/local/personal/0.1.0".source = ./0.1.0;
}
