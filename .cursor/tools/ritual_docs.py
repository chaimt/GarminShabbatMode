#!/usr/bin/env python3
"""
Pre-push hook: run the ritual.docs workflow (create/update PR documentation).

Invokes the Cursor CLI when available to execute the workflow from
.cursor/commands/ritual.docs.md; otherwise ensures docs/pull-requests/PR-<branch>.md
exists with the SpecIt template.

Non-interactive Cursor CLI use may require CURSOR_API_KEY (see Cursor CLI docs).
"""

import logging
import os
import shutil
import subprocess
import sys
from datetime import date
from pathlib import Path

log = logging.getLogger("ritual_docs")


def get_repo_root() -> str | None:
    """Return git repo root or None if not in a repo."""
    try:
        out = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True,
            text=True,
            check=True,
        )
        return out.stdout.strip() or None
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None


def get_current_branch() -> str | None:
    """Return current git branch or None."""
    try:
        out = subprocess.run(
            ["git", "branch", "--show-current"],
            capture_output=True,
            text=True,
            check=True,
        )
        return out.stdout.strip() or None
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None


def branch_to_pr_filename(branch: str) -> str:
    """Sanitize branch name for PR doc filename (e.g. feature/foo -> feature-foo)."""
    return branch.replace("/", "-").strip() or "unknown"


def get_specit_template(title: str) -> str:
    """SpecIt-style PR doc template (matches .cursor/commands/ritual.docs.md)."""
    today = date.today().isoformat()
    return f"""---
# PR: {title}
**Status:** Draft
**Author:** [Name]
**Date:** {today}

## 1. Context & Intent
*Why is this change happening? What problem does it solve?*

## 2. Proposed Changes


[Image of software architecture diagram]

*High-level summary of the logic changes. Focus on "The What" and "The How".*

## 3. Architectural Impact
* **Data Structures:** Any changes to schemas or state?
* **Interfaces:** Changes to APIs, Props, or Exports?
* **Dependencies:** New packages or modified internal imports?

## 4. Technical Decisions
*List specific "Trade-offs" made during development.*
* **Decision A:** Why we chose X over Y.

## 5. Verification Plan
* [ ] Automated Tests added?
* [ ] Manual Verification steps?
---
"""


def find_agent_cli() -> str | None:
    """Return path to Cursor agent CLI ('agent' or 'cursor') or None.

    Skips the Cursor.app shell wrapper (macOS .app bundle binary) which
    cannot be used as an agent CLI.
    """
    for name in ("agent", "cursor"):
        path = shutil.which(name)
        if path and ".app/Contents/" not in path:
            return path
    return None


def _shell_safe(s: str) -> str:
    """Remove chars that break Cursor app wrapper eval (it passes args through shell)."""
    for c in "'\"`$\\\n\r":
        s = s.replace(c, " ")
    return " ".join(s.split())  # collapse runs of spaces


def run_cursor_agent(repo_root: str, branch: str, pr_doc_path: Path) -> bool:
    """Invoke Cursor CLI with ritual.docs workflow. Return True on success."""
    prompt = (
        "Act as a Technical Architect. Your goal is to generate or update a PR documentation file "
        "in docs/pull-requests/ using the SpecIt style: lean, intent-focused, architectural impact. "
        f"Current branch is: {_shell_safe(branch)}. "
        f"Target file: {_shell_safe(pr_doc_path.name)}. "
        "Follow the instructions in .cursor/commands/ritual.docs.md: "
        "create the file if missing with the SpecIt template; if it exists do NOT overwrite "
        "Context or Technical Decisions, only append new Proposed Changes or Decisions and update "
        "Architectural Impact. Use the diff between this branch and main to inform the content."
    )
    prompt = _shell_safe(prompt)
    cli = find_agent_cli()
    if not cli:
        log.info("No agent CLI found; skipping Cursor agent")
        return False
    log.info("Running Cursor agent CLI: %s", cli)
    try:
        proc = subprocess.Popen(  # nosemgrep: python.lang.security.audit.dangerous-subprocess-use-audit  # args are internally constructed, no shell=True
            [cli, "-p", prompt, "--force"],
            cwd=repo_root,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
        )
        for line in proc.stdout or []:
            print(line, end="", flush=True)
        proc.wait(timeout=300)
        if proc.returncode == 0:
            log.info("Cursor agent completed successfully")
        else:
            log.warning("Cursor agent exited with code %d", proc.returncode)
        return proc.returncode == 0
    except subprocess.TimeoutExpired:
        proc.kill()
        proc.wait()
        log.warning("Cursor agent timed out after 300s")
        return False
    except OSError as exc:
        log.warning("Cursor agent failed to start: %s", exc)
        return False


