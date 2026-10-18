# Repair and Streamlining Workflow

Read this file for debugging, repair, cleanup, or streamlining tasks. The rules in `AGENTS.md` apply to every task, including these.

## Phase 1: Establish a Baseline

Before editing:

1. Confirm the repository root.
2. Determine the target host. If no host was provided, use `desktop` and state that assumption.
3. Inspect the working tree and existing diff.
4. Inspect the target host's import chain.
5. Identify which module currently owns the affected feature.
6. Record the exact symptom, failing command, failed service, or relevant error.
7. Run the least expensive check that can reproduce or narrow the problem.

Do not begin by changing packages, updating inputs, or reorganizing modules.

A reasonable initial sequence is:

```
git status --short
git diff --stat
nix flake check --no-build
```

Then use a targeted evaluation, build, service status, or journal query based on the symptom.

## Phase 2: Inspect Imports and Ownership

Before deciding where to edit:

1. Inspect `flake.nix`.
2. Trace the target NixOS host's imports.
3. Trace the corresponding Home Manager output's imports.
4. Determine whether the behavior is:
   - Host-specific
   - Shared by selected hosts
   - Shared by all hosts
   - Owned by Home Manager
   - Owned by NixOS
   - Defined by a local package
   - Defined upstream
5. State the expected impact before changing a shared file.

Do not place a host-specific workaround in a shared module merely because the shared module is easy to find.

Do not create a second module for a feature that already has a clear owner.

## Phase 3: Classify the Problem

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

When a problem may be caused by an upstream option rename, package change, regression, or version-specific behavior, verify it against current primary documentation, source code, release notes, or upstream issues before implementing a workaround. See the web research policy below.

## Phase 4: Repair Confirmed Problems

Fix one root cause or one closely related group at a time.

For each repair:

1. Identify the evidence supporting the root cause.
2. Edit the existing module that owns the behavior.
3. Make the smallest sufficient change.
4. Format only the changed files.
5. Run the narrowest relevant evaluation or build.
6. Repair any newly introduced failure before moving on.
7. Review the diff for accidental or unrelated edits.

Do not combine an unresolved bug fix with broad cleanup.

Do not change several unrelated subsystems in one step merely because they all have warnings.

Prefer correcting the source of a conflict over adding another override, force flag, compatibility layer, or duplicated option.

## Phase 5: Conservative Streamlining

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

## Handling Existing Failures

A full flake check or build may fail because of a problem that predates the current task.

When that occurs:

1. Determine whether the failure is related to the current edit.
2. Compare against the baseline when possible.
3. Do not modify unrelated configuration simply to make the check green.
4. Report the pre-existing failure separately.
5. Validate the current change using the narrowest reliable alternative.
6. Clearly state any validation that remains blocked.

Do not take ownership of unrelated failures without evidence.

## Web Research Policy

Use current web research when the problem depends on:

- A changed or removed NixOS option
- A changed Home Manager option
- A recent nixpkgs package change
- A regression in an upstream project
- Version-specific behavior
- An unfamiliar error message
- Current driver or hardware guidance
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

## Completion Criteria

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

## Completion Report

At the end of a repair or streamlining task, provide a structured report with the following sections.

### Problems Investigated

For each reported symptom, state:

- The symptom
- The evidence inspected
- Whether it was reproduced
- Its classification

### Confirmed Root Causes

Explain the supported root cause of each confirmed problem.

Do not present speculation as fact.

### Files Changed

List every changed file and explain why it changed.

### Repairs

Describe each functional repair separately.

### Streamlining

List only behavior-preserving cleanup that was actually performed.

Do not describe a bug fix as streamlining.

### Validation

List every command run and whether it:

- Passed
- Failed
- Was blocked
- Exposed a pre-existing problem

### Impact

State exactly which of the following may be affected:

- `desktop`
- `g14`
- `t480s`
- `edward-desktop`
- `edward-g14`
- `edward-t480s`
- Local packages
- Flake inputs

### Manual Verification

List only the minimal runtime checks Edward should perform after reviewing and activating the changes.

Do not activate the configuration yourself unless explicitly requested.

### Remaining Issues

List:

- Unconfirmed symptoms
- Upstream problems
- Blocked validation
- Required activation checks
- Risks
- Work intentionally left out of scope

Do not claim that all problems are fixed when evidence is incomplete.
