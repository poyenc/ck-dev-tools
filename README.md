# ck-dev-tools

CLI tools for developing [Composable Kernel (CK)](https://github.com/ROCm/composable_kernel) across the [`rocm-libraries`](https://github.com/ROCm/rocm-libraries) monorepo and customer repos that consume CK as a submodule.

## Problem

`rocm-libraries` is a monorepo containing CK under `projects/composablekernel/`. The standalone CK repo is synced periodically, so there's a gap where changes exist in the monorepo but not yet in the CK repo. When debugging in a customer repo that uses CK as a submodule, you end up manually duplicating patches between the two.

These tools let you use `rocm-libraries` directly as a CK remote — no manual patch copying.

## Install

```bash
git clone <this-repo> ~/workspace/repo/ck-dev-tools
cd ~/workspace/repo/ck-dev-tools
bash install.sh
```

This copies the scripts to `~/.local/bin/`. Ensure it's on your PATH:

```bash
export PATH="${HOME}/.local/bin:${PATH}"  # add to ~/.bashrc
```

## Tools

### ck-subtree-update

Extracts `projects/composablekernel/` from a `rocm-libraries` branch into a standalone branch that has CK at the repo root.

**Run from:** `rocm-libraries` repo root

```bash
ck-subtree-update                        # split current branch
ck-subtree-update develop                # split develop
ck-subtree-update users/poyenc/my-fix    # split a feature branch
```

This creates a branch named `ck-split/<branch>` using `git subtree split`. The first run rewrites history (takes ~1 minute), subsequent runs are incremental and fast thanks to `--rejoin`.

### ck-remote-setup

Adds `rocm-libraries` as a remote in a customer repo's CK submodule, configured so only the split branches are visible.

**Run from:** CK submodule directory inside a customer repo

```bash
cd ~/customer-repo/third_party/composable_kernel
ck-remote-setup ~/workspace/repo/rocm-libraries
ck-remote-setup ~/workspace/repo/rocm-libraries my-remote  # custom remote name
```

After setup, branches from the monorepo appear as normal remote tracking branches:

```
rocm-ck/develop
rocm-ck/users/poyenc/my-fix
```

### ck-cherry-pick

Cherry-picks a `rocm-libraries` monorepo commit into your CK submodule, automatically translating the commit SHA from monorepo space to the subtree-split space.

**Run from:** CK submodule directory inside a customer repo

```bash
ck-cherry-pick abc1234                                      # uses rocm-ck remote
ck-cherry-pick abc1234 ~/workspace/repo/rocm-libraries      # explicit path
```

If the monorepo commit doesn't touch any files under `projects/composablekernel/`, it prints a warning and skips.

## Workflow

```
┌─────────────────────────────────┐
│       rocm-libraries            │
│                                 │
│  1. ck-subtree-update develop   │
│     ck-subtree-update my-branch │
└──────────────┬──────────────────┘
               │ creates ck-split/* branches
               ▼
┌─────────────────────────────────┐
│  customer-repo/ck-submodule     │
│                                 │
│  2. ck-remote-setup <path>      │  (one-time)
│  3. git fetch rocm-ck           │
│                                 │
│  Then use normally:             │
│    git log rocm-ck/develop      │
│    git cherry-pick <sha>        │
│    git diff HEAD..rocm-ck/develop│
│    git merge rocm-ck/my-branch  │
│                                 │
│  Or translate monorepo SHAs:    │
│    ck-cherry-pick <mono-sha>    │
└─────────────────────────────────┘
```

## Example: applying a monorepo fix to a customer repo

```bash
# 1. In rocm-libraries, split the branch containing the fix
cd ~/workspace/repo/rocm-libraries
ck-subtree-update develop

# 2. In the customer repo's CK submodule, set up remote (first time only)
cd ~/customer-repo/third_party/composable_kernel
ck-remote-setup ~/workspace/repo/rocm-libraries

# 3. Fetch latest
git fetch rocm-ck

# 4. Cherry-pick by monorepo SHA (the one you see in rocm-libraries log)
ck-cherry-pick cd88039246

# Or browse and pick from the split branch directly
git log --oneline rocm-ck/develop
git cherry-pick <sha-from-split-branch>
```

## How it works

`git subtree split --prefix=projects/composablekernel/` rewrites the monorepo history to produce a synthetic branch where:
- Only commits touching `projects/composablekernel/` are included
- The `projects/composablekernel/` prefix is stripped from all paths
- The result has the same file layout as the standalone CK repo

The `ck-remote-setup` refspec maps `refs/heads/ck-split/*` to `refs/remotes/rocm-ck/*`, so the `ck-split/` prefix is hidden and branches appear with clean names.
