#!/bin/bash
# .\Aider\aider_run.sh - Isolated Guest CLI Execution Wrapper
# Style Enforced: Spaces 2, LF, Pure Vector RAG Mode Alignment
set -e

# --- Core Paths ---
AIDER_DIR="$HOME/.aider"
LOG_DIR="$AIDER_DIR/log"

# --- Default Parameters ---
ROLE="AI-AQA"
PROMPT_FILE=""
CONFIG_FILE="$AIDER_DIR/aider.conf.yml"

# --- Help Menu Utility ---
usage() {
  echo "Usage: aider-run [options] [-- aider_arguments]"
  echo "Options:"
  echo "  -r, --role <name>      Target role token for dynamic Qdrant RAG hydration (Default: AI-AQA)"
  echo "  -m, --message <path>   Path to custom task prompt file (Optional)"
  echo "  -c, --config <path>    Path to specific Aider configuration file (Default: aider.conf.yml)"
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
    -c|--config)
      CONFIG_FILE="$2"
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

# --- Operational Directory Layout Assertions ---
mkdir -p "$LOG_DIR"

# --- Runtime Input Verifications ---
if [ ! -f "$CONFIG_FILE" ]; then
  echo -e "\e[31m[ERROR] Target configuration file '$CONFIG_FILE' does not exist\e[0m"
  exit 1
fi

if [ -n "$PROMPT_FILE" ] && [ ! -f "$PROMPT_FILE" ]; then
  echo -e "\e[31m[ERROR] Targeted prompt file '$PROMPT_FILE' does not exist\e[0m"
  exit 1
fi

# --- Dynamic Context Assembly (Pure Token-Trigger Passing) ---
TEMP_INSTRUCTION=$(mktemp)

{
  # Fire the unified identity hydration token.
  echo "HYDRATE $ROLE"
  echo -e "\n"

  # Append immediate isolated project task only if explicitly provided via CLI
  if [ -n "$PROMPT_FILE" ]; then
    echo "# IMMEDIATE SESSION TASK"
    cat "$PROMPT_FILE"
  fi
} >> "$TEMP_INSTRUCTION"

# --- Session Runtime Diagnostics ---
echo -e "\e[32m>>> Spawning Independent AI Runtime Session...\e[0m"
echo -e "    |-- Hydration Key:  $ROLE (Resolving via Qdrant FastMCP)"
echo -e "    |-- Target Config:  $(basename "$CONFIG_FILE")"
if [ -n "$PROMPT_FILE" ]; then
  echo -e "    |-- Target Prompt:  $(basename "$PROMPT_FILE")"
else
  echo -e "    |-- Target Prompt:  None (Interactive Chat Mode)"
fi
echo -e "    |-- Vector RAG:     Active (On-Demand Context Layering)"

# --- Compile Telemetry Log Boundary File Path ---
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
SESSION_LOG="$LOG_DIR/aider_$TIMESTAMP.log"

# --- Execution Engine Start (Direct Config Injection & Logging Enforced) ---
# Redirecting stderr and piping through tee ensures real-time TTY feedback and cold telemetry logging
aider --config "$CONFIG_FILE" --message-file "$TEMP_INSTRUCTION" "${POSITIONAL_ARGS[@]}" 2>&1 | tee -a "$SESSION_LOG"

# --- Workspace Cleanup ---
rm -f "$TEMP_INSTRUCTION"
