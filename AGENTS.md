# Repository Guidelines

## Project Structure

This is Edward's personal NixOS/Home Manager flake.

- `flake.nix` defines inputs, local packages/apps, NixOS hosts, and standalone Home Manager configurations.
- `configs/system` contains shared NixOS base config, profiles, modules, and local package definitions.
- `configs/home-manager` contains shared Home Manager base config, profiles, modules, and desktop app/tool config.
- `configs/hosts/<host>` contains host-specific NixOS imports, hardware config, system modules, and Home Manager overrides.

Current NixOS hosts are `desktop`, `g14`, and `t480s`. Current Home Manager outputs are `edward-desktop`, `edward-g14`, and `edward-t480s`.

## Common Commands

From the repository root:

- Evaluate the flake: `nix flake check`
- Build a NixOS host without switching: `nixos-rebuild build --flake .#desktop`
- Build a Home Manager output without switching: `home-manager build --flake .#edward-desktop`
- Build a local package: `nix build .#packages.x86_64-linux.<name>`

On configured machines, fish aliases are available:

- `nrs` runs `sudo nixos-rebuild switch --flake ~/.dotnix#<host>`
- `nrb` runs `sudo nixos-rebuild boot --flake ~/.dotnix#<host>`
- `hms` runs `home-manager switch --flake ~/.dotnix#edward-<host>`

## Editing Conventions

- Prefer shared modules for behavior that should apply across hosts; use `configs/hosts/<host>` only for host-specific differences.
- Add Home Manager modules under `configs/home-manager/modules/<category>/<name>/default.nix`, then import them from the relevant profile or `configs/home-manager/modules.nix`.
- Add NixOS modules under `configs/system/modules/<category>/<name>.nix`, then import them through a system profile, shared host config, or host-specific `system/modules.nix`.
- Keep host-specific overrides close to the host under `configs/hosts/<host>/home/modules` or `configs/hosts/<host>/system/modules`.
- Format Nix files with `alejandra` when available, and otherwise preserve the surrounding style.

## Safety Notes

- This repository may contain uncommitted personal configuration changes. Do not revert or rewrite unrelated edits.
- Treat files ignored for Caddy certificates/keys as secrets and do not add them to version control.
