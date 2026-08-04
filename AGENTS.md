# **Repository Guidelines** 

## **Core Operating Rules** 

This repository is Edward's personal NixOS and Home Manager configuration. Changes can affect operating systems, graphical sessions, hardware behavior, remote access, and server availability. 

Always follow these rules: 

1. Diagnose before editing. 

- Make the smallest change that addresses a confirmed problem. 

2. 

- Fix bugs before performing cleanup or streamlining. 

3. 

- Validate each logical change before continuing. 

4. 

- Preserve existing repository structure and feature ownership. 

5. 

- Do not overwrite or revert unrelated user changes. 

6. 

- Do not activate a new system or Home Manager generation unless Edward explicitly asks. 

7. 

- Do not claim that a runtime problem is fixed unless the available evidence supports that conclusion. 

8. 

Prefer readable, direct, and boring Nix over clever abstractions. 

## **Project Identity** 

This repository is <mark>`dotnix` ,</mark> Edward's personal NixOS/Home Manager flake. 

The configuration is intended to be changed carefully, minimally, and in a way that fits the existing structure. Prefer small integrated edits over broad rewrites, reorganizations, or new abstractions. 

## **Project Structure** 

- <mark>`flake.nix`</mark> defines inputs, local packages/apps, NixOS hosts, and standalone Home Manager 

- configurations. 

- <mark>`flake.lock`</mark> records pinned flake inputs and may be updated only when an input change is 

- required. 

- <mark>`configs/system`</mark> contains shared NixOS base configuration, profiles, modules, and local package 

- definitions. 

- <mark>`configs/home-manager`</mark> contains shared Home Manager base configuration, profiles, modules, 

- and desktop application/tool configuration. 

- <mark>`configs/hosts/<host>`</mark> contains host-specific NixOS imports, hardware configuration, system 

- modules, and Home Manager overrides. 

Current NixOS hosts are: 

- <mark>`desktop`</mark> 

- <mark>`g14`</mark> 

1 

- <mark>`t480s`</mark> 

Current Home Manager outputs are: 

- <mark>`edward-desktop`</mark> 

- <mark>`edward-g14`</mark> 

- <mark>`edward-t480s`</mark> 

All current hosts are <mark>`x86_64-linux` .</mark> 

## **Host Roles** 

### **<mark>`desktop`</mark>** 

<mark>`desktop`</mark> is the main and default machine. 

It has: 

- An AMD processor • An NVIDIA graphics card • Hyprland, Sway, and MangoWC available • Hyprland through UWSM as its primary desktop session 

If a task does not name a host, assume `desktop` and state that assumption. 

### **<mark>`g14`</mark>** 

<mark>`g14`</mark> is a Zephyrus G14 GA402RJ laptop used for school. 

It has: 

- Hyprland, Sway, and MangoWC available • Sway as its primary desktop session 

Treat laptop power management, graphics switching, display behavior, suspend, battery, and hardware controls as host-specific unless the existing imports clearly establish shared behavior. 

### **<mark>`t480s`</mark>** 

<mark>`t480s`</mark> is a ThinkPad T480s used primarily as a server. 

Important services include: 

• Caddy • SSH • Tailscale • Syncthing 

2 

Treat changes to these services as potentially disruptive. Keep them host-specific unless Edward explicitly requests shared behavior. 

Do not treat <mark>`t480s`</mark> as a desktop-first machine merely because desktop environments or window managers are available in its imports. 

## **Secrets** 

This repository uses <mark>`sops-nix`</mark> for secrets. 

Never: 

- Edit encrypted secret files unless Edward explicitly requests a specific safe change. 

- Decrypt secrets. 

- Print secret contents. 

- Expose secret values in logs or reports. 

- Move, rename, or reformat secret files. 

- 

- Add decrypted files to Git. 

- 

- Read or expose private keys, tokens, passwords, certificates, or credentials. • Add ignored Caddy certificate or key files to version control. 

When examining logs, commands, environment variables, or generated files, redact sensitive values. 

## **Protected and High-Risk Files** 

