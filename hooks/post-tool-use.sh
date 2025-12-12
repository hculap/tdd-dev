#!/bin/bash
# TDD PostToolUse Hook - Detects test runs and updates cycle state
# Exit codes: 0 = always (PostToolUse cannot block)

# Don't use set -e as we want to continue even if jq fails
INPUT=$(cat)

# Parse input - per Claude Code docs, PostToolUse receives:
# { "tool_name": "...", "tool_input": {...}, "tool_response": {...}, "tool_use_id": "..." }
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# tool_response for Bash contains the output - it may be a string or object
# Try to extract output from various possible formats
TOOL_RESPONSE=$(echo "$INPUT" | jq -r '.tool_response // empty')

# Check if TDD mode is active
TDD_ACTIVE_FILE=".claude/.tdd-mode-active"
if [ ! -f "$TDD_ACTIVE_FILE" ]; then
  exit 0  # TDD not active
fi

ACTIVE=$(jq -r '.active // false' "$TDD_ACTIVE_FILE" 2>/dev/null || echo "false")
if [ "$ACTIVE" != "true" ]; then
  exit 0  # TDD not active
fi

# Only process Bash tool
if [ "$TOOL_NAME" != "Bash" ]; then
  exit 0
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

# Determine if tests passed or failed from tool_response
# The response contains the actual output from the test command
TESTS_FAILED=false

# Check for failure patterns in tool_response
if echo "$TOOL_RESPONSE" | grep -qiE "(FAIL[[:space:]]|FAILED|✗|✘|AssertionError|expect.*received|Expected.*Received|[1-9][0-9]* (failed|failures)|error:|Error:|not ok)"; then
  TESTS_FAILED=true
fi

# Check for explicit pass signals that override
if echo "$TOOL_RESPONSE" | grep -qiE "(All tests passed|0 failures|0 failed|Tests:[[:space:]]+[0-9]+[[:space:]]+passed,[[:space:]]+0[[:space:]]+failed)"; then
  # Only if no clear failure indicators
  if ! echo "$TOOL_RESPONSE" | grep -qE "^[[:space:]]*(FAIL|FAILED)[[:space:]]"; then
    TESTS_FAILED=false
  fi
fi

# Update state
jq --argjson failed "$TESTS_FAILED" '.testsRan = true | .testsFailed = $failed' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"

# Phase transitions and output proper JSON with additionalContext
CONTEXT_MSG=""
if [ "$CURRENT_PHASE" = "red" ] && [ "$TESTS_FAILED" = "true" ]; then
  jq '.phase = "green"' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
  CONTEXT_MSG="TDD Phase: RED → GREEN. Tests failed as expected. You can now implement the minimal code to make them pass."
elif [ "$CURRENT_PHASE" = "green" ] && [ "$TESTS_FAILED" = "false" ]; then
  jq '.phase = "refactor"' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
  CONTEXT_MSG="TDD Phase: GREEN → REFACTOR. Tests passed! You can now optionally refactor while keeping tests green."
elif [ "$CURRENT_PHASE" = "green" ] && [ "$TESTS_FAILED" = "true" ]; then
  CONTEXT_MSG="TDD Phase: GREEN (tests still failing). Keep implementing until tests pass."
elif [ "$CURRENT_PHASE" = "refactor" ] && [ "$TESTS_FAILED" = "true" ]; then
  jq '.phase = "green"' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
  CONTEXT_MSG="TDD Phase: REFACTOR → GREEN (regression!). Refactoring broke tests. Fix them before continuing."
fi

# Output JSON with additionalContext per Claude Code docs
if [ -n "$CONTEXT_MSG" ]; then
  cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "$CONTEXT_MSG"
  }
}
EOF
fi

exit 0
