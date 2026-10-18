# Repository Guidelines

## Core Operating Rules

This repository is Edward's personal NixOS and Home Manager configuration. Changes can affect operating systems, graphical sessions, hardware behavior, remote access, and server availability.

Always follow these rules:

1. Diagnose before editing.
   - Make the smallest change that addresses a confirmed problem.
2. Fix bugs before performing cleanup or streamlining.
3. Validate each logical change before continuing.
4. Preserve existing repository structure and feature ownership.
5. Do not overwrite or revert unrelated user changes.
6. Do not activate a new system or Home Manager generation unless Edward explicitly asks.
7. Do not claim that a runtime problem is fixed unless the available evidence supports that conclusion.
8. Prefer readable, direct, and boring Nix over clever abstractions.

For debugging, repair, cleanup, or streamlining tasks, follow `docs/repair-workflow.md`.

## Project Identity

This repository is `dotnix`, Edward's personal NixOS/Home Manager flake.

Change the configuration carefully, minimally, and in a way that fits the existing structure. Prefer small integrated edits over broad rewrites, reorganizations, or new abstractions.

## Project Structure

- `flake.nix` defines inputs, NixOS hosts, and standalone Home Manager configurations.
- `flake.lock` records pinned flake inputs and may be updated only when an input change is required.
- `configs/system` contains shared NixOS base configuration, profiles, and modules.
- `configs/home-manager` contains shared Home Manager base configuration, profiles, modules, and desktop application/tool configuration.
- `configs/hosts/<host>` contains host-specific NixOS imports, hardware configuration, system modules, and Home Manager overrides.

Current NixOS hosts are `desktop`, `g14`, and `t480s`. Current Home Manager outputs are `edward-desktop`, `edward-g14`, and `edward-t480s`. All hosts are `x86_64-linux`.

## Host Roles

### `desktop`

`desktop` is the main and default machine.

It has:

- An AMD processor
- An NVIDIA graphics card
- Hyprland, Sway, and Niri available
- Hyprland through UWSM as its primary desktop session

If a task does not name a host, assume `desktop` and state that assumption.

### `g14`

`g14` is a Zephyrus G14 GA402RJ laptop used for school.

It has:

- Hyprland, Sway, and Niri available
- Sway as its primary desktop session

Treat laptop power management, graphics switching, display behavior, suspend, battery, and hardware controls as host-specific unless the existing imports clearly establish shared behavior.

### `t480s`

`t480s` is a ThinkPad T480s used primarily as a server.

Important services include:

- Caddy
- SSH
- Tailscale
- Syncthing (Home Manager, enabled by the `server` profile)

Treat changes to these services as potentially disruptive. Keep them host-specific unless Edward explicitly requests shared behavior.

Current state: SSH and Tailscale are also enabled on `desktop` and `g14` through `configs/system/modules/services/homelab.nix`, which the shared desktop profile imports. `t480s` has its own copy in `configs/system/modules/networking/remote-access.nix`. A change to `homelab.nix` affects `desktop` and `g14`, not `t480s`.

Do not treat `t480s` as a desktop-first machine merely because desktop environments or window managers are available in its imports.

## Secrets

This repository uses `sops-nix` for secrets.

Never:

- Edit encrypted secret files unless Edward explicitly requests a specific safe change.
- Decrypt secrets.
- Print secret contents.
- Expose secret values in logs or reports.
- Move, rename, or reformat secret files.
- Add decrypted files to Git.
- Read or expose private keys, tokens, passwords, certificates, or credentials.
- Add ignored Caddy certificate or key files to version control.

When examining logs, commands, environment variables, or generated files, redact sensitive values.

## Protected and High-Risk Files

Never edit any `hardware-configuration.nix` file unless Edward explicitly requests it.

Do not modify the following without a confirmed need and a clear understanding of the impact:

- Bootloader configuration
- Disk, filesystem, or mount configuration
- Encryption configuration
- Kernel parameters
- GPU and display configuration
- Network interfaces or firewall rules
- SSH access
- Caddy routes or certificates
- Tailscale connectivity
- Syncthing identity or shared-folder definitions
- Secret declarations
- User accounts, authentication, or permissions

Do not perform destructive disk, filesystem, Git, package-store, or generation-cleanup operations unless directly requested.

## Common Commands

Run commands from the repository root unless a command specifically requires another directory.

Evaluate the flake:

```
nix flake check
nix flake check --no-build
```

Evaluate a NixOS host toplevel:

```
nix eval .#nixosConfigurations.desktop.config.system.build.toplevel.drvPath
```

Build a NixOS host without activating it:

```
nixos-rebuild build --flake .#desktop
nixos-rebuild build --flake .#g14
nixos-rebuild build --flake .#t480s
```

