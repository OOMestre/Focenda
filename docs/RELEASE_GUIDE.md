# Focenda Release & Deployment Guide

This guide details the release management philosophy, workflows, gating mechanisms, and tooling for **Focenda** on macOS. It outlines how development moves from fast-iteration **Staging Beta Releases** to battle-tested **Production Releases**.

---

## Table of Contents
1. [Overview & Philosophy](#overview--philosophy)
2. [Release Stages & Gating Matrix](#release-stages--gating-matrix)
3. [Release Lifecycle Architecture](#release-lifecycle-architecture)
4. [Staging Beta Release Workflow](#staging-beta-release-workflow)
5. [Production Release Workflow](#production-release-workflow)
6. [Release Management Tooling & Makefile Targets](#release-management-tooling--makefile-targets)
7. [Automated Release Notes Generation](#automated-release-notes-generation)
8. [GitHub Actions CI/CD Integration](#github-actions-cicd-integration)
9. [Release Checklist & Rollback Procedure](#release-checklist--rollback-procedure)

---

## 1. Overview & Philosophy

Focenda follows a **two-tier release cadence**:

- **Staging Beta Releases (`vX.Y.Z-beta.N`)**:
  - Published from the `staging` branch (or feature branches during stabilization).
  - Designed for fast feedback, internal dogfooding, team testing, and integration verification.
  - Generates `Focenda Staging.app` with an isolated staging bundle identifier (`com.oomestre.focenda.staging`).
  - Flagged as **Prerelease** in GitHub Releases.

- **Production Releases (`vX.Y.Z`)**:
  - Published strictly from the `main` branch.
  - Represents stable, polished builds ready for end users.
  - Protected by strict quality gates: mandatory peer review, 100% passing automated test suite, changelog audit, and semantic version freeze.
  - Flagged as **Stable Release** in GitHub Releases.

---

## 2. Release Stages & Gating Matrix

| Dimension | Staging Beta Release | Production Release |
| :--- | :--- | :--- |
| **Source Branch** | `staging` / feature branches | `main` |
| **Tag Pattern** | `vX.Y.Z-beta.N` (e.g. `v0.1.0-beta.1`) | `vX.Y.Z` (e.g. `v0.1.0`) |
| **App Name** | `Focenda Staging.app` | `Focenda.app` |
| **Bundle ID** | `com.oomestre.focenda.staging` | `com.oomestre.focenda` |
| **Target Audience** | Core team, QA, beta testers | All macOS users |
| **GitHub Release Status** | `Prerelease: true` | `Prerelease: false` (Latest Stable) |
| **Required Gates** | • `make test` passing<br>• Validated `VERSION`<br>• Clean local/CI build<br>• Hardened runtime verified | • All staging beta criteria met<br>• Approved PR into `main`<br>• Updated `CHANGELOG.md`<br>• Clean CI run on `main`<br>• Developer ID signing + notarization |

---

## 3. Release Lifecycle Architecture

```
[ Feature Branches ]
       │
       ▼ (Merge to staging)
[ staging branch ] ────► Run `make test`
       │                   │
       │                   ▼
       ├──────────────► `make release-beta` (Tags `vX.Y.Z-beta.N`)
       │                   │
       │                   ▼
       │              GitHub Actions (`release.yml`) ────► Publishes Staging Beta
       │
       ▼ (Promotion PR after testing)
[ main branch ] ──────► Automated CI Gate (`ci.yml`)
       │                   │
       │                   ▼
       ├──────────────► Sync `VERSION` & `CHANGELOG.md`
       │                   │
       │                   ▼
       └──────────────► Tag `vX.Y.Z` ──► GitHub Actions ──► Publishes Production Release
```

---

## 4. Staging Beta Release Workflow

To create and release a new Staging Beta build:

### Step 1: Ensure Working Tree is Ready
Ensure all intended commits are present and your repository is clean:
```bash
git checkout staging
git pull origin staging
```

### Step 2: Run the Beta Release Automation
Execute the automated staging beta script via `make`:
```bash
make release-beta
```
This command automatically:
1. Executes `make test` to ensure all unit tests pass.
2. Reads the base version from `VERSION` (e.g., `0.1.0`).
3. Determines the next beta counter (e.g., `v0.1.0-beta.1`, `v0.1.0-beta.2`).
4. Creates an annotated git tag (`v0.1.0-beta.N`).
5. Builds the local bundle `dist/Focenda Staging.app`.

The bundle is signed with the hardened runtime. It is intentionally not
sandboxed so the in-app updater can replace the installed app automatically,
without asking the user to select its containing folder.
For a distributable artifact, set `FOCENDA_SIGNING_IDENTITY` to a Developer ID
Application identity; without it, the script intentionally uses an ad-hoc
signature for local/CI staging only.

#### Advanced Beta Options
You can also run `./scripts/release-staging-beta.sh` directly with flags:
- `--tag <TAG>`: Explicitly specify a custom tag name (e.g. `--tag v0.1.0-beta.3`).
- `--dry-run`: Preview actions without creating git tags.
- `--no-open`: Build the app bundle without automatically launching it.
- `--skip-tests`: Bypass unit tests (not recommended for official builds).

### Step 3: Publish the Beta Tag
Push the created tag to GitHub:
```bash
git push origin v0.1.0-beta.1
```
GitHub Actions will automatically pick up the tag, build the staging bundle, zip the artifact, and publish a GitHub Pre-release.

---

## 5. Production Release Workflow

Production releases represent official general availability (GA) milestones.

### Step 1: Verification & Version Freeze
1. Confirm that all beta testing on `staging` is signed off.
2. Update the `VERSION` file if incrementing major/minor/patch:
   ```bash
   echo "0.2.0" > VERSION
   ```

### Step 2: Generate Release Notes & Update Changelog
Use the automated release notes generator to compile the changes:
```bash
make release-notes
```
Or export directly to a markdown file or update `CHANGELOG.md`:
```bash
./scripts/generate-release-notes.sh --release-type production --output dist/RELEASE_NOTES.md
```
Update `CHANGELOG.md` with the release notes and commit the changes.

### Step 3: Pull Request into `main`
1. Open a Pull Request from `staging` to `main`.
2. Verify that all GitHub Actions CI checks (`.github/workflows/ci.yml`) pass.
3. Obtain required review approvals and merge into `main`.

### Step 4: Tag & Publish Production Release
1. Check out the updated `main` branch:
   ```bash
   git checkout main
   git pull origin main
   ```
2. Tag the production release:
   ```bash
   git tag -a v0.2.0 -m "Release v0.2.0"
   git push origin v0.2.0
   ```
3. GitHub Actions triggers the `release.yml` pipeline:
   - Runs full test suite.
   - Builds release artifacts.
   - Creates a public GitHub Release with `prerelease: false`.

---

## 6. Release Management Tooling & Makefile Targets

Focenda includes a set of Makefile convenience commands:

| Command | Action | Description |
| :--- | :--- | :--- |
| `make test` | `swift test` | Runs the full XCTest unit test suite. |
| `make build` | `swift build -c release` | Builds release binary executable. |
| `make staging` | `./scripts/build-staging.sh` | Builds and signs `dist/Focenda Staging.app` with hardened runtime and automatic in-place update support. |
| `make release-beta` | `./scripts/release-staging-beta.sh` | Runs tests, increments beta tag, creates git tag, and builds staging bundle. |
| `make release-notes` | `./scripts/generate-release-notes.sh` | Extracts commit changes into formatted markdown release notes. |
| `make clean` | `rm -rf .build dist` | Cleans build caches and output artifacts. |

---

## 7. Automated Release Notes Generation

The `scripts/generate-release-notes.sh` script parses commit messages into categorized, user-friendly markdown sections.

### Commit Categorization Mapping

| Conventional Commit Prefix | Generated Section |
| :--- | :--- |
| `feat:`, `feature:`, `add:` | ✨ New Features & Enhancements |
| `ui:`, `ux:`, `style:` | 🎨 User Interface & Experience |
| `fix:`, `bugfix:`, `patch:` | 🐛 Bug Fixes & Improvements |
| `perf:`, `performance:` | ⚡ Performance Improvements |
| `refactor:` | 🛠️ Architecture & Refactoring |
| `docs:`, `doc:` | 📚 Documentation |
| `ci:`, `chore:`, `build:`, `tooling:` | ⚙️ CI/CD & Build Infrastructure |
| `test:`, `tests:` | 🧪 Testing & Quality Assurance |

### Custom Arguments & Flags
```bash
# Generate notes for specific version
./scripts/generate-release-notes.sh --version v0.1.0-beta.2

# Generate notes between two tags
./scripts/generate-release-notes.sh --from v0.1.0-beta.1 --to v0.1.0-beta.2

# Write directly to file
./scripts/generate-release-notes.sh --output RELEASE_NOTES.md

# Include full commit log details
./scripts/generate-release-notes.sh --include-raw-log
```

---

## 8. GitHub Actions CI/CD Integration

Focenda's release workflows are automated via GitHub Actions:

### 1. Continuous Integration (`.github/workflows/ci.yml`)
- Triggers on push and PR to `main` and `staging`.
- Executes `swift build -c release` and `swift test` on `macos-14` (Apple Silicon).

### 2. Release & Publish (`.github/workflows/release.yml`)
- Triggers on git tag push matching `v*` (e.g. `v0.1.0`, `v0.1.0-beta.1`).
- Validates tests and builds macOS application bundle.
- Packages application into native drag-and-drop installer `Focenda-macOS.dmg` and background update archive `Focenda-macOS.zip`.
- Detects whether the tag is a beta (`is_prerelease=true`) or production release (`is_prerelease=false`).
- Publishes the GitHub Release with attached `.dmg` and `.zip` binaries and generated release notes.

### 3. In-App Update Client
Focenda checks the public GitHub Releases API from the Mac. The client sends no tasks, notes, preferences, identifiers, or telemetry; the only downloaded content is the public release metadata and the selected `Focenda-macOS.zip` archive.

- The Settings page provides **Check Now** and an enabled-by-default **Check for updates automatically** preference. Automatic checks run at most once every 24 hours while the app is open.
- The distributed Focenda app checks official stable releases only. Releases marked as prerelease or carrying a prerelease tag are ignored, even if their GitHub metadata is inconsistent.
- Before installation, Focenda requires HTTPS GitHub download URLs, the expected Focenda bundle identifier, and a matching release version. It automatically replaces only the running `.app` bundle and relaunches it; local user data remains in macOS storage.
- If the app is running from a development executable or the installed app directory is not writable, the update remains available and Settings shows the reason so the user can install manually from GitHub Releases.

---

## 9. Release Checklist & Rollback Procedure

### Pre-Flight Release Checklist
- [ ] `make test` runs with 0 failures and 0 errors.
- [ ] `VERSION` matches intended target release number.
- [ ] `CHANGELOG.md` reflects all notable user-facing changes.
- [ ] Local staging app builds and launches cleanly (`make staging`).
- [ ] `codesign --verify --deep --strict` passes and the bundle contains the hardened runtime.
- [ ] Public artifacts use Developer ID signing and notarization (`FOCENDA_SIGNING_IDENTITY` configured).
- [ ] UI appearance verified in both Light and Dark macOS system appearance.

### Rollback / Hotfix Procedure
In the unlikely event an issue is discovered post-release:
1. **Beta Releases**: Fix directly on `staging`, run `make release-beta` to produce `vX.Y.Z-beta.(N+1)`.
2. **Production Hotfix**:
   - Branch from `main`: `git checkout -b hotfix/vX.Y.(Z+1) main`.
   - Apply fix, add regression tests, and verify with `make test`.
   - Increment PATCH version in `VERSION` (e.g., `0.1.1`).
   - Merge PR into `main` and tag `v0.1.1`.
   - Backport hotfix commit into `staging` branch to maintain synchronization.