def ensure_pr_doc_fallback(repo_root: str, branch: str) -> bool:
    """Ensure docs/pull-requests/PR-<branch>.md exists with template. Return True on success."""
    safe_name = branch_to_pr_filename(branch)
    docs_dir = Path(repo_root) / "docs" / "pull-requests"
    pr_path = docs_dir / f"PR-{safe_name}.md"
    try:
        docs_dir.mkdir(parents=True, exist_ok=True)
        if not pr_path.exists():
            pr_path.write_text(get_specit_template(safe_name), encoding="utf-8")
            log.info("Created %s", pr_path.relative_to(repo_root))
        else:
            log.info("PR doc already exists: %s", pr_path.relative_to(repo_root))
        return True
    except OSError as exc:
        log.error("Failed to create PR doc: %s", exc)
        return False


def _prompt_user(message: str) -> bool:
    """Prompt the user for yes/no confirmation via /dev/tty.

    Git hooks don't have access to stdin, so we read directly from /dev/tty.
    Returns True if the user answers yes, False otherwise.
    Defaults to False (skip) when /dev/tty is unavailable (e.g. CI).
    """
    try:
        with open("/dev/tty", "r") as tty_in:
            print(f"{message} [y/N]: ", end="", flush=True)
            answer = tty_in.readline().strip().lower()
            return answer in ("y", "yes")
    except OSError:
        log.info("No TTY available; skipping prompt (defaulting to no)")
        return False


def _redirect_to_tty() -> None:
    """Redirect stdout/stderr to /dev/tty so output is visible during git push.

    Pre-commit hides hook output; writing to /dev/tty bypasses that.
    Silently does nothing when /dev/tty is unavailable (e.g. CI).
    """
    try:
        tty_fd = os.open("/dev/tty", os.O_WRONLY)
        os.dup2(tty_fd, sys.stdout.fileno())
        os.dup2(tty_fd, sys.stderr.fileno())
        os.close(tty_fd)
    except OSError:
        pass


def main() -> int:
    logging.basicConfig(
        format="[ritual_docs] %(levelname)s: %(message)s",
        level=logging.INFO,
    )
    _redirect_to_tty()

    log.info("Starting ritual_docs hook")

    repo_root = get_repo_root()
    if not repo_root:
        log.error("Not in a git repository")
        return 1

    branch = get_current_branch()
    if not branch:
        log.error("Could not determine current branch")
        return 1

    log.info("Branch: %s", branch)
    safe_name = branch_to_pr_filename(branch)
    pr_path = Path(repo_root) / "docs" / "pull-requests" / f"PR-{safe_name}.md"

    if not _prompt_user("Run PR documentation generation?"):
        log.info("Skipped by user")
        return 0

    if run_cursor_agent(repo_root, branch, pr_path):
        log.info("PR documentation updated via Cursor agent")
        return 0

    if ensure_pr_doc_fallback(repo_root, branch):
        log.info("PR documentation ensured via fallback")
        return 0

    log.error("Failed to create or update PR documentation")
    return 1


if __name__ == "__main__":
    sys.exit(main())
