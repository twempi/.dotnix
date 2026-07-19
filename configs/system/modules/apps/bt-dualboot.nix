{
  pkgs,
  lib,
  ...
}: let
  bt-dualboot = pkgs.python3Packages.buildPythonApplication rec {
    pname = "bt-dualboot";
    version = "1.0.1";

    pyproject = true;

    src = pkgs.fetchPypi {
      inherit pname version;
      hash = "sha256-pjzGvLkotQllzyrnxqDIjGlpBOvUPkWpv0eooCUrgv8=";
    };

    build-system = [
      pkgs.python3Packages.poetry-core
    ];

    doCheck = false;

    makeWrapperArgs = [
      "--prefix"
      "PATH"
      ":"
      (lib.makeBinPath [pkgs.chntpw])
    ];

    meta = {
      description = "Synchronize Bluetooth pairing keys between Linux and Windows";
      homepage = "https://github.com/x2es/bt-dualboot";
      license = lib.licenses.mit;
      mainProgram = "bt-dualboot";
      platforms = lib.platforms.linux;
    };
  };
in {
  environment.systemPackages = [
    bt-dualboot
  ];
}
