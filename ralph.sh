#!/bin/bash
# Ralph - Long-running AI agent loop for Claude Code CLI
# Run ./ralph.sh help for usage information

VERSION="1.1.0"

set -e

# Detect platform for install instructions
detect_platform() {
  case "$(uname -s)" in
    Darwin*) echo "macos" ;;
    Linux*)  echo "linux" ;;
    MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
    *)       echo "unknown" ;;
  esac
}

# Get install command for a tool based on platform
get_install_cmd() {
  local tool="$1"
  local platform
  platform=$(detect_platform)

  case "$tool" in
    jq)
      case "$platform" in
        macos)   echo "brew install jq" ;;
        linux)   echo "sudo apt install jq  # or: sudo dnf install jq" ;;
        *)       echo "See: https://jqlang.github.io/jq/download/" ;;
      esac
      ;;
    gh)
      case "$platform" in
        macos)   echo "brew install gh" ;;
        linux)   echo "See: https://github.com/cli/cli/blob/trunk/docs/install_linux.md" ;;
        *)       echo "See: https://cli.github.com/" ;;
      esac
      ;;
    claude)
      echo "See: https://docs.anthropic.com/en/docs/claude-code"
      ;;
    git)
      case "$platform" in
        macos)   echo "brew install git  # or: xcode-select --install" ;;
        linux)   echo "sudo apt install git  # or: sudo dnf install git" ;;
        *)       echo "See: https://git-scm.com/downloads" ;;
      esac
      ;;
    bash)
      case "$platform" in
        macos)   echo "brew install bash" ;;
        linux)   echo "sudo apt install bash  # or: sudo dnf install bash" ;;
        *)       echo "See: https://www.gnu.org/software/bash/" ;;
      esac
      ;;
  esac
}

# Compare version strings (returns 0 if $1 >= $2, 1 otherwise)
version_gte() {
  local v1="$1"
  local v2="$2"
  # Use sort -V if available, fall back to basic comparison
  if printf '%s\n%s\n' "$v2" "$v1" | sort -V 2>/dev/null | head -1 | grep -qF "$v2"; then
    return 0
  fi
  # Fallback: simple numeric comparison of major.minor
  local v1_major v1_minor v2_major v2_minor
  v1_major=$(echo "$v1" | cut -d. -f1)
  v1_minor=$(echo "$v1" | cut -d. -f2)
  v2_major=$(echo "$v2" | cut -d. -f1)
  v2_minor=$(echo "$v2" | cut -d. -f2)

  if [ "$v1_major" -gt "$v2_major" ] 2>/dev/null; then
    return 0
  elif [ "$v1_major" -eq "$v2_major" ] 2>/dev/null && [ "$v1_minor" -ge "$v2_minor" ] 2>/dev/null; then
    return 0
  fi
  return 1
}

# Get tool version (returns version string or empty)
get_version() {
  local tool="$1"
  case "$tool" in
    jq)
      jq --version 2>/dev/null | sed 's/jq-//' | head -1
      ;;
    gh)
      gh --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1
      ;;
    claude)
      # Claude CLI version format varies; try to extract version number
      claude --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || \
      claude --version 2>/dev/null | head -1
      ;;
    git)
      git --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1
      ;;
    bash)
      bash --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1
      ;;
  esac
}

# Check a single dependency with version requirement
check_dep() {
  local tool="$1"
  local min_version="$2"
  local required="${3:-true}"

  # Check if command exists
  if ! command -v "$tool" >/dev/null 2>&1; then
    if [ "$required" = "true" ]; then
      echo "✗ $tool: NOT INSTALLED"
      echo "  Install: $(get_install_cmd "$tool")"
      return 1
    else
      echo "○ $tool: not installed (optional)"
      return 0
    fi
  fi

  # Get current version
  local current_version
  current_version=$(get_version "$tool")

  if [ -z "$current_version" ]; then
    echo "✓ $tool: installed (version unknown)"
    return 0
  fi

  # Check version if minimum specified
  if [ -n "$min_version" ]; then
    if version_gte "$current_version" "$min_version"; then
      echo "✓ $tool: $current_version (>= $min_version required)"
      return 0
    else
      echo "✗ $tool: $current_version (>= $min_version required)"
      echo "  Upgrade: $(get_install_cmd "$tool")"
      return 1
    fi
  else
    echo "✓ $tool: $current_version"
    return 0
  fi
}

