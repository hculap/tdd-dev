---
description: Fix a bug with regression test first
argument-hint: "<bug description>" [--strict|--standard|--relaxed] [--no-refactor] [--file <path>]
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, TodoWrite, AskUserQuestion
---

# TDD Bug Fix

Fix a bug using Test-Driven Development - regression test first: **$ARGUMENTS**

## Parse Arguments

Extract from arguments:
- **Bug description**: The bug to fix (required)
- **--strict / --standard / --relaxed**: Override strictness mode (optional)
- **--no-refactor**: Skip refactor phase after green (optional)
- **--file <path>**: Target specific file (optional)

## Pre-Flight Checks

1. **Load settings**: Read `.claude/tdd-dev.local.md` if exists
2. **Determine strictness**: Use flag override > settings > default (strict)
3. **Detect test command**: From settings or auto-detect
4. **Locate bug**: Find the code responsible for the bug

## Bug Analysis

Before writing tests:

1. **Understand the bug**: What is the incorrect behavior?
2. **Identify root cause**: Where in the code does the bug occur?
3. **Define expected behavior**: What should happen instead?
4. **Find reproduction steps**: How to trigger the bug?

## TDD Bug Fix Loop

### Phase 1: RED - Write Regression Test

**Critical**: Write a test that FAILS due to the bug, proving the bug exists.

1. **Create regression test**:
   - Test name clearly describes the bug scenario
   - Test reproduces the exact failing condition
   - Test asserts the CORRECT expected behavior
2. **Run tests**: Execute test command
3. **Verify RED**: New test fails because of the bug

```
Regression Test: test_[bug_scenario]

Expected: [correct behavior]
Actual: [buggy behavior]
Status: RED ✓ (bug confirmed)
```

If the test passes immediately:
- Bug may already be fixed
- Bug description may be incorrect
- Test may not reproduce the bug correctly
- Investigate before proceeding

### Phase 2: GREEN - Fix the Bug

1. **Make minimal fix**: Change only what's necessary to fix the bug
2. **Avoid scope creep**: Don't refactor or add features
3. **Run tests**: Execute test command
4. **Verify GREEN**: Regression test passes, no new failures

```
Tests: X passed, 0 failed
Regression Test: PASSES ✓
Status: GREEN ✓ (bug fixed)
```

If fix causes other tests to fail:
- Investigate the relationship
- The "bug" might be intentional behavior
- May need to adjust approach

### Phase 3: REFACTOR (unless --no-refactor)

Only proceed when ALL tests are green.

1. **Review the fix**: Is the code clean?
2. **Consider improvements**:
   - Remove any duplication introduced
   - Improve naming if unclear
   - Simplify if possible
3. **Run tests after each change**
4. **Stay GREEN throughout**

## Output Format

Bug fix progress:
```
Bug Fix: [description]

Phase: [RED|GREEN|REFACTOR]
Action: [what was done]
Tests: X passed, Y failed
Regression Test: [FAILS|PASSES]

[Details if needed]
```

## Completion

When bug is fixed:
```
Bug Fixed: [description]

Summary:
  Regression Test: [test name]
  Root Cause: [brief explanation]
  Fix Applied: [what was changed]
  Files Modified: [list]
  Final Status: GREEN ✓

The bug will not regress - protected by test.
```

## Edge Cases

### Bug Cannot Be Reproduced

If unable to write a failing test:
```
Unable to reproduce bug in tests.

Attempted:
- [test approach 1]
- [test approach 2]

Possible reasons:
- Bug occurs in specific environment
- Bug is intermittent
- Bug description needs clarification

Recommendation: [next steps]
```

### Bug in External Dependency

If bug is in external code:
```
Bug appears to be in external dependency: [package]

Options:
1. Work around the bug in our code
2. Report/fix upstream
3. Pin to different version

Recommended: [approach]
```

### Multiple Related Bugs

If investigation reveals multiple issues:
```
Investigation revealed multiple related issues:
1. [issue 1]
2. [issue 2]
3. [issue 3]

Recommended approach: Fix one at a time with TDD.
Starting with: [most fundamental issue]
```

Begin the TDD bug fix process.
