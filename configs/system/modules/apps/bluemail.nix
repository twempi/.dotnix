{pkgs, ...}: {
  environment.systemPackages = with pkgs; [bluemail];
}
