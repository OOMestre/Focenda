#!/bin/bash
# ==============================================================================
# Focenda Worktree Helper
# Manages isolated Git worktrees for multi-chat parallel development.
# ==============================================================================

set -e

ACTION="${1:-list}"
NAME="$2"
BRANCH="$3"
ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
WORKTREES_DIR="$ROOT_DIR/.worktrees"

case "$ACTION" in
    add|create|new)
        if [ -z "$NAME" ]; then
            echo "❌ Usage: $0 add <name> [branch-name]"
            echo "   Example: $0 add bookmark-stats feat/bookmark-stats"
            exit 1
        fi

        TARGET_BRANCH="${BRANCH:-feat/$NAME}"
        TARGET_DIR="$WORKTREES_DIR/$NAME"

        mkdir -p "$WORKTREES_DIR"

        if [ -d "$TARGET_DIR" ]; then
            echo "⚠️ Worktree already exists at: $TARGET_DIR"
            exit 0
        fi

        echo "🔄 Ensuring staging is up to date..."
        git fetch origin staging:staging 2>/dev/null || true

        echo "🌿 Creating worktree at '$TARGET_DIR' on branch '$TARGET_BRANCH' from staging..."
        if git show-ref --verify --quiet "refs/heads/$TARGET_BRANCH"; then
            git worktree add "$TARGET_DIR" "$TARGET_BRANCH"
        else
            git worktree add -b "$TARGET_BRANCH" "$TARGET_DIR" staging
        fi

        echo "✅ Worktree ready at: $TARGET_DIR"
        echo "💡 In your new chat, you can work inside: $TARGET_DIR"
        ;;

    list|ls)
        echo "📂 Active Git Worktrees:"
        git worktree list
        ;;

    remove|rm|delete)
        if [ -z "$NAME" ]; then
            echo "❌ Usage: $0 remove <name>"
            echo "   Example: $0 remove bookmark-stats"
            exit 1
        fi

        TARGET_DIR="$WORKTREES_DIR/$NAME"

        if [ -d "$TARGET_DIR" ]; then
            echo "🗑️ Removing worktree at: $TARGET_DIR"
            git worktree remove "$TARGET_DIR" --force 2>/dev/null || git worktree remove "$TARGET_DIR"
            echo "✅ Worktree removed."
        else
            if git worktree list | grep -q "$NAME"; then
                git worktree remove "$NAME" --force
                echo "✅ Worktree removed."
            else
                echo "⚠️ Worktree not found for: $NAME"
            fi
        fi
        git worktree prune
        ;;

    *)
        echo "Usage: $0 {add|list|remove} [name] [branch]"
        exit 1
        ;;
esac
