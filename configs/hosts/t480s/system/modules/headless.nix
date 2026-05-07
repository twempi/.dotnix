{pkgs, ...}: {
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
  };

  boot.kernelParams = ["consoleblank=60"];

  services.acpid = {
    enable = true;

    lidEventCommands = ''
      case "$1" in
        *close*)
          # Blank/power down Linux virtual consoles when lid closes
          for tty in /dev/tty{1..6}; do
            ${pkgs.util-linux}/bin/setterm --blank force --powersave powerdown < "$tty" > "$tty" 2>/dev/null || true
          done
          ;;

        *open*)
          # Wake the console display when lid opens
          for tty in /dev/tty{1..6}; do
            ${pkgs.util-linux}/bin/setterm --blank poke --powersave off < "$tty" > "$tty" 2>/dev/null || true
          done
          ;;
      esac
    '';
  };
}
