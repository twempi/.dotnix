# Repository Guidelines

## Project Identity

This repository is `dotnix`, Edward's personal NixOS/Home Manager flake.

The config is intended to be changed carefully, minimally, and in a way that fits the existing structure. Prefer small integrated edits over broad rewrites, reorganizations, or new abstractions.

## Project Structure

- `flake.nix` defines inputs, local packages/apps, NixOS hosts, and standalone Home Manager configurations.
- `flake.lock` may be updated when needed for dependency/input changes.
- `configs/system` contains shared NixOS base config, profiles, modules, and local package definitions.
- `configs/home-manager` contains shared Home Manager base config, profiles, modules, and desktop app/tool config.
- `configs/hosts/<host>` contains host-specific NixOS imports, hardware config, system modules, and Home Manager overrides.

Current NixOS hosts are `desktop`, `g14`, and `t480s`. Current Home Manager outputs are `edward-desktop`, `edward-g14`, and `edward-t480s`.

All current hosts are `x86_64-linux`.

## Host Roles

- `desktop` is the main/default machine. It has an AMD processor and an NVIDIA graphics card. If a task does not name a host, assume `desktop` and say so.
- `g14` is a Zephyrus G14 GA402RJ laptop used for school.
- `t480s` is a ThinkPad T480s used as a server.

`desktop`, `g14`, and `t480s` all have Hyprland, Sway, and MangoWC available. `desktop` primarily uses Hyprland through UWSM. `g14` primarily uses Sway. The `t480s` is primarily a server and runs server programs rather than being treated as a desktop-first machine.

Important server services on `t480s` include Caddy, SSH, Tailscale, and Syncthing. Treat changes to these services as potentially disruptive and keep them host-specific unless Edward explicitly asks for shared behavior.

This repository uses `sops-nix` for secrets.

## Common Commands

From the repository root:

- Evaluate the flake: `nix flake check`
- Build a NixOS host without switching: `nixos-rebuild build --flake .#desktop`
- Build a Home Manager output without switching: `home-manager build --flake .#edward-desktop`
- Build a local package: `nix build .#packages.x86_64-linux.<name>`

Use the matching host/output when the task targets another machine:

- `nixos-rebuild build --flake .#g14`
- `nixos-rebuild build --flake .#t480s`
- `home-manager build --flake .#edward-g14`
- `home-manager build --flake .#edward-t480s`

On configured machines, fish aliases are available:

- `nrs` runs `sudo nixos-rebuild switch --flake ~/.dotnix#<host>`
- `nrb` runs `sudo nixos-rebuild boot --flake ~/.dotnix#<host>`
- `hms` runs `home-manager switch --flake ~/.dotnix#edward-<host>`

Prefer safe validation commands before applying changes. Do not switch or boot into a new system generation unless Edward explicitly asks for that. A good default validation flow is:

1. Format changed Nix files with `alejandra` when available.
2. Run `nix flake check` when the change may affect flake evaluation.
3. Build the affected NixOS host with `nixos-rebuild build --flake .#<host>` when system config changed.
4. Build the affected Home Manager output with `home-manager build --flake .#edward-<host>` when user/home config changed.

If `alejandra`, `deadnix`, or `statix` are available in the repo or development environment, they may be used for formatting/linting. Do not introduce new formatter/linter dependencies just to complete a small config edit.

## Editing Conventions

Make the smallest change that fits the existing structure. If a module for a feature already exists, edit it. If a change is only for one machine, put it under that host. If a change should apply to multiple machines, ask Edward before moving it into a shared module or profile.

Prefer editing the existing module/profile that already owns a feature. Only create a new module when the change would otherwise make an existing file too large or mix unrelated concerns. Avoid broad reorganizations unless explicitly requested.

- Use `configs/hosts/<host>` for host-specific differences.
- Use shared modules/profiles only for behavior that should intentionally apply across multiple hosts.
- Add Home Manager modules under `configs/home-manager/modules/<category>/<name>/default.nix`, then import them from the relevant profile or `configs/home-manager/modules.nix`.
- Add NixOS modules under `configs/system/modules/<category>/<name>.nix`, then import them through a system profile, shared host config, or host-specific `system/modules.nix`.
- Keep host-specific overrides close to the host under `configs/hosts/<host>/home/modules` or `configs/hosts/<host>/system/modules`.
- Avoid huge files. Split or create modules only when it keeps the structure clearer and matches the existing style.
- Preserve the surrounding Nix style and naming conventions. Do not rewrite files just to match a personal preference.
- Prefer readable, boring Nix over clever abstractions.

## Cross-Host Changes

If a requested change appears to affect more than the named host, explain which hosts are affected and ask before applying it. Do not silently move host-specific behavior into shared modules.

Examples:

- A change under `configs/hosts/desktop` should only affect `desktop`.
- A change under `configs/system` may affect multiple NixOS hosts.
- A change under `configs/home-manager` may affect multiple Home Manager outputs.
- A change to shared Wayland, shell, editor, service, or package modules may affect `desktop`, `g14`, and/or `t480s` depending on imports.

When unsure, inspect imports first and then state the expected impact.

## Safety Notes

- This repository may contain uncommitted personal configuration changes. Do not revert or rewrite unrelated edits.
- Never edit any `hardware-configuration.nix` file unless Edward explicitly says otherwise.
- Never edit encrypted files managed by `sops-nix`.
- Do not print, expose, decrypt, move, rename, or reformat secrets.
- Treat files ignored for Caddy certificates/keys as secrets and do not add them to version control.
- Avoid destructive commands and cleanup operations unless they are directly requested.
- Before changing service definitions for Caddy, SSH, Tailscale, or Syncthing, consider whether the change could interrupt access to the `t480s` server.