Never edit any <mark>`hardware-configuration.nix`</mark> file unless Edward explicitly requests it. 

Do not modify the following without a confirmed need and a clear understanding of the impact: 

- Bootloader configuration 

- Disk, filesystem, or mount configuration 

- Encryption configuration 

- 

- Kernel parameters 

- GPU and display configuration 

- 

- Network interfaces or firewall rules 

- 

- SSH access 

- Caddy routes or certificates 

- 

- Tailscale connectivity 

- Syncthing identity or shared-folder definitions 

- 

- Secret declarations 

- User accounts, authentication, or permissions 

Do not perform destructive disk, filesystem, Git, package-store, or generation-cleanup operations unless directly requested. 

3 

## **Common Commands** 

Run commands from the repository root unless a command specifically requires another directory. 

### **Evaluate the flake** 

```
nixflakecheck
```

For an evaluation-focused initial check: 

```
nixflakecheck--no-build
```

### **Evaluate a NixOS host toplevel** 

```
nixeval.#nixosConfigurations.<host>.config.system.build.toplevel.drvPath
```

Example: 

```
nixeval.#nixosConfigurations.desktop.config.system.build.toplevel.drvPath
```

### **Build a NixOS host without activating it** 

```
nixos-rebuildbuild--flake.#desktop
nixos-rebuildbuild--flake.#g14
nixos-rebuildbuild--flake.#t480s
```

### **Build a Home Manager output without activating it** 

```
home-managerbuild--flake.#edward-desktop
home-managerbuild--flake.#edward-g14
home-managerbuild--flake.#edward-t480s
```

### **Build a local package** 

```
nixbuild.#packages.x86_64-linux.<name>
```

### **Inspect failed services** 

System services: 

4 

```
systemctl--failed--no-pager
```

User services: 

```
systemctl--user--failed--no-pager
```

Use targeted <mark>`systemctl status` ,</mark> <mark>`journalctl` ,</mark> or <mark>`journalctl --user`</mark> commands for the affected service. Prefer current-boot and narrowly scoped logs over dumping an entire journal. 

### **Configured aliases** 

On configured machines, fish aliases may be available: 

- <mark>`nrs`</mark> runs <mark>`sudo nixos-rebuild switch --flake ~/.dotnix#<host>`</mark> 

- <mark>`nrb`</mark> runs <mark>`sudo nixos-rebuild boot --flake ~/.dotnix#<host>`</mark> 

- <mark>`hms`</mark> runs <mark>`home-manager switch --flake ~/.dotnix#edward-<host>`</mark> 

Do not run these activation aliases unless Edward explicitly requests activation. 

## **Prohibited Activation Commands** 

Do not run any of the following unless Edward explicitly requests the corresponding operation: 

```
nixos-rebuildswitch
nixos-rebuildtest
nixos-rebuildboot
home-managerswitch
systemctlrestart
systemctlstop
systemctldisable
reboot
shutdown
```

Building is allowed by default. Activating is not. 

Do not reboot, log Edward out, restart the graphical session, or replace the currently running generation without explicit permission. 

## **Working Tree Safety** 

This repository may contain uncommitted personal configuration changes. 

Before editing, inspect: 

5 

```
gitstatus--short
gitdiff--stat
gitdiff
```

When appropriate, also inspect staged changes: 

```
gitdiff--cached
```

Never run the following unless Edward explicitly requests the exact operation: 

```
gitadd
gitcommit
gitstash
gitreset
gitrestore
gitcheckout
gitclean
gitrevert
```

Do not: 

- Revert unrelated edits. 

- Rewrite files wholesale when a targeted edit is sufficient. 

- Assume an existing diff was created by Codex. 

- Stage files merely to make a flake evaluation succeed. 

- Commit changes automatically. 

- alter Git history. 

Distinguish pre-existing user changes from changes made during the current task. 

### **Git-backed flake visibility** 

When a flake is inside a Git repository, untracked files may not be included in the flake source copied into the Nix store. 

If a newly created file is referenced by the configuration but Nix reports that it does not exist: 

1. Check whether the file is untracked. 

