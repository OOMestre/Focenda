#!/usr/bin/env python3
"""
Focenda Release Notes Generator
Extracts user-friendly change summaries from git log/commits for staging and production release notes.
"""

import argparse
import datetime
import os
import re
import subprocess
import sys


def run_git(args, cwd=None):
    try:
        res = subprocess.run(
            ["git"] + args,
            capture_output=True,
            text=True,
            check=True,
            cwd=cwd
        )
        return res.stdout.strip()
    except subprocess.CalledProcessError:
        return ""


def get_repo_root():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    return os.path.abspath(os.path.join(script_dir, ".."))


def get_current_version(repo_root):
    version_file = os.path.join(repo_root, "VERSION")
    if os.path.isfile(version_file):
        with open(version_file, "r", encoding="utf-8") as f:
            return f.read().strip()
    return "0.1.0"


def get_tags(repo_root):
    tags = run_git(["tag", "--sort=-creatordate"], cwd=repo_root)
    if not tags:
        return []
    return [t.strip() for t in tags.splitlines() if t.strip()]


def get_commits(repo_root, from_ref=None, to_ref="HEAD"):
    if from_ref:
        rev_range = f"{from_ref}..{to_ref}"
    else:
        rev_range = to_ref
    
    # Format: hash|subject|author|date
    log_format = "%h|%s|%an|%ad"
    raw_log = run_git(["log", f"--pretty=format:{log_format}", "--date=short", rev_range], cwd=repo_root)
    if not raw_log:
        return []
    
    commits = []
    for line in raw_log.splitlines():
        parts = line.strip().split("|", 3)
        if len(parts) == 4:
            commits.append({
                "hash": parts[0],
                "subject": parts[1],
                "author": parts[2],
                "date": parts[3]
            })
    return commits


CATEGORIES = [
    ("features", "✨ New Features & Enhancements", [r"^(?:feat|feature|add)(?:\([^\)]+\))?:\s*(.*)$", r"^✨\s*(.*)$"]),
    ("ui", "🎨 User Interface & Experience", [r"^(?:ui|ux|style)(?:\([^\)]+\))?:\s*(.*)$", r"^🎨\s*(.*)$"]),
    ("fixes", "🐛 Bug Fixes & Improvements", [r"^(?:fix|bugfix|patch)(?:\([^\)]+\))?:\s*(.*)$", r"^🐛\s*(.*)$"]),
    ("perf", "⚡ Performance Improvements", [r"^(?:perf|performance)(?:\([^\)]+\))?:\s*(.*)$", r"^⚡\s*(.*)$"]),
    ("refactor", "🛠️ Architecture & Refactoring", [r"^(?:refactor)(?:\([^\)]+\))?:\s*(.*)$", r"^🛠️?\s*(.*)$"]),
    ("docs", "📚 Documentation", [r"^(?:docs|doc)(?:\([^\)]+\))?:\s*(.*)$", r"^📝\s*(.*)$", r"^📚\s*(.*)$"]),
    ("ci", "⚙️ CI/CD & Build Infrastructure", [r"^(?:ci|chore|build|tooling)(?:\([^\)]+\))?:\s*(.*)$", r"^⚙️\s*(.*)$"]),
    ("tests", "🧪 Testing & Quality Assurance", [r"^(?:test|tests)(?:\([^\)]+\))?:\s*(.*)$", r"^🧪\s*(.*)$"]),
]


def clean_subject(subject):
    for cat_id, title, patterns in CATEGORIES:
        for p in patterns:
            m = re.match(p, subject, re.IGNORECASE)
            if m:
                clean = m.group(1).strip()
                if clean:
                    return cat_id, clean[0].upper() + clean[1:]
    
    m = re.match(r"^[a-zA-Z0-9_\-]+(?:\([^\)]+\))?:\s*(.*)$", subject)
    if m:
        clean = m.group(1).strip()
        if clean:
            return "other", clean[0].upper() + clean[1:]
            
    clean = subject.strip()
    return "other", (clean[0].upper() + clean[1:]) if clean else ""


