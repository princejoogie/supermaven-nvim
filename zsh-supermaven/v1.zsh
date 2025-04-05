# Get absolute path of script directory
PLUGIN_DIR=${0:A:h}
request_id=0

# Load components
source "${PLUGIN_DIR}/config.zsh"
source "${PLUGIN_DIR}/completion.zsh"
source "${PLUGIN_DIR}/util.zsh"

SUPERMAVEN_BINARY="$HOME/.supermaven/binary/v20/linux-x86_64/sm-agent"
SUPERMAVEN_PID=0

function supermaven_init() {
  [[ -n "$SUPERMAVEN_INITIALIZED" ]] && return 0

  if [ ! -f "$SUPERMAVEN_BINARY" ]; then
    echo "ERROR" "Supermaven binary not found at $SUPERMAVEN_BINARY"
    return 1
  fi

  "$SUPERMAVEN_BINARY" stdio &
  SUPERMAVEN_PID=$!

  # Register Zsh widgets with correct naming
  zle -N supermaven_trigger_completion
  zle -N supermaven_accept_suggestion

  # Set up key bindings
  bindkey '^X' supermaven_trigger_completion
  bindkey "${SUPERMAVEN_ACCEPT_SUGGESTION_KEY:-'^Y'}" supermaven_accept_suggestion

  compdef _supermaven_complete supermaven

  export SUPERMAVEN_INITIALIZED=1
}

function send_request() {
  local request="$1"
  local response=""
  local line=""

  echo "================="
  echo "request: $request"
  echo "----"

  # Start the binary in the background and get its process ID

  # Send the request to the binary's stdin
  echo "$request" >/proc/$SUPERMAVEN_PID/fd/0

  # Read the response from stdout
  while IFS= read -r line; do
    response+="$line"$'\n'
    echo "response line: $line"

    if [[ "$line" == *"finish"* ]]; then
      break
    fi
  done

  kill $SUPERMAVEN_PID

  echo "final response: $response"
  echo "================="
}

function supermaven_trigger_completion() {
  local buffer="$BUFFER"
  local cursor_pos="$CURSOR"
  if [ -n "$SUPERMAVEN_BINARY" ]; then
    ((request_id++))
    # "{\"newId\":\"1\",\"updates\":[{\"kind\":\"cursor_update\",\"offset\":8,\"path\":\"/tmp/zsh-supermaven\"},{\"content\":\"rm -rf\",\"kind\":\"file_update\",\"path\":\"/tmp/zsh-supermaven\"}],\"kind\":\"state_update\",\"buffer\":\"rm -rf\",\"cursor\":4}"
    # '{"newId":"2","updates":[{"kind":"cursor_update","offset":8,"path":"/tmp/zsh-supermaven"},{"content":"pnpm run","kind":"file_update","path":"/tmp/zsh-supermaven"}],"kind":"state_update","buffer":"pnpm run","cursor":4}'

    local updates=$(printf '[{"kind":"cursor_update","offset":%d,"path":"zsh_completion"},{"content":"%s","kind":"file_update","path":"zsh_completion"}]' "$cursor_pos" "$buffer")
    local request=$(printf '{"newId":"%d","updates":%s,"kind":"state_update","buffer":"%s","cursor":%d}\n' "$request_id" "$updates" "$buffer" "$cursor_pos")
    send_request "$request"

    # Parse response for completion text
    if [ $? -eq 0 ] && [ -n "$response" ]; then
      local completion_text=$(echo "$response" | grep 'SM-MESSAGE' | grep -o '"text":"[^"]*"' | cut -d'"' -f4)
      display_virtual_text "$completion_text"
    fi
  fi
}

function display_virtual_text() {
  local response="$1"
  print -P "%F{cyan}$response%f"
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