2. Report that the Git-backed flake cannot currently see it. 

3. Do not stage it automatically. 

4. Ask Edward to stage it only when staging is necessary and appropriate. 

5. Do not stage unrelated files. 

6 

## **Diagnostic and Repair Workflow** 

For debugging, repair, cleanup, or streamlining tasks, use the following phases. 

## **Phase 1: Establish a Baseline** 

Before editing: 

1. Confirm the repository root. 

2. Determine the target host. 

3. If no host was provided, use <mark>`desktop`</mark> and state that assumption. 

- Inspect the working tree and existing diff. 

4. 

5. Inspect the target host's import chain. 

- Identify which module currently owns the affected feature. 

6. 

7. Record the exact symptom, failing command, failed service, or relevant error. 

8. Run the least expensive check that can reproduce or narrow the problem. 

Do not begin by changing packages, updating inputs, or reorganizing modules. 

A reasonable initial sequence is: 

```
gitstatus--short
gitdiff--stat
nixflakecheck--no-build
```

Then use a targeted evaluation, build, service status, or journal query based on the symptom. 

## **Phase 2: Inspect Imports and Ownership** 

Before deciding where to edit: 

1. Inspect <mark>`flake.nix` .</mark> 

2. Trace the target NixOS host's imports. 

3. Trace the corresponding Home Manager output's imports. 

4. Determine whether the behavior is: 

5. Host-specific 

6. Shared by selected hosts 

7. Shared by all hosts 

8. Owned by Home Manager 

9. Owned by NixOS 

- Defined by a local package 

10. 

   - Defined upstream 

11. 

7 

12. State the expected impact before changing a shared file. 

Do not place a host-specific workaround in a shared module merely because the shared module is easy to find. 

Do not create a second module for a feature that already has a clear owner. 

## **Phase 3: Classify the Problem** 

Classify each reported problem before editing it. 

Use one of the following categories: 

- Nix syntax error 

- Flake evaluation error 

- NixOS module option error 

- Home Manager module option error 

- Build or package failure 

- System service failure 

- User service failure 

- Graphical-session failure 

- Hardware- or host-specific behavior 

- Upstream package regression 

- Application state outside the declarative configuration 

- Configuration duplication or conflict 

- Unconfirmed or non-reproducible symptom 

Do not make speculative changes for an unconfirmed problem. 

When a problem may be caused by an upstream option rename, package change, regression, or versionspecific behavior, verify it against current primary documentation, source code, release notes, or upstream issues before implementing a workaround. 

## **Phase 4: Repair Confirmed Problems** 

Fix one root cause or one closely related group at a time. 

For each repair: 

1. Identify the evidence supporting the root cause. 

2. Edit the existing module that owns the behavior. 

3. Make the smallest sufficient change. 

4. Format only the changed files. 

5. Run the narrowest relevant evaluation or build. 

6. Repair any newly introduced failure before moving on. 

7. Review the diff for accidental or unrelated edits. 

8 

Do not combine an unresolved bug fix with broad cleanup. 

Do not change several unrelated subsystems in one step merely because they all have warnings. 

Prefer correcting the source of a conflict over adding another override, force flag, compatibility layer, or duplicated option. 

## **Phase 5: Conservative Streamlining** 

Only begin streamlining after confirmed bugs have been repaired or clearly separated from the cleanup work. 

Streamlining means: 

- Removing confirmed duplicate imports. 

- Removing confirmed duplicate option assignments. 

- Removing obsolete configuration that is no longer referenced. 

- Consolidating exactly equivalent repeated configuration. 

- Moving a misplaced host-specific setting back to its host. 

- Keeping feature ownership in the existing appropriate module. 

- Removing unnecessary one-use indirection. 

- Simplifying expressions without changing their behavior. 

- Deleting stale comments that no longer describe the configuration. 

- Keeping files reasonably sized and focused. 

Streamlining does not mean: 

- Rewriting the repository. 

- Applying a preferred personal architecture. 

- Moving all configuration into new modules. 

- Creating a framework for a single use. 

- Introducing a new library or helper for a trivial expression. 

