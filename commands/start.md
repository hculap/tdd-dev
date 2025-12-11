---
description: Enable TDD Dev Mode for the session
allowed-tools: Read, Write, Glob, Grep, Bash, AskUserQuestion
---

# TDD Mode Activation

Activate TDD Dev Mode for this session. From now on, apply strict Test-Driven Development practices to all coding requests.

## Step 1: Create TDD Mode Flag File

**CRITICAL**: Create the flag file that enables hook enforcement.

1. Ensure `.claude/` directory exists in project root
2. Create the TDD mode state file at `.claude/.tdd-mode-active` with the following JSON content:

```json
{
  "active": true,
  "activatedAt": "[current ISO timestamp]",
  "strictness": "strict"
}
```

This file signals to hooks that TDD mode is active and enforcement should apply.

## Step 2: Configuration Detection

Detect project test configuration:

1. **Check for settings file**: Look for `.claude/tdd-dev.local.md` in project root
2. **Auto-detect test command**:
   - If `package.json` exists: Use `npm test` or check for vitest/jest in devDependencies
   - If `pyproject.toml` or `pytest.ini` exists: Use `pytest`
   - If `go.mod` exists: Use `go test ./...`
   - Otherwise: Ask user for test command

3. **Read strictness setting**: Default to `strict` if not configured

4. **Update flag file**: If strictness was configured differently, update `.claude/.tdd-mode-active` with the detected strictness level

## Step 3: Session State

Set the following TDD mode state:
- **TDD Mode**: ACTIVE (flag file created)
- **Strictness**: [detected or default: strict]
- **Test Command**: [detected command]

## User Guidance

Provide a brief orientation:

```
TDD Dev Mode: ACTIVE

Configuration:
  Strictness: [mode]
  Test Command: [command]

Available Commands:
  /tdd-dev:feature "<description>" - Implement new feature with TDD
  /tdd-dev:bug "<description>"     - Fix bug with regression test first
  /tdd-dev:refactor "<target>"     - Safe refactoring with test coverage

Flags (any command):
  --strict / --standard / --relaxed  - Override strictness
  --no-refactor                      - Skip refactor phase
  --file <path>                      - Target specific file

How it works:
  1. All coding requests now follow Red→Green→Refactor
  2. Tests are written BEFORE implementation
  3. Changes require failing tests first (in strict mode)
```

## Behavior Change

After activation:
- Coding requests (features, bugs) automatically engage TDD workflow
- Use the tdd-methodology skill for all implementation guidance
- Enforce strictness rules on Write/Edit operations to source files
- Track Red→Green→Refactor cycles

Confirm activation and await user's first TDD task.
