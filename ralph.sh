#!/bin/bash
# Ralph - Long-running AI agent loop for Claude Code CLI
# Usage: ./ralph.sh [project_dir] [max_iterations]
#        ./ralph.sh status [project_dir]
#
# Examples:
#   ./ralph.sh                     # Run in current directory, 10 iterations
#   ./ralph.sh 20                  # Run in current directory, 20 iterations
#   ./ralph.sh ~/Projects/my-app   # Run against my-app, 10 iterations
#   ./ralph.sh ~/Projects/my-app 20 # Run against my-app, 20 iterations
#   ./ralph.sh status              # Show status for current directory
#   ./ralph.sh status ~/Projects/my-app  # Show status for my-app
#
# Modes (set in prd.json):
#   "mode": "feature"  - Single branch, one PR at end (default)
#   "mode": "backlog"  - Branch per story/issue, PR after each

set -e

# Check dependencies
command -v jq >/dev/null 2>&1 || { echo "Error: jq is required but not installed. Run: brew install jq"; exit 1; }
command -v claude >/dev/null 2>&1 || { echo "Error: claude CLI is required but not installed. See: https://docs.anthropic.com/claude-code"; exit 1; }
command -v gh >/dev/null 2>&1 || { echo "Error: gh (GitHub CLI) is required but not installed. Run: brew install gh"; exit 1; }

# Check GitHub authentication
if ! gh auth status >/dev/null 2>&1; then
  echo "Error: GitHub CLI is not authenticated."
  echo "Run: gh auth login"
  exit 1
fi

