#!/bin/bash
set -e

# --- Core Paths ---
AIDER_DIR="$HOME/.aider"
PROMPTS_DIR="$AIDER_DIR/prompts"

# --- Default Parameters (Cleaned from flat file layout constraints)
ROLE="aqa-tatar"
PROMPT_FILE="$PROMPTS_DIR/default.md"

# --- Help Menu Utility ---
usage() {
  echo "Usage: aider-run [options] [-- aider_arguments]"
  echo "Options:"
  echo "  -r, --role <name>      Target role token for dynamic Qdrant RAG hydration (Default: aqa-tatar)"
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

# --- Immediate Task Verification ---
if [ ! -f "$PROMPT_FILE" ]; then
  echo -e "\e[31m[ERROR] Targeted prompt file '$PROMPT_FILE' does not exist\e[0m"
  exit 1
fi

# --- Dynamic Context Assembly (Pure Token-Trigger Passing) ---
TEMP_INSTRUCTION=$(mktemp)

{
  # Fire the unified identity hydration token.
  # This string triggers the C++ engine to pull the complete persona out of Qdrant via FastMCP
  echo "[MARKER HYDRATE] $ROLE"
  echo -e "\n"

  # Append only the immediate isolated project task
  echo "# IMMEDIATE SESSION TASK"
  cat "$PROMPT_FILE"
} >> "$TEMP_INSTRUCTION"

# --- Session Runtime Diagnostics ---
echo -e "\e[32m>>> Spawning Independent AI Runtime Session...\e[0m"
echo -e "    |-- Hydration Key:  $ROLE (Resolving via Qdrant FastMCP)"
echo -e "    |-- Target Prompt:  $(basename "$PROMPT_FILE")"
echo -e "    |-- Vector RAG:     Active (On-Demand Context Layering)"

# --- Execution Engine Start ---
aider --message-file "$TEMP_INSTRUCTION" "${POSITIONAL_ARGS[@]}"

# --- Workspace Cleanup ---
rm -f "$TEMP_INSTRUCTION"
