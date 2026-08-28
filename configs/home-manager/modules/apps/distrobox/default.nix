{...}: {
  programs.distrobox = {
    enable = true;
    settings.container_manager = "podman";

    containers = {
      matlab = {
        image = "ubuntu:24.04";
        pull = true;
        replace = false;
        additional_packages = [
          "ca-certificates"
          "curl"
          "unzip"
        ];
      };
    };
  };
}