# Special check for bash (3.2+ works, 4.0+ recommended)
check_dep_bash() {
  if ! command -v bash >/dev/null 2>&1; then
    echo "✗ bash: NOT INSTALLED"
    echo "  Install: $(get_install_cmd bash)"
    return 1
  fi

  local current_version
  current_version=$(get_version bash)

  if [ -z "$current_version" ]; then
    echo "✓ bash: installed (version unknown)"
    return 0
  fi

  # Must be at least 3.2
  if ! version_gte "$current_version" "3.2"; then
    echo "✗ bash: $current_version (>= 3.2 required)"
    echo "  Upgrade: $(get_install_cmd bash)"
    return 1
  fi

  # Warn if under 4.0 but don't fail
  if version_gte "$current_version" "4.0"; then
    echo "✓ bash: $current_version (>= 4.0 recommended)"
  else
    echo "⚠ bash: $current_version (works, but 4.0+ recommended)"
    echo "  Upgrade: $(get_install_cmd bash)"
  fi
  return 0
}

# Check GitHub authentication
check_gh_auth() {
  if gh auth status >/dev/null 2>&1; then
    local user
    user=$(gh api user -q '.login' 2>/dev/null || echo "authenticated")
    echo "✓ gh auth: logged in as $user"
    return 0
  else
    echo "✗ gh auth: NOT AUTHENTICATED"
    echo "  Run: gh auth login"
    return 1
  fi
}

# Check Claude CLI authentication
check_claude_auth() {
  # Try to run a simple claude command to verify auth
  # Using 'claude --version' doesn't check auth, so we try a minimal prompt
  if claude --version >/dev/null 2>&1; then
    # Claude is installed; we can't easily verify auth without running a prompt
    # Check if there's a config file or auth indicator
    local config_dir="$HOME/.claude"
    if [ -d "$config_dir" ]; then
      echo "✓ claude auth: configured (config directory exists)"
      return 0
    else
      echo "⚠ claude auth: not configured (run 'claude' to authenticate)"
      echo "  Visit: https://docs.anthropic.com/en/docs/claude-code"
      return 0  # Don't fail - user may authenticate on first run
    fi
  else
    echo "✗ claude: NOT INSTALLED"
    echo "  Install: $(get_install_cmd claude)"
    return 1
  fi
}

# Check plugin directory structure
check_plugin_structure() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local plugin_dir="$script_dir/.claude-plugin"
  local has_issues=0

  # Check plugin.json exists
  if [ -f "$plugin_dir/plugin.json" ]; then
    if jq empty "$plugin_dir/plugin.json" 2>/dev/null; then
      local version
      version=$(jq -r '.version // "unknown"' "$plugin_dir/plugin.json")
      echo "✓ plugin.json: valid (v$version)"
    else
      echo "✗ plugin.json: invalid JSON"
      has_issues=1
    fi
  else
    echo "✗ plugin.json: NOT FOUND"
    echo "  Expected at: $plugin_dir/plugin.json"
    has_issues=1
  fi

  # Check skills directory exists and count skills
  local skills_dir="$plugin_dir/skills"
  if [ -d "$skills_dir" ]; then
    local skill_count
    skill_count=$(find "$skills_dir" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    if [ "$skill_count" -gt 0 ]; then
      echo "✓ skills/: $skill_count skill(s) found"
    else
      echo "⚠ skills/: directory exists but no skills found"
      has_issues=1
    fi
  else
    echo "✗ skills/: directory NOT FOUND"
    echo "  Expected at: $skills_dir"
    has_issues=1
  fi

  # Check essential files exist
  if [ -f "$script_dir/prompt.md" ]; then
    echo "✓ prompt.md: found"
  else
    echo "✗ prompt.md: NOT FOUND"
    echo "  Expected at: $script_dir/prompt.md"
    has_issues=1
  fi

  return $has_issues
}

