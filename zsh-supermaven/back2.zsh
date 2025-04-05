# supermaven.zsh

# Path to the binary
SUPERMAVEN_BINARY="$HOME/.supermaven/binary/v20/linux-x86_64/sm-agent"

# FIFO (named pipe) to capture the response
FIFO_PIPE=$(mktemp -u /tmp/supermaven_fifo.XXXXXX)

# Function to initialize the script, start the background job, and bind keys
init() {
  # Create FIFO pipe
  mkfifo "$FIFO_PIPE"

  # Start the background job (binary) and redirect stdout to FIFO pipe
  start_sm_agent_background

  # Bind <C-x> to trigger the send_to_sm_agent function
  zle -N send_to_sm_agent
  bindkey "^X" send_to_sm_agent
}

# Function to start the background job (the binary)
start_sm_agent_background() {
  # Start the binary in the background, writing its output to the FIFO pipe
  $SUPERMAVEN_BINARY stdio >"$FIFO_PIPE" &
}

# Function to send the request and capture the response
send_to_sm_agent() {
  local buffer="$BUFFER"
  local cursor="$CURSOR"
  local json_request
  local response=""
  local finish_edit_received=false

  # Prepare JSON request with buffer content and cursor position
  json_request="{\"newId\":\"0\",\"updates\":[{\"kind\":\"cursor_update\",\"offset\":${cursor},\"path\":\"/tmp/zsh_super_maven\"},{\"content\":\"${buffer}\",\"kind\":\"file_update\",\"path\":\"/tmp/zsh_super_maven\"}],\"kind\":\"state_update\",\"buffer\":\"${buffer}\",\"cursor\":${cursor}}\n"

  echo "Sending request: $json_request" # Debug

  # Send the request to the binary (stdin to background process)
  echo "$json_request" >"$FIFO_PIPE"

  # Use readline to continuously read from the FIFO pipe line by line
  while true; do
    # Read the next line from the FIFO pipe
    response_line=$(<"$FIFO_PIPE")

    # Check if response line contains the finish_edit signal
    if [[ "$response_line" == *'"kind":"finish_edit"'* ]]; then
      finish_edit_received=true
      break
    fi

    # Accumulate the response text from SM-MESSAGE
    if [[ "$response_line" =~ ^SM-MESSAGE ]]; then
      text=$(echo "$response_line" | sed 's/.*"text":"\([^"]*\)".*/\1/')
      if [[ -n "$text" ]]; then
        response+="$text"
      fi
    fi
  done

  # Once the "finish_edit" is received, display the accumulated response text
  display_virtual_text "$response"
}

# Function to display virtual text in the command line
display_virtual_text() {
  local response="$1"

  # Display the accumulated response text as virtual text (you can adjust formatting)
  print -P "%F{cyan}$response%f" # Example: Display the text in cyan
}

# Initialize the script
init
