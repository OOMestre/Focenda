#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPOSITORY_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
VERSION_FILE="$REPOSITORY_ROOT/VERSION"

fail() {
  echo "Error: $*" >&2
  exit 1
}

# Defaults
DRY_RUN=0
SKIP_TESTS=0
NO_OPEN=0
CUSTOM_TAG=""
ALLOW_DIRTY=0

usage() {
  cat <<HELP
Usage: $(basename "$0") [OPTIONS]

Automates the Staging Beta release process for Focenda:
1. Validates the test suite with 'make test'.
2. Reads base version from VERSION file.
3. Automatically computes or accepts next beta tag (e.g. v0.1.0-beta.1).
4. Creates an annotated git tag.
5. Builds 'Focenda Staging.app'.

Options:
  --tag <TAG>        Explicitly specify tag name (e.g., v0.1.0-beta.1)
  --dry-run          Simulate the release process without modifying git tags
  --skip-tests       Skip running 'make test' validation
  --no-open          Do not automatically launch Focenda Staging.app after build
  --allow-dirty      Allow releasing with uncommitted changes in git working tree
  -h, --help         Show this help message
HELP
  exit 0
}

# Parse options
while [ $# -gt 0 ]; do
  case "$1" in
    --tag)
      [ $# -gt 1 ] || fail "Missing value for --tag"
      CUSTOM_TAG="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --skip-tests)
      SKIP_TESTS=1
      shift
      ;;
    --no-open)
      NO_OPEN=1
      shift
      ;;
    --allow-dirty)
      ALLOW_DIRTY=1
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      fail "Unknown option: $1. Run with --help for usage."
      ;;
  esac
done

cd "$REPOSITORY_ROOT"

# Check prerequisites
[ -f "$VERSION_FILE" ] || fail "VERSION file not found at $VERSION_FILE"
command -v git >/dev/null 2>&1 || fail "git command is required but not found"

# Read base version
BASE_VERSION=$(tr -d '[:space:]' < "$VERSION_FILE")
if ! printf '%s\n' "$BASE_VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  fail "VERSION must contain semantic version format MAJOR.MINOR.PATCH (e.g. 0.1.0). Found: '$BASE_VERSION'"
fi

# Check git status if not allowed dirty
if [ "$ALLOW_DIRTY" -eq 0 ]; then
  if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    fail "Git working directory has uncommitted changes. Commit or stash them before releasing, or pass --allow-dirty."
  fi
fi

# Determine beta tag
if [ -n "$CUSTOM_TAG" ]; then
  BETA_TAG="$CUSTOM_TAG"
else
  # Find existing beta tags for this version: v0.1.0-beta.N
  EXISTING_BETAS=$(git tag -l "v${BASE_VERSION}-beta.*" 2>/dev/null || true)
  if [ -z "$EXISTING_BETAS" ]; then
    NEXT_BETA_NUM=1
  else
    # Extract highest beta number
    HIGHEST_BETA=0
    for tag in $EXISTING_BETAS; do
      num=$(printf '%s\n' "$tag" | sed "s/^v${BASE_VERSION}-beta\.//" | grep -E '^[0-9]+$' || true)
      if [ -n "$num" ] && [ "$num" -gt "$HIGHEST_BETA" ]; then
        HIGHEST_BETA="$num"
      fi
    done
    NEXT_BETA_NUM=$((HIGHEST_BETA + 1))
  fi
  BETA_TAG="v${BASE_VERSION}-beta.${NEXT_BETA_NUM}"
fi

echo "=================================================="
echo "Focenda Staging Beta Release: $BETA_TAG"
echo "=================================================="
echo "- Base Version: $BASE_VERSION"
echo "- Target Tag:   $BETA_TAG"
echo "- Commit Hash:  $(git rev-parse --short HEAD 2>/dev/null || echo 'HEAD')"
echo "=================================================="

# Step 1: Validate tests
if [ "$SKIP_TESTS" -eq 0 ]; then
  echo ""
  echo "[1/3] Validating test suite with 'make test'..."
  make test || fail "Test suite failed! Staging beta release aborted."
  echo "Tests passed successfully."
else
  echo ""
  echo "[1/3] Skipping test validation (--skip-tests specified)."
fi

# Step 2: Git Tagging
echo ""
echo "[2/3] Tagging release commit with '$BETA_TAG'..."
if git rev-parse "$BETA_TAG" >/dev/null 2>&1; then
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "Tag '$BETA_TAG' already exists (dry run mode)."
  else
    fail "Tag '$BETA_TAG' already exists in the repository! Choose a different tag or delete the old one."
  fi
else
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "[Dry Run] Would create tag: git tag -a '$BETA_TAG' -m 'Release $BETA_TAG (Staging Beta)'"
  else
    git tag -a "$BETA_TAG" -m "Release $BETA_TAG (Staging Beta)"
    echo "Tag '$BETA_TAG' successfully created."
  fi
fi

# Step 3: Build Focenda Staging.app & DMG
echo ""
echo "[3/3] Building Focenda Staging.app and packaging DMG..."
if [ "$DRY_RUN" -eq 1 ]; then
  echo "[Dry Run] Would execute: ./scripts/build-staging.sh"
  echo "[Dry Run] Would execute: ./scripts/create-dmg.sh"
else
  if [ "$NO_OPEN" -eq 1 ]; then
    FOCENDA_RELEASE_TAG="$BETA_TAG" FOCENDA_NO_OPEN=1 "$SCRIPT_DIR/build-staging.sh"
  else
    FOCENDA_RELEASE_TAG="$BETA_TAG" "$SCRIPT_DIR/build-staging.sh"
  fi
  "$SCRIPT_DIR/create-dmg.sh" "$REPOSITORY_ROOT/dist/Focenda Staging.app" "$REPOSITORY_ROOT/dist/Focenda-macOS.dmg" "Focenda Staging"
fi

echo ""
echo "=================================================="
echo "Staging Beta Release Process Complete"
echo "- Tag:       $BETA_TAG"
echo "- Artifacts: dist/Focenda Staging.app"
echo "             dist/Focenda-macOS.dmg"
echo ""
echo "To publish this staging beta tag to GitHub, run:"
echo "  git push origin $BETA_TAG"
echo "=================================================="