- Moving host-specific behavior into shared configuration. 

- Removing packages or services because their use is not immediately visible. 

- Replacing readable Nix with highly generic or clever Nix. 

- Reformatting entire unrelated files. 

- Renaming files or modules without a practical reason. 

- Updating every input. 

- Replacing working configuration with another person's dotfiles structure. 

Prefer deletion or direct configuration over a new abstraction, but only when behavioral equivalence has been established. 

## **Editing Conventions** 

Make the smallest change that fits the existing structure. 

9 

If a module for a feature already exists, edit it. 

If a change is only for one machine, place it under that host. 

If a change should intentionally apply to multiple machines, determine which hosts import the affected file and explain the impact before editing. 

### **Host-specific configuration** 

Use: 

```
configs/hosts/<host>
```

Keep host-specific overrides close to the host under: 

```
configs/hosts/<host>/home/modules
configs/hosts/<host>/system/modules
```

### **Home Manager modules** 

Add Home Manager modules under: 

```
configs/home-manager/modules/<category>/<name>/default.nix
```

Import them from the relevant profile or: 

```
configs/home-manager/modules.nix
```

Create a new Home Manager module only when: 

- No existing module owns the feature. 

- Adding the feature to an existing file would mix unrelated concerns. 

- The new module will have a clear responsibility. 

### **NixOS modules** 

Add NixOS modules under: 

```
configs/system/modules/<category>/<name>.nix
```

10 

Import them through: 

- A system profile • Shared host configuration • A host-specific <mark>`system/modules.nix`</mark> 

Create a new NixOS module only when the existing structure does not already provide a clear owner. 

### **Style** 

- Preserve surrounding Nix style and naming conventions. 

- Do not rewrite files solely to match a personal preference. 

- 

- Avoid huge files, but do not split a file without a concrete clarity benefit. 

- 

- Prefer explicit names. 

- Avoid premature abstractions. 

- Keep comments focused on why a non-obvious decision exists. 

- Do not add comments that merely restate the code. 

- Preserve intentional option ordering where it improves readability. 

- Avoid unrelated whitespace churn. 

## **Cross-Host Changes** 

A file under <mark>`configs/hosts/desktop`</mark> should affect only <mark>`desktop` .</mark> 

A file under <mark>`configs/hosts/g14`</mark> should affect only <mark>`g14` .</mark> 

A file under <mark>`configs/hosts/t480s`</mark> should affect only <mark>`t480s` .</mark> 

A change under <mark>`configs/system`</mark> may affect multiple NixOS hosts. 

A change under <mark>`configs/home-manager`</mark> may affect multiple Home Manager outputs. 

A change to shared Wayland, shell, editor, service, package, or profile modules may affect <mark>`desktop` ,</mark> <mark>`g14` ,</mark> and <mark>`t480s` ,</mark> depending on their imports. 

Before changing a shared file: 

1. Inspect all import paths that reference it. 

- Determine which NixOS hosts and Home Manager outputs are affected. 

2. 

- Prefer a host-specific override when the requested behavior is host-specific. 

3. 

4. Report the expected cross-host impact. 

Do not silently move host-specific behavior into a shared module. 

Do not broaden the scope of a task merely to make configurations look uniform. 

11 

## **Formatting and Static Analysis** 

Use the repository's existing formatter when available. 

Prefer <mark>`alejandra`</mark> for changed Nix files if it is already installed or provided by the repository environment. 

Format only files changed during the task unless a broader formatting operation was explicitly requested. 

If available, the following tools may be used as advisory diagnostics: 

- <mark>`statix`</mark> 

- <mark>`deadnix`</mark> 

Use their read-only or check modes first. 

Do not run automatic rewriting modes such as: 

```
statixfix
deadnix--edit
```

unless Edward explicitly requests automatic fixes and every resulting change will be reviewed. 

Static-analysis findings are not proof that code is safe to remove. 

In particular: 

- A value may be referenced through an import or module system. 

- Function arguments may be supplied through <mark>`callPackage` .</mark> 

- Module arguments may look unused to a syntax-only tool. 

