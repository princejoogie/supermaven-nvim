function fetch_supermaven_binary() {
  local platform=$(uname -s | tr '[:upper:]' '[:lower:]')
  local arch=$(uname -m)
  local binary_dir="${PLUGIN_DIR}/bin"
  local dest="${binary_dir}/supermaven"
  
  # Create bin directory if it doesn't exist
  mkdir -p "$binary_dir"
  
  if [ ! -f "$dest" ]; then
    supermaven_log "INFO" "Downloading Supermaven binary..."
    local url="https://releases.supermaven.com/${platform}-${arch}/supermaven"
    if ! curl -L -s -o "$dest" "$url"; then
      supermaven_log "ERROR" "Failed to download Supermaven binary"
      return 1
    fi
    chmod +x "$dest"
  fi
  
  export SUPERMAVEN_BINARY="$dest"
}

function supermaven_is_running() {
  if [ -f "/tmp/supermaven.pid" ]; then
    local pid=$(cat /tmp/supermaven.pid)
    if kill -0 "$pid" 2>/dev/null; then
      return 0
    fi
  fi
  return 1
}
