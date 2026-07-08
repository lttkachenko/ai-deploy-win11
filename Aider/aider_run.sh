#!/bin/bash
set -e

# --- Core Paths ---
AIDER_DIR="$HOME/.aider"
ROLES_DIR="$AIDER_DIR/roles"
USER_DIR="$AIDER_DIR/user"
PROMPTS_DIR="$AIDER_DIR/prompts"

# --- Default Parameters ---
ROLE="aqa-tatar"
USER_PROFILE="default"
PROMPT_FILE="$PROMPTS_DIR/default.md"

# --- Help Menu Utility ---
usage() {
  echo "Usage: aider-run [options] [-- aider_arguments]"
  echo "Options:"
  echo "  -r, --role <name>      Role profile name from /roles (Default: aqa-tatar)"
  echo "  -u, --user <profile>   User profile filename from /user (Default: default)"
  echo "  -m, --message <path>   Path to custom task prompt file (Fallback: prompts/default.md)"
  echo "  -h, --help             Display this help message"
  exit 0
}

# --- CLI Flags Parsing ---
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    -r|--role)
      ROLE="$2"
      shift 2
      ;;
    -u|--user)
      USER_PROFILE="$2"
      shift 2
      ;;
    -m|--message)
      PROMPT_FILE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    --)
      shift
      POSITIONAL_ARGS+=("$@")
      break
      ;;
    *)
      POSITIONAL_ARGS+=("$1")
      shift
      ;;
  esac
done

# --- Infrastructure Components Validation ---
ROLE_FILE="$ROLES_DIR/$ROLE.md"
if [ ! -f "$ROLE_FILE" ]; then
  echo -e "\e[31m[ERROR] Role profile '$ROLE' not found in $ROLES_DIR\e[0m"
  exit 1
fi

USER_FILE="$USER_DIR/$USER_PROFILE.md"
if [ ! -f "$USER_FILE" ]; then
  # Fallback to look for any .md file in user folder if 'default' is missing
  USER_FILE=$(find "$USER_DIR" -maxdepth 1 -name "*.md" | head -n 1)
  if [ -z "$USER_FILE" ]; then
    echo -e "\e[31m[ERROR] No valid user profile found in $USER_DIR\e[0m"
    exit 1
  fi
fi

if [ ! -f "$PROMPT_FILE" ]; then
  echo -e "\e[31m[ERROR] Targeted prompt file '$PROMPT_FILE' does not exist\e[0m"
  exit 1
fi

# --- Dynamic Context Assembly (Prompt Stitching via Consolidated Stream) ---
TEMP_INSTRUCTION=$(mktemp)

{
  # Layer 1: Inject Selected Base Role Persona
  echo "# ACTIVE AI PERSONA"
  cat "$ROLE_FILE"
  echo -e "\n\n"

  # Layer 2: Inject Global User Profile Constraints & Rules
  echo "# SYSTEM USER PROFILE & CONSTRAINTS"
  cat "$USER_FILE"
  echo -e "\n\n"

  # Layer 3: Append Immediate Task Prompt
  echo "# IMMEDIATE SESSION TASK"
  cat "$PROMPT_FILE"
} >> "$TEMP_INSTRUCTION"

# --- Session Runtime Diagnostics ---
echo -e "\e[32m>>> Spawning Independent AI Runtime Session...\e[0m"
echo -e "    |-- Active Persona: $ROLE"
echo -e "    |-- User Profile:   $(basename "$USER_FILE")"
echo -e "    |-- Target Prompt:  $(basename "$PROMPT_FILE")"
echo -e "    |-- Vector RAG:     Active via FastMCP Bridge"

# --- Execution Engine Start ---
aider --message-file "$TEMP_INSTRUCTION" "${POSITIONAL_ARGS[@]}"

# --- Workspace Cleanup ---
rm -f "$TEMP_INSTRUCTION"