- Dynamically constructed attributes may not be understood. 

- A warning may be a false positive. 

- A stylistic warning does not justify an unrelated refactor. 

Do not add formatter or linter dependencies solely to complete a small repair. 

## **Validation Workflow** 

Use the narrowest relevant validation first, followed by broader validation after the logical change is stable. 

### **For a Nix syntax or expression change** 

- Format the changed file. 

1. 

2. Run an appropriate targeted evaluation. 

- Run <mark>`nix flake check`</mark> when the change can affect flake evaluation. 

3. 

12 

### **For a NixOS system change** 

Run: 

```
nixos-rebuildbuild--flake.#<host>
```

For example: 

```
nixos-rebuildbuild--flake.#desktop
```

### **For a Home Manager change** 

Run: 

```
home-managerbuild--flake.#edward-<host>
```

For example: 

```
home-managerbuild--flake.#edward-desktop
```

### **For a local package change** 

Run: 

```
nixbuild.#packages.x86_64-linux.<name>
```

Also build any host or Home Manager output that consumes the package when practical. 

### **For a flake or input change** 

Run: 

```
nixflakecheck
```

Then build every directly affected output. 

### **Before completion** 

Run: 

13 

```
gitdiff--check
```

Then: 

1. Review the complete diff. 

- Verify that only intended files changed. 

2. 

3. Verify that no secrets were introduced. 

- Verify that no hardware configuration changed. 

4. 

- Verify the affected hosts and outputs. 

5. 

6. Report every validation command and its result. 

## **Validation Boundaries** 

A successful evaluation proves that Nix can evaluate the relevant expression. 

A successful build proves that Nix can build the relevant output. 

Neither result necessarily proves that: 

- A graphical session starts correctly. 

- A service behaves correctly after activation. 

- Suspend or resume works. 

- GPU switching works. 

- Hardware controls work. 

- A network route is reachable. 

- A remote server remains accessible. 

- An interactive application behaves correctly. 

- A problem requiring reboot has been resolved. 

When activation is required for final verification, report: 

```
Build validated; activation verification required.
```

Do not claim the runtime issue is fully fixed unless it was safely and directly verified. 

## **Flake Input and Lock-File Policy** 

Do not update <mark>`flake.lock`</mark> merely to see whether newer inputs solve a problem. 

Update an input only when: 

- The root cause is confirmed to be in the pinned dependency. 

- The requested feature requires a newer dependency. 

- A current option or package is unavailable in the pinned revision. 

14 

- Edward explicitly asks for an update. 

When updating inputs: 

1. Update only the required input when possible. 

2. Inspect the lock-file diff. 

3. Avoid unrelated input churn. 

4. Review any transitive changes. 

5. Run the full applicable validation. 

6. Explain why the update was necessary. 

Do not replace a reproducible diagnosis with a blanket <mark>`nix flake update` .</mark> 

## **Service Safety** 

Inspecting service status and logs is allowed. 

Changing service state is not allowed by default. 

Do not stop, restart, reload, enable, disable, or mask a system or user service unless Edward explicitly requests it. 

Be especially careful with: 

• <mark>`sshd`</mark> 

- Caddy • Tailscale • Syncthing • Display managers • UWSM 

- Graphical-session targets 

- Network services 

- Filesystem and storage services • Remote-access services 

A build-time validation is preferable to service disruption. 

Changes involving remote access on <mark>`t480s`</mark> require special caution because a mistake could make the server unreachable. 

## **Destructive Operation Policy** 

Do not run: 

- Garbage collection 

- Generation deletion 

- Store optimization or repair 

15 

- Filesystem cleanup 

- Cache deletion 

- Broad package removal 

- Disk formatting 

- Partitioning commands 

- Recursive deletion 

- Git cleanup 

- Secret rotation 

- Certificate replacement 

unless Edward explicitly requests the exact operation and its consequences are understood. 

Do not use destructive cleanup as a general response to a failed build or low disk space. 

## **Web Research Policy** 

Use current web research when the problem depends on: 

- A changed or removed NixOS option 

