#!/bin/bash
# Ralph - Long-running AI agent loop for Claude Code CLI
# Usage: ./ralph.sh [project_dir] [max_iterations]
#
# Examples:
#   ./ralph.sh                     # Run in current directory, 10 iterations
#   ./ralph.sh 20                  # Run in current directory, 20 iterations
#   ./ralph.sh ~/Projects/my-app   # Run against my-app, 10 iterations
#   ./ralph.sh ~/Projects/my-app 20 # Run against my-app, 20 iterations

set -e

# Check dependencies
command -v jq >/dev/null 2>&1 || { echo "Error: jq is required but not installed"; exit 1; }
command -v claude >/dev/null 2>&1 || { echo "Error: claude CLI is required but not installed"; exit 1; }

# Parse arguments: detect if first arg is a directory or a number
if [ -n "$1" ]; then
  if [ -d "$1" ]; then
    PROJECT_DIR="$(cd "$1" && pwd)"
    MAX_ITERATIONS=${2:-10}
  elif [[ "$1" =~ ^[0-9]+$ ]]; then
    PROJECT_DIR="$(pwd)"
    MAX_ITERATIONS=$1
  else
    echo "Error: '$1' is not a valid directory or number"
    echo "Usage: ./ralph.sh [project_dir] [max_iterations]"
    exit 1
  fi
else
  PROJECT_DIR="$(pwd)"
  MAX_ITERATIONS=10
fi

# Script dir is where ralph.sh and prompt.md live
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Project files live in the target project
PRD_FILE="$PROJECT_DIR/prd.json"
PROGRESS_FILE="$PROJECT_DIR/progress.txt"
OUTPUT_LOG="$PROJECT_DIR/ralph-output.log"
ARCHIVE_DIR="$PROJECT_DIR/archive"
LAST_BRANCH_FILE="$PROJECT_DIR/.last-branch"

# Archive previous run if branch changed
if [ -f "$PRD_FILE" ] && jq empty "$PRD_FILE" 2>/dev/null && [ -f "$LAST_BRANCH_FILE" ]; then
  CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
  LAST_BRANCH=$(cat "$LAST_BRANCH_FILE" 2>/dev/null || echo "")
  
  if [ -n "$CURRENT_BRANCH" ] && [ -n "$LAST_BRANCH" ] && [ "$CURRENT_BRANCH" != "$LAST_BRANCH" ]; then
    # Archive the previous run
    DATE=$(date +%Y-%m-%d)
    # Strip "ralph/" prefix from branch name for folder
    FOLDER_NAME=${LAST_BRANCH#ralph/}
    ARCHIVE_FOLDER="$ARCHIVE_DIR/$DATE-$FOLDER_NAME"
    
    echo "Archiving previous run: $LAST_BRANCH"
    mkdir -p "$ARCHIVE_FOLDER"
    [ -f "$PRD_FILE" ] && cp "$PRD_FILE" "$ARCHIVE_FOLDER/"
    [ -f "$PROGRESS_FILE" ] && cp "$PROGRESS_FILE" "$ARCHIVE_FOLDER/"
    [ -f "$OUTPUT_LOG" ] && cp "$OUTPUT_LOG" "$ARCHIVE_FOLDER/"
    echo "   Archived to: $ARCHIVE_FOLDER"

    # Reset files for new run
    echo "# Ralph Progress Log" > "$PROGRESS_FILE"
    echo "Started: $(date)" >> "$PROGRESS_FILE"
    echo "---" >> "$PROGRESS_FILE"

    # Reset output log for new run
    echo "# Ralph Output Log - $(date)" > "$OUTPUT_LOG"
    echo "---" >> "$OUTPUT_LOG"
  fi
fi

# Track current branch
if [ -f "$PRD_FILE" ]; then
  CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
  if [ -n "$CURRENT_BRANCH" ]; then
    echo "$CURRENT_BRANCH" > "$LAST_BRANCH_FILE"
  fi
fi

# Validate PRD exists and is valid JSON
if [ ! -f "$PRD_FILE" ]; then
  echo "Error: PRD file not found at $PRD_FILE"
  echo "Create a prd.json file or specify a different project directory."
  exit 1
fi

if ! jq empty "$PRD_FILE" 2>/dev/null; then
  echo "Error: $PRD_FILE is not valid JSON"
  exit 1
fi

# Initialize progress file if it doesn't exist
if [ ! -f "$PROGRESS_FILE" ]; then
  echo "# Ralph Progress Log" > "$PROGRESS_FILE"
  echo "Started: $(date)" >> "$PROGRESS_FILE"
  echo "---" >> "$PROGRESS_FILE"
fi

# Initialize output log if it doesn't exist
if [ ! -f "$OUTPUT_LOG" ]; then
  echo "# Ralph Output Log - $(date)" > "$OUTPUT_LOG"
  echo "---" >> "$OUTPUT_LOG"
fi

echo "Starting Ralph (Claude Code)"
echo "  Project:    $PROJECT_DIR"
echo "  PRD:        $PRD_FILE"
echo "  Iterations: $MAX_ITERATIONS"
echo "  Output log: $OUTPUT_LOG"

for i in $(seq 1 "$MAX_ITERATIONS"); do
  echo ""
  echo "═══════════════════════════════════════════════════════"
  echo "  Ralph Iteration $i of $MAX_ITERATIONS"
  echo "═══════════════════════════════════════════════════════"
  
  # Log iteration start
  {
    echo ""
    echo "═══════════════════════════════════════════════════════"
    echo "  Iteration $i of $MAX_ITERATIONS - $(date)"
    echo "═══════════════════════════════════════════════════════"
  } >> "$OUTPUT_LOG"

  # Run Claude Code CLI with the ralph prompt
  # --print: non-interactive mode
  # --dangerously-skip-permissions: equivalent to amp's --dangerously-allow-all
  # Run from PROJECT_DIR so Claude has correct working directory context
  # Output is logged to both stderr (terminal) and the output log file
  OUTPUT=$(cd "$PROJECT_DIR" && claude --print --dangerously-skip-permissions < "$SCRIPT_DIR/prompt.md" 2>&1 | tee -a "$OUTPUT_LOG" | tee /dev/stderr) || true
  
  # Check for completion signal
  if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
    echo ""
    echo "Ralph completed all tasks!"
    echo "Completed at iteration $i of $MAX_ITERATIONS"
    exit 0
  fi
  
  echo "Iteration $i complete. Continuing..."
  sleep 2
done

echo ""
echo "Ralph reached max iterations ($MAX_ITERATIONS) without completing all tasks."
echo "Check $PROGRESS_FILE for status."
exit 1
