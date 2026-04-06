---
name: git-delivery-handoff
description: Analyzes the current iteration and recommends an atomic commit plan, branch strategy, and PR summary using strict Conventional Commits. Does not execute git commands.
argument-hint: "<optional context or just run it>"
---

# Skill: git-delivery-handoff

## Purpose
Analyzes the latest workspace changes and proposes a clean, professional, and atomic git delivery strategy. It does not execute commands; it only recommends the safest and most coherent way to commit and integrate the work into the Karate API automation framework.

## When to use
At the end of a work iteration, before staging files, or when multiple files have been modified and guidance is needed to split them into atomic, logical commits.

## Inputs expected
The agent should read Git diffs, untracked files, and modified files in the workspace. An optional context string can be provided by the user to explain the main intent.

## Analysis rules
- Detect the nature of the changes (e.g., `docs`, `refactor`, `test`, `config`, `feat`, `fix`, `mixed`).
- Group files not by directory, but by logical intent.
- Identify if changes span multiple disconnected features or just one.

## Atomicity rules
- Atomicity is by **coherent intent**, not by individual file.
- **Do not** recommend absurdly small commits (e.g., one commit per file if they belong to the same logical feature).
- **Do not** recommend a single giant commit mixing `refactor`, `docs`, `test`, and `config` if they are conceptually separate and can be cleanly isolated.
- If an update changes a core Karate `.feature` file and its corresponding test data, they belong in the same commit.

## Branch recommendation rules
- Recommend continuing on the **current branch** if the scope of the change aligns with the current branch's purpose.
- Recommend creating a **new branch** ONLY if the changes introduce a completely separate line of work, pivot to a new feature, or fix a bug completely unrelated to the current branch.
- Branch names must be simple, technical, and in English (e.g., `feat/karate-auth-flow`, `fix/login-edge-case`).

## Conventional commit rules
- Strict adherence to Conventional Commits (`type(scope): description`).
- Types allowed: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.
- **NO emojis.**
- The description must be clear, concise, professional, and written in the imperative mood (e.g., `add user authentication scenario`).
- Use `scope` only when it provides real clarity (e.g., `test(auth)`, `config(maven)`). Avoid generic or redundant scopes.

## Required output format
The skill MUST output the following exact sections in English:

### # Change Summary
[Brief summary of what was analyzed and changed in the workspace]

### # Branch Recommendation
[Recommendation to stay on the current branch or create a new one, including the suggested branch name if applicable, and the rationale]

### # Atomic Commit Plan
[Explanation of how the changes were logically grouped and why]

### # Suggested Conventional Commits
- `type(scope): description`
- `type: description`

### # Files per Commit
[Map each suggested conventional commit to the exact list of files it should include]

### # Pull Request Summary
[A short, professional summary ready to be pasted into a PR description]

### # Pre-Push Checklist
- [ ] Review diff for accidental changes or secrets
- [ ] Run Karate tests locally ensuring no regressions
- [ ] Confirm compliance with guidelines

## Limits
This skill is purely analytical and advisory. It will never run `git commit`, `git push`, or `git checkout`. It relies on accurate parsing of the local workspace state.