Build a Home Manager output without activating it:

```
home-manager build --flake .#edward-desktop
home-manager build --flake .#edward-g14
home-manager build --flake .#edward-t480s
```

Local packages are not exposed as flake outputs. To build one, build the NixOS host or Home Manager output that consumes it.

Inspect failed services:

```
systemctl --failed --no-pager
systemctl --user --failed --no-pager
```

Use targeted `systemctl status`, `journalctl`, or `journalctl --user` commands for the affected service. Prefer current-boot and narrowly scoped logs over dumping an entire journal.

Configured fish aliases, on configured machines:

- `nrs` runs `sudo nixos-rebuild switch --flake ~/.dotnix#<host>`
- `nrb` runs `sudo nixos-rebuild boot --flake ~/.dotnix#<host>`
- `hms` runs `home-manager switch --flake ~/.dotnix#edward-<host>`. On `desktop` and `g14` it also runs `theme-switch --restore`.

Do not run these activation aliases unless Edward explicitly requests activation.

## Prohibited Activation Commands

Do not run any of the following unless Edward explicitly requests the corresponding operation:

```
nixos-rebuild switch
nixos-rebuild test
nixos-rebuild boot
home-manager switch
systemctl restart
systemctl stop
systemctl disable
reboot
shutdown
```

Building is allowed by default. Activating is not.

Do not reboot, log Edward out, restart the graphical session, or replace the currently running generation without explicit permission.

## Working Tree Safety

This repository may contain uncommitted personal configuration changes.

Before editing, inspect:

```
git status --short
git diff --stat
git diff
```

When appropriate, also inspect staged changes with `git diff --cached`.

Never run the following unless Edward explicitly requests the exact operation:

```
git add
git commit
git stash
git reset
git restore
git checkout
git clean
git revert
```

Do not:

- Revert unrelated edits.
- Rewrite files wholesale when a targeted edit is sufficient.
- Assume an existing diff is intentional or belongs to Edward. Ask if unsure.
- Stage files merely to make a flake evaluation succeed.
- Commit changes automatically.
- Alter Git history.

Distinguish pre-existing user changes from changes made during the current task.

### Git-backed flake visibility

When a flake is inside a Git repository, untracked files may not be included in the flake source copied into the Nix store.

If a newly created file is referenced by the configuration but Nix reports that it does not exist:

1. Check whether the file is untracked.
2. Report that the Git-backed flake cannot currently see it.
3. Do not stage it automatically.
4. Ask Edward to stage it only when staging is necessary and appropriate.
5. Do not stage unrelated files.

## Editing Conventions

Make the smallest change that fits the existing structure.

If a module for a feature already exists, edit it. If a change is only for one machine, place it under that host. If a change should intentionally apply to multiple machines, determine which hosts import the affected file and explain the impact before editing.

Do not place a host-specific workaround in a shared module merely because the shared module is easy to find. Do not create a second module for a feature that already has a clear owner.

- Host-specific overrides go under `configs/hosts/<host>/home/modules` and `configs/hosts/<host>/system/modules`.
- Home Manager modules go under `configs/home-manager/modules/<category>/<name>/default.nix`, or as a single file where neighboring modules do that. Import them from the relevant profile or `configs/home-manager/modules.nix`.
- NixOS modules go under `configs/system/modules/<category>/<name>.nix`. Import them through a system profile, shared host configuration, or a host-specific `system/modules.nix`.
- Create a new module only when the existing structure does not already provide a clear owner.
- Local packages are not exposed as flake outputs. They live beside the module that uses them, for example `configs/hosts/g14/home/modules/refresh-rate/package.nix`.

Style:

- Preserve surrounding Nix style and naming conventions.
- Do not rewrite files solely to match a personal preference.
- Avoid huge files, but do not split a file without a concrete clarity benefit.
- Prefer explicit names and avoid premature abstractions.
- Keep comments focused on why a non-obvious decision exists. Do not add comments that merely restate the code.
- Preserve intentional option ordering where it improves readability.
- Avoid unrelated whitespace churn.

## Cross-Host Changes

A file under `configs/hosts/<host>` should affect only that host.

A change under `configs/system` may affect multiple NixOS hosts. A change under `configs/home-manager` may affect multiple Home Manager outputs. Shared Wayland, shell, editor, service, package, or profile modules may affect `desktop`, `g14`, and `t480s`, depending on their imports.

Before changing a shared file:

1. Inspect all import paths that reference it.
2. Determine which NixOS hosts and Home Manager outputs are affected.
3. Prefer a host-specific override when the requested behavior is host-specific.
4. Report the expected cross-host impact.

Do not silently move host-specific behavior into a shared module. Do not broaden the scope of a task merely to make configurations look uniform.

