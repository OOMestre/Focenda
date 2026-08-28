---
name: focenda-orchestrator
description: >-
  Governs the Focenda workflow: acts as the Integrator / Merge Master to merge
  and resolve conflicts from parallel worktree chats, or as an isolated Feature
  Worker operating inside a dedicated Git Worktree.
---

# Focenda Orchestrator & Integrator Skill

This skill governs both the **Merge Master / Integrator** role and the **Isolated Feature Worker** role in the Focenda macOS productivity project.

## Mode 1: Integrator / Merge Master (Consolidation Chat)

When the user asks to integrate, merge, or finalize features completed in parallel chats:

1. **Pull & Status Check:**
   - Ensure the repository is on `staging`: `git checkout staging`.
   - Update with remote: `git pull origin staging`.
   - List active branches / worktrees: `make worktree-list` or `git branch -a`.

2. **Sequential Merge & Conflict Resolution:**
   - For each target branch (e.g. `feat/xxx`, `fix/yyy`):
     - Run `git merge origin/<branch>` or `git merge <branch>`.
     - If conflicts arise:
       - Carefully inspect conflicted files.
       - Preserve the functionality and intent of both sides according to macOS HIG and project principles.
       - Retain 100% Swift native code, unit tests, and clean architecture.
       - Stage resolved files and complete the merge commit under author `OOMestre`.

3. **Validation & Verification:**
   - Run unit test suite: `make test` (must achieve 100% pass, 0 regressions).
   - Build staging app: `make staging`.

4. **Delivery, Remote Cleanup & CI Validation:**
   - Push integrated `staging` to remote: `git push origin staging`.
   - **Clean up local and remote branches:** `make worktree-remove NAME=<name>` and ensure the remote branch is deleted on GitHub (`git push origin --delete <branch>`). Merged branches must never remain on GitHub.
   - **Monitor and guarantee GitHub Actions CI:** Run `gh run watch <run-id> --exit-status` or `gh run list` to ensure all CI jobs pass with 100% success (green). If any job fails, immediately fix, push, and verify until green.
   - Present a concise, structured integration report to the user including CI status and branch cleanup confirmation.

---

## Mode 2: Isolated Feature Worker (Worktree Chat)

When operating as an isolated feature worker in a dedicated chat:

1. **Worktree Environment:**
   - Ensure work is confined to `.worktrees/<feature-name>` on branch `feat/<feature-name>`.
   - If not yet created, run: `make worktree-add NAME=<feature-name> BRANCH=feat/<feature-name>`.

2. **Scoped Implementation:**
   - Implement only the requested feature or bugfix.
   - Run tests locally in the worktree: `swift test` / `make test`.

3. **Commit & Remote Delivery:**
   - Commit using Conventional Commits (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`) with author `OOMestre`.
   - Push branch to remote: `git push origin feat/<feature-name>`.
   - Report completion and branch name so the Integrator chat can merge it.