# Full dependency check with detailed output
check_deps() {
  local verbose="${1:-false}"
  local has_errors=0

  echo ""
  echo "╔═══════════════════════════════════════════════════════╗"
  echo "║           Ralph Installation Verification             ║"
  echo "╚═══════════════════════════════════════════════════════╝"
  echo ""
  echo "  Checking required dependencies..."
  echo ""

  # Required dependencies with minimum versions
  # Note: bash 3.2+ works, but 4.0+ is recommended
  check_dep_bash || has_errors=1
  check_dep "git" "2.0" "true" || has_errors=1
  check_dep "jq" "1.6" "true" || has_errors=1
  check_dep "gh" "2.0" "true" || has_errors=1
  check_dep "claude" "" "true" || has_errors=1

  echo ""
  echo "  Checking authentication..."
  echo ""

  check_gh_auth || has_errors=1
  check_claude_auth || has_errors=1

  echo ""
  echo "  Checking Ralph installation..."
  echo ""

  check_plugin_structure || has_errors=1

  if [ "$verbose" = "true" ]; then
    echo ""
    echo "  Platform: $(detect_platform)"
    echo "  Shell: $SHELL"
    echo "  Ralph location: $(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  fi

  echo ""
  if [ "$has_errors" -eq 0 ]; then
    echo "  ────────────────────────────────────────────────────"
    echo "  ✓ All checks passed! Ralph is ready to use."
    echo "  ────────────────────────────────────────────────────"
    echo ""
    echo "  Next steps:"
    echo "    1. Create a prd.json in your project directory"
    echo "    2. Run: ./ralph.sh <project-dir>"
    echo ""
    echo "  Or generate a PRD from GitHub issues:"
    echo "    ./ralph.sh --from-issues <project-dir> --label bug"
    echo ""
  else
    echo "  ────────────────────────────────────────────────────"
    echo "  ✗ Some checks failed (see above)"
    echo "  ────────────────────────────────────────────────────"
    echo ""
    echo "  Fix the issues above and run --check-deps again."
    echo ""
  fi

  return $has_errors
}

# Quick dependency check (for normal runs - minimal output)
quick_check_deps() {
  local errors=""

  # Check jq
  if ! command -v jq >/dev/null 2>&1; then
    errors="$errors\nError: jq is required but not installed.\n  Install: $(get_install_cmd jq)"
  else
    local jq_ver
    jq_ver=$(get_version jq)
    if [ -n "$jq_ver" ] && ! version_gte "$jq_ver" "1.6"; then
      errors="$errors\nError: jq $jq_ver is too old (>= 1.6 required).\n  Upgrade: $(get_install_cmd jq)"
    fi
  fi

  # Check gh
  if ! command -v gh >/dev/null 2>&1; then
    errors="$errors\nError: gh (GitHub CLI) is required but not installed.\n  Install: $(get_install_cmd gh)"
  else
    local gh_ver
    gh_ver=$(get_version gh)
    if [ -n "$gh_ver" ] && ! version_gte "$gh_ver" "2.0"; then
      errors="$errors\nError: gh $gh_ver is too old (>= 2.0 required).\n  Upgrade: $(get_install_cmd gh)"
    fi
  fi

  # Check claude
  if ! command -v claude >/dev/null 2>&1; then
    errors="$errors\nError: claude CLI is required but not installed.\n  Install: $(get_install_cmd claude)"
  fi

  # Check git
  if ! command -v git >/dev/null 2>&1; then
    errors="$errors\nError: git is required but not installed.\n  Install: $(get_install_cmd git)"
  fi

  # Print any errors and exit
  if [ -n "$errors" ]; then
    echo -e "$errors"
    echo ""
    echo "Run './ralph.sh --check-deps' for detailed dependency information."
    exit 1
  fi

  # Check GitHub authentication
  if ! gh auth status >/dev/null 2>&1; then
    echo "Error: GitHub CLI is not authenticated."
    echo "Run: gh auth login"
    exit 1
  fi
}

# Handle version command (before dependency checks so it always works)
if [ "$1" = "--version" ] || [ "$1" = "-v" ]; then
  echo "Ralph v$VERSION"
  exit 0
fi

# Handle --check-deps command
if [ "$1" = "--check-deps" ] || [ "$1" = "check-deps" ]; then
  if check_deps "true"; then
    exit 0
  else
    exit 1
  fi
fi

# Quick dependency check for normal operation
quick_check_deps

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