## Formatting and Static Analysis

Use the repository's existing formatter when available. The flake defines no `formatter` output. `alejandra`, `statix`, and `deadnix` are installed through the Neovim module (`configs/home-manager/modules/editors/neovim/default.nix`).

Prefer `alejandra` for changed Nix files. Format only files changed during the task unless a broader formatting operation was explicitly requested.

`statix` and `deadnix` are advisory. Use their read-only or check modes first. Do not run `statix fix` or `deadnix --edit` unless Edward explicitly requests automatic fixes and every resulting change will be reviewed.

Static-analysis findings are not proof that code is safe to remove. A value may be referenced through an import or module system, function arguments may be supplied through `callPackage`, and a stylistic warning does not justify an unrelated refactor. Do not add formatter or linter dependencies solely to complete a small repair.

## Validation Workflow

Use the narrowest relevant validation first, followed by broader validation after the logical change is stable.

- Nix syntax or expression change: format the changed file, then run a targeted evaluation. Run `nix flake check` when the change can affect flake evaluation.
- NixOS system change: `nixos-rebuild build --flake .#<host>`.
- Home Manager change: `home-manager build --flake .#edward-<host>`.
- Local package change: there are no flake package outputs to build. Build each NixOS host or Home Manager output that consumes the package.
- Flake or input change: `nix flake check`, then build every directly affected output.

Before completion:

1. Run `git diff --check`.
2. Review the complete diff and verify that only intended files changed.
3. Verify that no secrets were introduced and no hardware configuration changed.
4. Verify the affected hosts and outputs.
5. Report every validation command and its result.

## Validation Boundaries

A successful evaluation proves that Nix can evaluate the relevant expression. A successful build proves that Nix can build the relevant output.

Neither result necessarily proves that a graphical session starts, a service behaves correctly after activation, suspend or resume works, GPU switching works, hardware controls work, a network route is reachable, a remote server remains accessible, an interactive application behaves correctly, or a problem requiring reboot has been resolved.

When activation is required for final verification, report:

```
Build validated; activation verification required.
```

Do not claim the runtime issue is fully fixed unless it was safely and directly verified.

## Flake Input and Lock-File Policy

Do not update `flake.lock` merely to see whether newer inputs solve a problem.

Update an input only when the root cause is confirmed to be in the pinned dependency, the requested feature requires a newer dependency, a current option or package is unavailable in the pinned revision, or Edward explicitly asks for an update.

When updating inputs, update only the required input when possible, inspect the lock-file diff, avoid unrelated churn, review transitive changes, run the full applicable validation, and explain why the update was necessary.

Do not replace a reproducible diagnosis with a blanket `nix flake update`.

## Service Safety

Inspecting service status and logs is allowed. Changing service state is not allowed by default.

Do not stop, restart, reload, enable, disable, or mask a system or user service unless Edward explicitly requests it. Be especially careful with `sshd`, Caddy, Tailscale, Syncthing, display managers, UWSM, graphical-session targets, network services, filesystem and storage services, and remote-access services.

A build-time validation is preferable to service disruption. Changes involving remote access on `t480s` require special caution because a mistake could make the server unreachable.

## Destructive Operation Policy

Do not run garbage collection, generation deletion, store optimization or repair, filesystem cleanup, cache deletion, broad package removal, disk formatting, partitioning commands, recursive deletion, Git cleanup, secret rotation, or certificate replacement unless Edward explicitly requests the exact operation and its consequences are understood.

Do not use destructive cleanup as a general response to a failed build or low disk space.

## Research and Upstream Claims

When a problem depends on a changed option, a recent package change, an upstream regression, version-specific behavior, or an unfamiliar error, verify it against primary sources before implementing a workaround. Prefer official Nix, NixOS, nixpkgs, and Home Manager documentation, then nixpkgs source, then upstream documentation and issues.

Do not copy configuration from community dotfiles or blog posts without verifying the NixOS or Home Manager version, the package version, the option definitions, the host's hardware and role, and the repository's existing structure. The full research policy is in `docs/repair-workflow.md`.

## Completion Report

Every repair or streamlining task ends with the structured report described in `docs/repair-workflow.md`. Do not claim that all problems are fixed when evidence is incomplete.

## Default Decision Rules

When uncertain:

- Choose `desktop` as the target host if no host was named.
- Inspect imports before deciding whether a change is shared.
- Keep behavior host-specific unless sharing is clearly intentional.
- Prefer an existing module over creating a new one.
- Prefer a small repair over a rewrite.
- Prefer a targeted build over activation.
- Prefer primary documentation over community snippets.
- Prefer reporting uncertainty over guessing.
- Prefer leaving working code alone over speculative cleanup.
