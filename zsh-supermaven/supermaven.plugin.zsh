# Get absolute path of script directory
PLUGIN_DIR=${0:A:h}

# Load components
source "${PLUGIN_DIR}/config.zsh"
source "${PLUGIN_DIR}/completion.zsh"
source "${PLUGIN_DIR}/util.zsh"

export SUPERMAVEN_BINARY="$HOME/.supermaven/binary/v20/linux-x86_64/sm-agent"

function supermaven_init() {
  [[ -n "$SUPERMAVEN_INITIALIZED" ]] && return 0

  if [ ! -f "$SUPERMAVEN_BINARY" ]; then
    echo "ERROR" "Supermaven binary not found at $SUPERMAVEN_BINARY"
    return 1
  fi

  # Register Zsh widgets with correct naming
  zle -N supermaven_trigger_completion
  zle -N supermaven_accept_suggestion

  # Set up key bindings
  bindkey '^X' supermaven_trigger_completion
  bindkey "${SUPERMAVEN_ACCEPT_SUGGESTION_KEY:-'^Y'}" supermaven_accept_suggestion

  compdef _supermaven_complete supermaven

  export SUPERMAVEN_INITIALIZED=1
}

function supermaven_trigger_completion() {
  local buffer="$BUFFER"
  local cursor_pos="$CURSOR"
  if [ -n "$SUPERMAVEN_BINARY" ]; then
    # Create JSON request
    local request=$(printf '{"newId":"","updates":[],"kind":"state_update","buffer":"%s","cursor":%d}\n' "$buffer" "$cursor_pos")

    # Call binary and capture response
    local response=$("$SUPERMAVEN_BINARY" stdio <<<"$request")

    echo "DEBUG" "Triggering completion..."
    echo "response: $response, request: $request"

    # Parse response for completion text
    if [ $? -eq 0 ] && [ -n "$response" ]; then
      local completion_text=$(echo "$response" | grep -o '"text":"[^"]*"' | cut -d'"' -f4)

      if [ -n "$completion_text" ]; then
        local completion_color=${SUPERMAVEN_COMPLETION_COLOR:-"8"}
        local colored_completion=$'\e['${completion_color}'m'${completion_text}$'\e[0m'

        POSTDISPLAY="$colored_completion"
        _supermaven_completion="$completion_text"

        zle redisplay
      fi
    fi
  fi
}

function supermaven_accept_suggestion() {
  if [[ -n "$_supermaven_completion" ]]; then
    BUFFER="$BUFFER$_supermaven_completion"
    CURSOR=${#BUFFER}
    POSTDISPLAY=""
    _supermaven_completion=""
    zle redisplay
  fi
}

# Initialize
supermaven_init
