{inputs, ...}: {
  imports = [inputs.corecycler.nixosModules.default];

  services.corecycler = {
    enable = true;

    deviceAccess = true;
    deviceAccessUser = "edward";

    ryzenSmu = true;
    unfreeBackends = true;

    zenpower = false;
    nct6775 = false;
    it87 = false;
    spd5118 = false;
    cpuid = false;
  };
}
