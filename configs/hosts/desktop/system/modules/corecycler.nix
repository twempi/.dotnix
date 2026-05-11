{inputs, ...}: {
  imports = [inputs.corecycler.nixosModules.default];

  services.corecycler = {
    enable = true;
    deviceAccessUser = "edward";

    # Keep this true if you want to read/write CO values from Linux.
    # For stress testing only, it is not required.
    ryzenSmu = true;

    # Optional, but useful if you want Prime95/mprime backend.
    # Default false gives you FOSS-only stress-ng + stressapptest.
    unfreeBackends = true;

    # Leave these off unless you specifically need better motherboard/voltage sensors.
    zenpower = false;
    nct6775 = false;
    it87 = false;
    spd5118 = false;
    cpuid = false;
  };
}
