{pkgs, ...}: let
  t3codePackage = pkgs.t3code.override {
    enableCodex = true;
    enableGit = false;
    enableGitHub = false;
  };
in {
  environment.systemPackages = [
    t3codePackage
    (pkgs.writeShellScriptBin "t3code" ''
      exec ${t3codePackage}/bin/t3code-desktop "$@"
    '')
  ];
}
