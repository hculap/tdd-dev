# TDD Dev Plugin

Transform Claude Code from a general code generator into a strict Test-Driven Development practitioner that enforces the Red→Green→Refactor cycle.

## Features

- **Strict TDD Enforcement**: No behavior-changing code without a failing test first
- **Automatic TDD Loop**: Write test → Run → Implement minimal code → Run → Refactor
- **Multiple Strictness Modes**: Strict (block), Standard (prompt), Relaxed (coach)
- **Framework Support**: First-class Jest/Vitest and Pytest support, generic fallback for others
- **Smart Test Detection**: Auto-detects test commands from project configuration
- **Hook-Based Validation**: Automatically validates writes to source files when TDD mode is active

## Installation

```bash
claude --plugin-dir /path/to/tdd-dev
```

Or for development/testing:
```bash
claude --plugin-dir .
```

## Commands

| Command | Description |
|---------|-------------|
| `/tdd-dev:start` | Enable TDD mode for the session (creates flag file) |
| `/tdd-dev:stop` | Disable TDD mode for the session |
| `/tdd-dev:feature "<desc>"` | Implement a new feature using full TDD loop |
| `/tdd-dev:bug "<desc>"` | Create regression test, then fix the bug |
| `/tdd-dev:refactor "<target>"` | Safe refactoring verified by existing tests |

### Command Flags

- `--strict` / `--standard` / `--relaxed` - Override strictness for this command
- `--no-refactor` - Skip refactor phase, stop after green
- `--file <path>` - Target specific test or source file
- `--plan` - Force planning mode (require approval before test and implementation)
- `--skip-plan` - Skip planning entirely, execute directly
- `--ensemble` - Enable ensemble mode for competing patch proposals (experimental)

### Planning Modes

By default, commands will ask if you want to review and approve plans before execution. You can control this behavior:

| Flag | Behavior |
|------|----------|
| `--plan` | Always show plan and require approval before each phase |
| `--skip-plan` | Skip planning, execute directly without approval |
| (default) | Ask user whether to use planning mode |

When planning is enabled, the agent will enter Claude Code's native plan mode before:
1. **Test Phase**: Shows planned test structure and assertions
2. **Implementation Phase**: Shows planned code changes and files to modify

## Strictness Modes

| Mode | Behavior |
|------|----------|
| **Strict** (default) | Block any implementation without a failing test |
| **Standard** | Warn and prompt for confirmation |
| **Relaxed** | Coach and suggest, but don't enforce |

## How It Works

### TDD Mode Activation

When you run `/tdd-dev:start`:

1. Creates `.claude/.tdd-mode-active` flag file with configuration
2. Hooks begin enforcing TDD rules on Write/Edit operations
3. Source file writes require a failing test first (in strict mode)
4. Test file writes are always allowed

### The TDD Loop

1. **Enable TDD Mode**: Run `/tdd-dev:start`
2. **Request a Feature**: "Add pagination to the user list"
3. **Agent Takes Over**:
   - Writes a failing test for the requested behavior (RED)
   - Runs tests, confirms failure
   - Implements minimal code to pass (GREEN)
   - Runs tests, confirms pass
   - Optionally refactors while keeping tests green (REFACTOR)
4. **Iterate**: If tests still fail, the agent iterates (up to configured limit)

### Disabling TDD Mode

Run `/tdd-dev:stop` to disable hook enforcement. You can still use individual commands like `/tdd-dev:feature` without TDD mode active.

## Configuration

Create `.claude/tdd-dev.local.md` in your project:

```markdown
---
testCommand: npm test
strictness: strict
ensemble: false
maxIterations: 5
sourcePatterns:
  - src/**/*.ts
  - src/**/*.tsx
  - app/**/*.py
testPatterns:
  - "**/*.test.*"
  - "**/*.spec.*"
  - "**/__tests__/**"
  - tests/**
---

# Project-Specific TDD Notes

Add any project-specific testing conventions here.
```

### Settings Reference

| Setting | Description | Default |
|---------|-------------|---------|
| `testCommand` | Command to run tests | Auto-detected |
| `strictness` | `strict`, `standard`, or `relaxed` | `strict` |
| `maxIterations` | Max RED→GREEN cycles before asking | `5` |
| `ensemble` | Enable ensemble patch mode | `false` |
| `sourcePatterns` | Globs for source files (hook enforced) | `src/**/*` |
| `testPatterns` | Globs for test files (always allowed) | `**/*.test.*` |

### Global Settings

For user-level defaults, create `~/.claude/tdd-dev.local.md` with the same format.
Project settings override global settings. Command flags override both.

## File Structure

```
.claude/
├── tdd-dev.local.md      # Project settings (optional)
└── .tdd-mode-active      # Flag file (created by /tdd-dev:start)
```

The `.tdd-mode-active` file contains:
```json
{
  "active": true,
  "activatedAt": "2024-01-15T10:30:00Z",
  "strictness": "strict",
  "testCommand": "npm test"
}
```

## Hooks

The plugin includes hooks that:

1. **PreToolUse (Write|Edit)**: Validates source file writes against TDD rules
2. **Stop**: Verifies TDD cycle was followed before task completion

Hooks only activate when `.claude/.tdd-mode-active` exists and `active` is `true`.

## Testing the Plugin

```bash
# Start Claude Code with the plugin
claude --plugin-dir /path/to/tdd-dev

# Verify commands are available
/help

# Enable TDD mode
/tdd-dev:start

# Try a feature
/tdd-dev:feature "Add a function to validate email addresses"

# Disable when done
/tdd-dev:stop
```

## License

MIT
