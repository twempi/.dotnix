{lib, pkgs, ...}: {
  programs.ssh.askPassword = lib.mkDefault "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";
  services.dbus.packages = [
    pkgs.seahorse
  ];
}