def generate_release_notes(repo_root, from_ref=None, to_ref="HEAD", version=None, release_type=None, include_raw=False):
    all_tags = get_tags(repo_root)
    
    if not from_ref:
        if all_tags:
            if to_ref in all_tags and len(all_tags) > 1:
                from_ref = all_tags[1]
            elif to_ref not in all_tags and len(all_tags) >= 1:
                from_ref = all_tags[0]
            else:
                from_ref = None

    commits = get_commits(repo_root, from_ref=from_ref, to_ref=to_ref)
    
    base_version = get_current_version(repo_root)
    if not version:
        if to_ref != "HEAD" and to_ref in all_tags:
            version = to_ref
        else:
            version = f"v{base_version}"
            
    if not version.startswith("v") and not version.startswith("V"):
        version = f"v{version}"
        
    if not release_type:
        if "beta" in version.lower() or "rc" in version.lower() or "alpha" in version.lower():
            release_type = "Staging Beta"
        else:
            release_type = "Production Release"
    else:
        release_type = release_type.title()

    today_str = datetime.date.today().strftime("%Y-%m-%d")
    
    categorized = {cat[0]: [] for cat in CATEGORIES}
    categorized["other"] = []
    
    for c in commits:
        cat_id, cleaned = clean_subject(c["subject"])
        if cat_id not in categorized:
            cat_id = "other"
        categorized[cat_id].append({
            "cleaned": cleaned,
            "hash": c["hash"],
            "raw": c["subject"],
            "author": c["author"]
        })
        
    lines = []
    lines.append(f"# 🚀 Focenda {version} Release Notes")
    lines.append("")
    lines.append(f"- **Release Date:** `{today_str}`")
    lines.append(f"- **Release Stage:** `{release_type}`")
    if from_ref:
        lines.append(f"- **Commit Range:** `{from_ref}...{to_ref}` ({len(commits)} commits)")
    else:
        lines.append(f"- **Total Commits Included:** {len(commits)}")
    lines.append(f"- **Target OS:** macOS 14.0+ (Sonoma or later)")
    lines.append("")
    lines.append("---")
    lines.append("")
    lines.append("### 🌟 Release Summary")
    
    if "beta" in version.lower():
        lines.append(f"This is a **Staging Beta Release** for **Focenda {version}**. It includes test validation, continuous integration builds, and staging verification for macOS.")
    else:
        lines.append(f"Welcome to **Focenda {version}**! This release delivers native productivity workflows, an intelligent focus timer, task prioritization, and dashboard analytics for macOS.")
    lines.append("")
    
    has_items = False
    for cat_id, title, _ in CATEGORIES:
        items = categorized.get(cat_id, [])
        if items:
            has_items = True
            lines.append(f"### {title}")
            for item in items:
                lines.append(f"- {item['cleaned']} (`{item['hash']}`)")
            lines.append("")
            
    other_items = categorized.get("other", [])
    if other_items:
        has_items = True
        lines.append("### 📋 Additional Changes & Maintenance")
        for item in other_items:
            lines.append(f"- {item['cleaned']} (`{item['hash']}`)")
        lines.append("")
        
    if not has_items:
        lines.append("### 📝 Changes")
        lines.append("- Routine maintenance, optimizations, and internal stability improvements.")
        lines.append("")
        
    lines.append("---")
    lines.append("")
    lines.append("### 📦 Installation & Verification")
    if "beta" in version.lower():
        lines.append("1. Download `Focenda-macOS.zip` or extract `Focenda Staging.app` into `/Applications` or run locally.")
        lines.append("2. Or build locally using `make staging` or double-click `Focenda Staging Launcher.app`.")
        lines.append("3. Report any issues or feedback to the development repository.")
    else:
        lines.append("1. Download `Focenda-macOS.zip` from the release assets.")
        lines.append("2. Move `Focenda.app` to your `/Applications` directory.")
        lines.append("3. Launch Focenda and enjoy focused productivity!")
    lines.append("")

    if include_raw and commits:
        lines.append("---")
        lines.append("")
        lines.append("### 🔍 Full Commit History")
        lines.append("```text")
        for c in commits:
            lines.append(f"{c['hash']} - {c['subject']} ({c['author']}, {c['date']})")
        lines.append("```")
        lines.append("")

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(
        description="Extracts user-friendly change summaries from git commits for release notes."
    )
    parser.add_argument("--from", dest="from_ref", help="Start git commit/tag range (exclusive)")
    parser.add_argument("--to", dest="to_ref", default="HEAD", help="End git commit/tag range (inclusive, default: HEAD)")
    parser.add_argument("--version", dest="version", help="Release version title (e.g. v0.1.0 or v0.1.0-beta.1)")
    parser.add_argument("--release-type", dest="release_type", choices=["staging", "production", "beta"], help="Type of release")
    parser.add_argument("--output", "-o", dest="output_file", help="Output file path (default: stdout)")
    parser.add_argument("--include-raw-log", action="store_true", help="Include raw git commit log in notes")

    args = parser.parse_args()
    repo_root = get_repo_root()

    notes = generate_release_notes(
        repo_root=repo_root,
        from_ref=args.from_ref,
        to_ref=args.to_ref,
        version=args.version,
        release_type=args.release_type,
        include_raw=args.include_raw_log
    )

    if args.output_file:
        output_path = os.path.abspath(args.output_file)
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        with open(output_path, "w", encoding="utf-8") as f:
            f.write(notes + "\n")
        print(f"✅ Release notes written to {args.output_file}")
    else:
        print(notes)


if __name__ == "__main__":
    main()
