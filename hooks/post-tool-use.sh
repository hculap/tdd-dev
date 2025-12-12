#!/bin/bash
# TDD PostToolUse Hook - Detects test runs and updates cycle state
# Exit codes: 0 = always (PostToolUse cannot block)

set -e

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
EXIT_CODE=$(echo "$INPUT" | jq -r '.metadata.exit_code // 0')
STDOUT=$(echo "$INPUT" | jq -r '.stdout // empty')
STDERR=$(echo "$INPUT" | jq -r '.stderr // empty')

# Combine stdout and stderr for analysis
OUTPUT="$STDOUT $STDERR"

# Check if TDD mode is active
TDD_ACTIVE_FILE=".claude/.tdd-mode-active"
if [ ! -f "$TDD_ACTIVE_FILE" ]; then
  exit 0  # TDD not active
fi

ACTIVE=$(jq -r '.active // false' "$TDD_ACTIVE_FILE" 2>/dev/null || echo "false")
if [ "$ACTIVE" != "true" ]; then
  exit 0  # TDD not active
fi

# Check if this looks like a test command
# Common test runners
if ! [[ "$COMMAND" =~ (npm[[:space:]]+(run[[:space:]]+)?test|npx[[:space:]]+(jest|vitest|mocha)|yarn[[:space:]]+(run[[:space:]]+)?test|pnpm[[:space:]]+(run[[:space:]]+)?test|pytest|py\.test|python[[:space:]]+-m[[:space:]]+pytest|go[[:space:]]+test|cargo[[:space:]]+test|mix[[:space:]]+test|bundle[[:space:]]+exec[[:space:]]+rspec|rspec|rake[[:space:]]+(test|spec)|phpunit|dotnet[[:space:]]+test|mvn[[:space:]]+(test|verify)|gradle[[:space:]]+test) ]]; then
  exit 0  # Not a test command
fi

STATE_FILE=".claude/.tdd-cycle-state"
if [ ! -f "$STATE_FILE" ]; then
  # Create initial state if it doesn't exist
  echo '{"phase":"red","testFilesWritten":[],"testsRan":false,"testsFailed":false}' > "$STATE_FILE"
fi

CURRENT_PHASE=$(jq -r '.phase // "red"' "$STATE_FILE")

# Determine if tests passed or failed
# Strategy: Trust exit code first, then analyze output as fallback
TESTS_FAILED=false

# Check exit code first (most reliable)
if [ "$EXIT_CODE" != "0" ] && [ "$EXIT_CODE" != "" ]; then
  TESTS_FAILED=true
fi

# If exit code was 0 or unknown, check output for clear pass/fail signals
if [ "$EXIT_CODE" = "0" ] || [ "$EXIT_CODE" = "" ]; then
  # Check for explicit passing signals first
  if echo "$OUTPUT" | grep -qiE "(PASS[[:space:]]|All tests passed|✓|0 failures|0 failed|passing|Tests passed|OK \()"; then
    TESTS_FAILED=false
  fi

  # Check for failure patterns that indicate actual failures (not "0 failed")
  # Use word boundaries and specific patterns
  if echo "$OUTPUT" | grep -qE "^[[:space:]]*(FAIL|FAILED)[[:space:]]" || \
     echo "$OUTPUT" | grep -qiE "(✗|✘|AssertionError|expect.*received|Expected.*Received|[1-9][0-9]* (failed|failures))" || \
     echo "$OUTPUT" | grep -qE "^not ok"; then
    TESTS_FAILED=true
  fi
fi

# Update state
jq --argjson failed "$TESTS_FAILED" '.testsRan = true | .testsFailed = $failed' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"

# Phase transitions
if [ "$CURRENT_PHASE" = "red" ] && [ "$TESTS_FAILED" = "true" ]; then
  jq '.phase = "green"' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
  echo ""
  echo "=========================================="
  echo "TDD Phase: RED -> GREEN"
  echo "Tests failed as expected. Now implement!"
  echo "=========================================="
elif [ "$CURRENT_PHASE" = "green" ] && [ "$TESTS_FAILED" = "false" ]; then
  jq '.phase = "refactor"' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
  echo ""
  echo "=========================================="
  echo "TDD Phase: GREEN -> REFACTOR"
  echo "Tests passed! Optionally refactor now."
  echo "=========================================="
elif [ "$CURRENT_PHASE" = "green" ] && [ "$TESTS_FAILED" = "true" ]; then
  echo ""
  echo "=========================================="
  echo "TDD Phase: GREEN (tests still failing)"
  echo "Keep implementing until tests pass."
  echo "=========================================="
elif [ "$CURRENT_PHASE" = "refactor" ] && [ "$TESTS_FAILED" = "true" ]; then
  # Refactor broke tests - go back to green
  jq '.phase = "green"' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
  echo ""
  echo "=========================================="
  echo "TDD Phase: REFACTOR -> GREEN (regression!)"
  echo "Refactoring broke tests. Fix them first!"
  echo "=========================================="
fi

exit 0
