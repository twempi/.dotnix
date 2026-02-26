{ pkgs, ... }: {

	 security.rtkit.enable = true;
	 services.pipewire = {
		 enable = true;
		 pulse.enable = true;
		 alsa.enable = true;
		 alsa.support32Bit = true;
		 jack.enable = true;
		 wireplumber.enable = true;
	 };

	environment.systemPackages = with pkgs; [
	paprefs
	pasystray
	playerctl
	reaper
	];

	hardware.bluetooth = {
		enable = true;
		powerOnBoot = true;
		settings = {
			General = {
				Experimental = true;
			};
		};
	};
}