# Status command function
show_status() {
  local project_dir="$1"
  local prd_file="$project_dir/prd.json"
  local progress_file="$project_dir/progress.txt"
  local output_log="$project_dir/ralph-output.log"

  if [ ! -f "$prd_file" ]; then
    echo "Error: No prd.json found in $project_dir"
    exit 1
  fi

  if ! jq empty "$prd_file" 2>/dev/null; then
    echo "Error: $prd_file is not valid JSON"
    exit 1
  fi

  # Get project info
  local project_name=$(jq -r '.project // "Unknown"' "$prd_file")
  local branch_name=$(jq -r '.branchName // "Unknown"' "$prd_file")
  local mode=$(jq -r '.mode // "feature"' "$prd_file")

  # Count stories by status
  local total=$(jq '.userStories | length' "$prd_file")
  local completed=$(jq '[.userStories[] | select(.passes == true)] | length' "$prd_file")
  local incomplete=$(jq '[.userStories[] | select(.passes == false)] | length' "$prd_file")

  # Count eligible (no unmet dependencies) vs blocked stories
  # A story is blocked if it has dependsOn and any dependency has passes=false
  local eligible=$(jq '
    .userStories as $all |
    [.userStories[] | select(
      .passes == false and
      (
        (.dependsOn == null) or
        (.dependsOn | length == 0) or
        ((.dependsOn // []) | all(. as $dep | $all | map(select(.id == $dep and .passes == true)) | length > 0))
      )
    )] | length
  ' "$prd_file")
  local blocked=$((incomplete - eligible))

  # Get last run time from output log
  local last_run="Never"
  if [ -f "$output_log" ]; then
    # Look for the most recent iteration timestamp
    last_run=$(grep -o "Iteration [0-9]* of [0-9]* - .*" "$output_log" 2>/dev/null | tail -1 | sed 's/.*- //' || echo "Unknown")
    if [ -z "$last_run" ]; then
      last_run="Unknown"
    fi
  fi

  echo ""
  echo "╔═══════════════════════════════════════════════════════╗"
  echo "║                    Ralph Status                       ║"
  echo "╚═══════════════════════════════════════════════════════╝"
  echo ""
  echo "  Project:  $project_name"
  echo "  Mode:     $mode"
  if [ "$mode" = "backlog" ]; then
    echo "  Base:     $(jq -r '.baseBranch // "main"' "$prd_file")"
  else
    echo "  Branch:   $branch_name"
  fi
  echo "  Location: $project_dir"
  echo ""
  echo "  Stories:  $completed/$total complete"
  if [ "$eligible" -gt 0 ]; then
    echo "            $eligible ready to implement"
  fi
  if [ "$blocked" -gt 0 ]; then
    echo "            $blocked blocked by dependencies"
  fi
  echo ""
  echo "  Last run: $last_run"
  echo ""

  # Show story details
  echo "  Stories:"
  echo "  ────────────────────────────────────────────────────"

  jq -r '
    .userStories as $all |
    .userStories[] |
    . as $story |
    (
      if .passes == true then "✓"
      elif (.dependsOn == null) or (.dependsOn | length == 0) then "○"
      elif ((.dependsOn // []) | all(. as $dep | $all | map(select(.id == $dep and .passes == true)) | length > 0)) then "○"
      else "⊘"
      end
    ) as $status |
    "  \($status) \(.id): \(.title)"
  ' "$prd_file"

  echo ""
  echo "  Legend: ✓ complete  ○ ready  ⊘ blocked"
  echo ""
}

# Handle status command
if [ "$1" = "status" ]; then
  if [ -n "$2" ] && [ -d "$2" ]; then
    STATUS_DIR="$(cd "$2" && pwd)"
  else
    STATUS_DIR="$(pwd)"
  fi
  show_status "$STATUS_DIR"
  exit 0
fi

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
  PREV_PROJECT=$(jq -r '.project // "unknown"' "$PRD_FILE" 2>/dev/null || echo "unknown")

  if [ -n "$CURRENT_BRANCH" ] && [ -n "$LAST_BRANCH" ] && [ "$CURRENT_BRANCH" != "$LAST_BRANCH" ]; then
    # Archive the previous run - organize by project name
    DATE=$(date +%Y-%m-%d)
    # Sanitize project name for folder (replace spaces with dashes, lowercase)
    SAFE_PROJECT=$(echo "$PREV_PROJECT" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd '[:alnum:]-')
    # Strip "ralph/" prefix from branch name for folder
    FOLDER_NAME=${LAST_BRANCH#ralph/}
    ARCHIVE_FOLDER="$ARCHIVE_DIR/$SAFE_PROJECT/$DATE-$FOLDER_NAME"

    echo "Archiving previous run: $LAST_BRANCH"
    mkdir -p "$ARCHIVE_FOLDER"
    [ -f "$PRD_FILE" ] && cp "$PRD_FILE" "$ARCHIVE_FOLDER/"
    [ -f "$PROGRESS_FILE" ] && cp "$PROGRESS_FILE" "$ARCHIVE_FOLDER/"
    [ -f "$OUTPUT_LOG" ] && cp "$OUTPUT_LOG" "$ARCHIVE_FOLDER/"
    echo "   Archived to: $ARCHIVE_FOLDER"

    # Reset files will be done after we read new project name below
    rm -f "$PROGRESS_FILE" "$OUTPUT_LOG"
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

# Get project name from PRD for attribution
PROJECT_NAME=$(jq -r '.project // "Unknown Project"' "$PRD_FILE")

# Initialize progress file if it doesn't exist
if [ ! -f "$PROGRESS_FILE" ]; then
  cat > "$PROGRESS_FILE" << EOF
# Ralph Progress Log
# Project: $PROJECT_NAME
# Location: $PROJECT_DIR
# Started: $(date)
#
# This file is generated and maintained by Ralph.
# See: https://github.com/thecgaigroup/ralph-cc-loop
---
EOF
fi

# Initialize output log if it doesn't exist
if [ ! -f "$OUTPUT_LOG" ]; then
  cat > "$OUTPUT_LOG" << EOF
# Ralph Output Log
# Project: $PROJECT_NAME
# Location: $PROJECT_DIR
# Started: $(date)
#
# This file contains full Claude output from all Ralph iterations.
# See: https://github.com/thecgaigroup/ralph-cc-loop
---
EOF
fi

# Get mode from PRD
MODE=$(jq -r '.mode // "feature"' "$PRD_FILE")

echo "Starting Ralph (Claude Code)"
echo "  Project:    $PROJECT_DIR"
echo "  PRD:        $PRD_FILE"
echo "  Mode:       $MODE"
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
  
  # Check for completion signals
  if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
    echo ""
    echo "═══════════════════════════════════════════════════════"
    echo "  Ralph completed all tasks!"
    echo "  Mode: $MODE"
    echo "  Completed at iteration $i of $MAX_ITERATIONS"
    echo "═══════════════════════════════════════════════════════"
    exit 0
  fi

  if echo "$OUTPUT" | grep -q "<promise>BACKLOG_EMPTY</promise>"; then
    echo ""
    echo "═══════════════════════════════════════════════════════"
    echo "  Backlog empty - no eligible stories remaining"
    echo "  Completed at iteration $i of $MAX_ITERATIONS"
    echo "═══════════════════════════════════════════════════════"
    echo ""
    echo "Add more stories to prd.json and run again, or check"
    echo "if any stories are blocked by unmet dependencies."
    exit 0
  fi

  echo "Iteration $i complete. Continuing..."
  sleep 2
done

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  Ralph reached max iterations ($MAX_ITERATIONS)"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "Check $PROGRESS_FILE for status."
if [ "$MODE" = "backlog" ]; then
  echo "Run again to continue processing the backlog."
fi
exit 1