# Dry-run command function
show_dry_run() {
  local project_dir="$1"
  local prd_file="$project_dir/prd.json"

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
  local mode=$(jq -r '.mode // "feature"' "$prd_file")
  local base_branch=$(jq -r '.baseBranch // "main"' "$prd_file")
  local branch_name=$(jq -r '.branchName // "N/A"' "$prd_file")
  local description=$(jq -r '.description // "No description"' "$prd_file")

  # Count stories by status
  local total=$(jq '.userStories | length' "$prd_file")
  local completed=$(jq '[.userStories[] | select(.passes == true)] | length' "$prd_file")
  local incomplete=$(jq '[.userStories[] | select(.passes == false)] | length' "$prd_file")

  # Count eligible (no unmet dependencies) vs blocked stories
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

  echo ""
  echo "╔═══════════════════════════════════════════════════════╗"
  echo "║                  Ralph Dry Run                        ║"
  echo "╚═══════════════════════════════════════════════════════╝"
  echo ""
  echo "  Project:     $project_name"
  echo "  Description: $description"
  echo "  Mode:        $mode"
  if [ "$mode" = "backlog" ]; then
    echo "  Base branch: $base_branch"
  else
    echo "  Branch:      $branch_name"
  fi
  echo "  Location:    $project_dir"
  echo ""
  echo "  Stories:     $total total"
  echo "               $completed completed"
  echo "               $eligible eligible (ready to implement)"
  if [ "$blocked" -gt 0 ]; then
    echo "               $blocked blocked by dependencies"
  fi
  echo ""
  echo "  Story List:"
  echo "  ────────────────────────────────────────────────────"

  jq -r '
    .userStories as $all |
    .userStories[] |
    . as $story |
    (
      if .passes == true then "✓ PASS"
      elif (.dependsOn == null) or (.dependsOn | length == 0) then "○ ELIGIBLE"
      elif ((.dependsOn // []) | all(. as $dep | $all | map(select(.id == $dep and .passes == true)) | length > 0)) then "○ ELIGIBLE"
      else "⊘ BLOCKED"
      end
    ) as $status |
    "  \($status | .[0:10])  \(.id): \(.title)"
  ' "$prd_file"

  echo ""
  echo "  Legend: ✓ PASS = completed  ○ ELIGIBLE = ready  ⊘ BLOCKED = waiting"
  echo ""

  # Show what would happen next
  if [ "$eligible" -gt 0 ]; then
    echo "  Next Action:"
    echo "  ────────────────────────────────────────────────────"
    local next_story=$(jq -r '
      .userStories as $all |
      [.userStories[] | select(
        .passes == false and
        (
          (.dependsOn == null) or
          (.dependsOn | length == 0) or
          ((.dependsOn // []) | all(. as $dep | $all | map(select(.id == $dep and .passes == true)) | length > 0))
        )
      )] | sort_by(.priority) | .[0] | "\(.id): \(.title)"
    ' "$prd_file")
    echo "  Would implement: $next_story"
    if [ "$mode" = "backlog" ]; then
      local next_issue=$(jq -r '
        .userStories as $all |
        [.userStories[] | select(
          .passes == false and
          (
            (.dependsOn == null) or
            (.dependsOn | length == 0) or
            ((.dependsOn // []) | all(. as $dep | $all | map(select(.id == $dep and .passes == true)) | length > 0))
          )
        )] | sort_by(.priority) | .[0] | .githubIssue // empty
      ' "$prd_file")
      if [ -n "$next_issue" ]; then
        echo "  Would create branch: ralph/issue-$next_issue"
      fi
    fi
    echo ""
  else
    echo "  Next Action:"
    echo "  ────────────────────────────────────────────────────"
    if [ "$completed" -eq "$total" ]; then
      echo "  All stories complete! Would create final PR."
    else
      echo "  No eligible stories. All remaining stories are blocked."
    fi
    echo ""
  fi

  echo "  No changes were made. Run without --dry-run to execute."
  echo ""
}

# From-issues command function - generates PRD from GitHub issues then runs Ralph
run_from_issues() {
  local project_dir="$1"
  shift
  local labels=""
  local repo=""
  local issues=""
  local milestone=""
  local mode="backlog"
  local iterations=10

  # Capture script directory before any cd commands
  local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  # Parse remaining arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      --label|--labels)
        labels="$2"
        shift 2
        ;;
      --repo)
        repo="$2"
        shift 2
        ;;
      --issue|--issues)
        issues="$2"
        shift 2
        ;;
      --milestone)
        milestone="$2"
        shift 2
        ;;
      --mode)
        mode="$2"
        shift 2
        ;;
      [0-9]*)
        iterations="$1"
        shift
        ;;
      *)
        shift
        ;;
    esac
  done

  echo ""
  echo "╔═══════════════════════════════════════════════════════╗"
  echo "║            Ralph - From Issues Mode                   ║"
  echo "╚═══════════════════════════════════════════════════════╝"
  echo ""
  echo "  Project:    $project_dir"

  # Auto-detect repo if not specified
  if [ -z "$repo" ]; then
    repo=$(cd "$project_dir" && gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null || echo "")
    if [ -z "$repo" ]; then
      echo "Error: Could not detect GitHub repo. Use --repo owner/repo"
      exit 1
    fi
  fi
  echo "  Repository: $repo"

  if [ -n "$issues" ]; then
    echo "  Issues:     $issues"
  fi

  if [ -n "$labels" ]; then
    echo "  Labels:     $labels"
  fi

  if [ -n "$milestone" ]; then
    echo "  Milestone:  $milestone"
  fi

  echo "  Mode:       $mode"
  echo "  Iterations: $iterations"
  echo ""
  echo "  Step 1: Fetching GitHub issues..."

  # Build gh issue list command
  local gh_cmd="gh issue list --repo $repo --state open --json number,title,body,labels"

  if [ -n "$issues" ]; then
    # Fetch specific issues one by one
    local issue_data="[]"
    IFS=',' read -ra ISSUE_ARRAY <<< "$issues"
    for issue_num in "${ISSUE_ARRAY[@]}"; do
      local single=$(gh issue view "$issue_num" --repo "$repo" --json number,title,body,labels 2>/dev/null || echo "")
      if [ -n "$single" ]; then
        issue_data=$(echo "$issue_data" | jq --argjson item "$single" '. + [$item]')
      fi
    done
    ISSUES_JSON="$issue_data"
  else
    # Fetch by label or milestone
    if [ -n "$labels" ]; then
      IFS=',' read -ra LABEL_ARRAY <<< "$labels"
      for label in "${LABEL_ARRAY[@]}"; do
        gh_cmd="$gh_cmd --label $label"
      done
    fi
    if [ -n "$milestone" ]; then
      gh_cmd="$gh_cmd --milestone $milestone"
    fi
    gh_cmd="$gh_cmd --limit 20"
    ISSUES_JSON=$($gh_cmd 2>/dev/null || echo "[]")
  fi

  local issue_count=$(echo "$ISSUES_JSON" | jq 'length')

  if [ "$issue_count" -eq 0 ]; then
    echo ""
    echo "  No open issues found matching criteria."
    echo "  Nothing to do."
    exit 0
  fi

  echo "  Found $issue_count issue(s)"
  echo ""
  echo "  Step 2: Generating PRD..."

  # Generate prd.json from issues
  local project_name=$(basename "$project_dir")
  echo "$ISSUES_JSON" | jq --arg project "$project_name" --arg repo "$repo" --arg mode "$mode" '{
    project: $project,
    mode: $mode,
    baseBranch: "main",
    description: "Auto-generated PRD from GitHub issues",
    githubRepo: $repo,
    githubIssues: [.[].number],
    plugins: { recommended: ["commit-commands"], optional: [] },
    userStories: [to_entries[] | {
      id: ("GH-" + (.value.number | tostring) + "-1"),
      githubIssue: .value.number,
      title: .value.title,
      description: (.value.body // "No description provided" | split("\n")[0:5] | join("\n")),
      acceptanceCriteria: ["Implementation resolves issue #\(.value.number)", "All tests pass", "Code follows project conventions"],
      files: [],
      dependsOn: [],
      priority: (.key + 1),
      passes: false,
      notes: ""
    }]
  }' > "$project_dir/prd.json"

  # Check if prd.json was created
  if [ ! -f "$project_dir/prd.json" ]; then
    echo ""
    echo "Error: prd.json was not created."
    exit 1
  fi

  echo "  Created prd.json with $issue_count stories"
  echo ""
  echo "  Stories:"
  jq -r '.userStories[] | "    - \(.id): \(.title)"' "$project_dir/prd.json"
  echo ""

  # Now run the normal Ralph loop by re-executing ourselves
  exec "$script_dir/ralph.sh" "$project_dir" "$iterations"
}

# Help command function
show_help() {
  cat << 'EOF'

  ╦═╗┌─┐┬  ┌─┐┬ ┬
  ╠╦╝├─┤│  ├─┘├─┤
  ╩╚═┴ ┴┴─┘┴  ┴ ┴
  Autonomous AI Agent Loop

USAGE
  ./ralph.sh <project> [iterations]    Run Ralph on a project
  ./ralph.sh --from-issues <project>   Generate PRD from issues, then run
  ./ralph.sh status <project>          Check PRD progress
  ./ralph.sh --dry-run <project>       Preview what Ralph would do
  ./ralph.sh --check-deps              Verify installation is complete
  ./ralph.sh help                      Show this help message
  ./ralph.sh --version                 Show version information

VERIFICATION
  The --check-deps command verifies:
    - Required tools: bash, git, jq, gh, claude
    - Minimum versions: git 2.0+, jq 1.6+, gh 2.0+, bash 3.2+
    - GitHub CLI authentication (gh auth status)
    - Claude CLI configuration (~/.claude directory)
    - Ralph plugin structure (plugin.json, skills/, prompt.md)

ARGUMENTS
  <project>      Path to project directory containing prd.json
  [iterations]   Max iterations to run (default: 10)

FROM-ISSUES OPTIONS
  --label <labels>      Filter issues by label (comma-separated)
  --issue <numbers>     Specific issues to process (comma-separated)
  --milestone <name>    Filter issues by milestone
  --repo <owner/repo>   GitHub repository (auto-detected if not specified)
  --mode <mode>         PRD mode: feature or backlog (default: backlog)

EXAMPLES
  ./ralph.sh ~/Projects/my-app              Run with existing prd.json
  ./ralph.sh ~/Projects/my-app 20           Run with 20 iterations
  ./ralph.sh status ~/Projects/my-app       Check progress
  ./ralph.sh --dry-run ~/Projects/app       Preview without executing

  # From-issues examples (auto-generate PRD then run):
  ./ralph.sh --from-issues ~/Projects/app --label bug
  ./ralph.sh --from-issues ~/Projects/app --label bug,feature 20
  ./ralph.sh --from-issues ~/Projects/app --issue 13,14,15
  ./ralph.sh --from-issues ~/Projects/app --milestone v2.0

SKILLS (run with Claude Code in your project directory)
  claude /prd "feature description"    Create PRD interactively
  claude /review-issues --issue 42     Generate PRD from GitHub issues
  claude /review-prs --auto-merge      Review and merge pull requests

WORKFLOW
  # Manual workflow:
  1. Create PRD    claude /review-issues --issue 42
  2. Run Ralph     ./ralph.sh ~/Projects/my-app
  3. Merge PRs     claude /review-prs --auto-merge

  # Automated workflow:
  ./ralph.sh --from-issues ~/Projects/app --label bug,feature

MODES (set in prd.json or via --mode)
  "feature"   Single branch, one PR at end (default for /prd)
  "backlog"   Branch per story, PR after each (default for --from-issues)

MORE INFO
  https://github.com/thecgaigroup/ralph-cc-loop

EOF
}

# Handle help command
if [ "$1" = "help" ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  show_help
  exit 0
fi

# Handle --from-issues command
if [ "$1" = "--from-issues" ]; then
  shift
  if [ -n "$1" ] && [ -d "$1" ]; then
    FROM_ISSUES_DIR="$(cd "$1" && pwd)"
    shift
  else
    FROM_ISSUES_DIR="$(pwd)"
  fi
  run_from_issues "$FROM_ISSUES_DIR" "$@"
  exit 0
fi

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

# Handle dry-run command
if [ "$1" = "--dry-run" ]; then
  if [ -n "$2" ] && [ -d "$2" ]; then
    DRYRUN_DIR="$(cd "$2" && pwd)"
  else
    DRYRUN_DIR="$(pwd)"
  fi
  show_dry_run "$DRYRUN_DIR"
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