- A changed Home Manager option 

- A recent nixpkgs package change 

- A regression in an upstream project 

- Version-specific behavior 

- An unfamiliar error message 

- Current driver or hardware guidance 

- Current Codex behavior 

- Current documentation 

Prefer sources in this order: 

1. Official Nix, NixOS, nixpkgs, or Home Manager documentation 

2. Nixpkgs source and module definitions 

3. Official upstream documentation 

4. Official upstream issue trackers and release notes 

5. Maintainer discussions 

6. Community examples only as supporting context 

Do not copy configuration from Reddit, a blog, or another dotfiles repository without verifying: 

- The NixOS or Home Manager version 

- The relevant package version 

- The module option definitions 

- The host's hardware and role 

- The repository's existing structure 

Use community configurations to discover possibilities, not as proof that a change is correct. 

16 

## **Handling Existing Failures** 

A full flake check or build may fail because of a problem that predates the current task. 

When that occurs: 

1. Determine whether the failure is related to the current edit. 

2. Compare against the baseline when possible. 

3. Do not modify unrelated configuration simply to make the check green. 

4. Report the pre-existing failure separately. 

5. Validate the current change using the narrowest reliable alternative. 

6. Clearly state any validation that remains blocked. 

Do not take ownership of unrelated failures without evidence. 

## **Completion Criteria** 

A repair task is complete only when: 

- The reported problem was investigated. 

- The root cause was confirmed or the uncertainty was clearly documented. 

- The smallest appropriate repair was made. 

- Relevant formatting and validation were run. 

- The final diff was reviewed. 

- Cross-host impact was identified. 

- Runtime checks that still require activation were documented. 

- Remaining risks or unconfirmed symptoms were reported. 

A streamlining task is complete only when: 

- Removed code was confirmed to be redundant, obsolete, or unused. 

- Behavior and host boundaries were preserved. 

- No unrelated subsystem was reorganized. 

- The affected outputs still evaluate and build. 

- The final configuration is easier to understand without introducing unnecessary abstractions. 

## **Completion Report** 

At the end of a task, provide a structured report with the following sections. 

### **Problems Investigated** 

For each reported symptom, state: 

- The symptom 

- The evidence inspected 

- Whether it was reproduced 

17 

• Its classification 

### **Confirmed Root Causes** 

Explain the supported root cause of each confirmed problem. 

Do not present speculation as fact. 

### **Files Changed** 

List every changed file and explain why it changed. 

### **Repairs** 

Describe each functional repair separately. 

### **Streamlining** 

List only behavior-preserving cleanup that was actually performed. 

Do not describe a bug fix as streamlining. 

### **Validation** 

List every command run and whether it: 

- Passed • Failed • Was blocked • Exposed a pre-existing problem 

### **Impact** 

State exactly which of the following may be affected: 

- <mark>`desktop`</mark> 

- • <mark>`g14`</mark> 

- <mark>`t480s`</mark> 

- <mark>`edward-desktop`</mark> 

- <mark>`edward-g14`</mark> 

- <mark>`edward-t480s`</mark> 

- • Local packages • Flake inputs 

### **Manual Verification** 

List only the minimal runtime checks Edward should perform after reviewing and activating the changes. 

18 

Do not activate the configuration yourself unless explicitly requested. 

### **Remaining Issues** 

List: 

- Unconfirmed symptoms 

- Upstream problems 

- Blocked validation 

- Required activation checks • Risks • Work intentionally left out of scope 

Do not claim that all problems are fixed when evidence is incomplete. 

## **Default Decision Rules** 

When uncertain: 

- Choose <mark>`desktop`</mark> as the target host if no host was named. 

- Inspect imports before deciding whether a change is shared. 

- Keep behavior host-specific unless sharing is clearly intentional. 

- Prefer an existing module over creating a new one. 

- Prefer a small repair over a rewrite. 

- Prefer a targeted build over activation. 

- Prefer primary documentation over community snippets. 

- Prefer reporting uncertainty over guessing. 

- Prefer leaving working code alone over speculative cleanup. 

19 

