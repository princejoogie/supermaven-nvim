# Get absolute path of script directory
PLUGIN_DIR=${0:A:h}

# Load components
source "${PLUGIN_DIR}/config.zsh"
source "${PLUGIN_DIR}/completion.zsh"
source "${PLUGIN_DIR}/util.zsh"

export SUPERMAVEN_BINARY="$HOME/.supermaven/binary/v20/linux-x86_64/sm-agent"

# Initialize the plugin
function supermaven_init() {
  # Ensure plugin is only loaded once
  [[ -n "$SUPERMAVEN_INITIALIZED" ]] && return 0
  # Check if binary exists
  if [ ! -f "$SUPERMAVEN_BINARY" ]; then
    supermaven_log "ERROR" "Supermaven binary not found at $SUPERMAVEN_BINARY"
    return 1
  fi

  # Set up key bindings
  bindkey '^X^M' supermaven_trigger_completion  # Ctrl-X + Ctrl-M for triggering completion
  bindkey "$SUPERMAVEN_ACCEPT_SUGGESTION_KEY" supermaven_accept_suggestion  # Accept suggestion
  
  # Register completion
  compdef _supermaven_complete supermaven

  export SUPERMAVEN_INITIALIZED=1
}

function supermaven_status() {
  if supermaven_is_running; then
    echo "Supermaven is running"
    return 0
  else
    echo "Supermaven is not running"
    return 1
  fi
}

function supermaven_get_completions() {
  local buffer=$1
  local cursor_pos=$2
  
  # Call binary to get completions
  if [ -n "$SUPERMAVEN_BINARY" ]; then
    # Add --inline flag for inline completion mode
    "$SUPERMAVEN_BINARY" complete --buffer "$buffer" --position "$cursor_pos" --inline
  fi
}

function supermaven_trigger_completion() {
  local buffer=$BUFFER
  local cursor_pos=$CURSOR
  
  local completions=$(supermaven_get_completions "$buffer" "$cursor_pos")
  
  if [ -n "$completions" ]; then
    # Show completion in a different color
    local completion_color=${SUPERMAVEN_COMPLETION_COLOR:-"8"} # Default to gray
    local colored_completion=$'\e['${completion_color}'m'${completions}$'\e[0m'
    
    # Display the completion suggestion after the cursor
    POSTDISPLAY="$colored_completion"
    
    # Store the completion for later use
    _supermaven_completion="$completions"
  fi
}

function supermaven_accept_suggestion() {
  if [[ -n "$_supermaven_completion" ]]; then
    BUFFER="$BUFFER$_supermaven_completion"
    CURSOR=${#BUFFER}
    POSTDISPLAY=""
    _supermaven_completion=""
  fi
}

# Call init function
supermaven_init
