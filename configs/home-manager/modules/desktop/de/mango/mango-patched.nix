{
  inputs,
  pkgs,
  system ? pkgs.stdenv.hostPlatform.system,
}:
inputs.mangowm.packages.${system}.mango.overrideAttrs (old: {
  patches = (old.patches or []) ++ [
    ./patches/mango-ten-tags-forcekill.patch
  ];
})
