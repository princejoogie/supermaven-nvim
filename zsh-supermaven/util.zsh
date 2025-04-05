# Escape special characters in a string
function supermaven_escape() {
  local str="$1"
  # Handle empty input
  [[ -z "$str" ]] && return 0
  # Escape more special characters including spaces, quotes, and control chars
  echo "${str//[^A-Za-z0-9_.-]/\\&}"
}

# Check if a command exists
function supermaven_has_command() {
  local cmd="$1"
  [[ -z "$cmd" ]] && return 1
  command -v "$cmd" >/dev/null 2>&1
}

# Get a consistent path representation
function supermaven_get_path() {
  local path="$1"
  [[ -z "$path" ]] && return 1
  # Handle both absolute and relative paths
  if [[ "$path" = /* ]]; then
    echo "${path:A}"
  else
    echo "${PWD}/${path}"
  fi
}

# Log messages with timestamp and proper log levels
function supermaven_log() {
  local level="$1"
  local message="$2"
  local timestamp=$(date +"%Y-%m-%dT%H:%M:%S")
  
  # Set color based on log level
  local color=""
  case "$level" in
    ERROR)   color="\033[0;31m" ;; # Red
    WARN)    color="\033[0;33m" ;; # Yellow
    INFO)    color="\033[0;32m" ;; # Green
    DEBUG)   color="\033[0;34m" ;; # Blue
    *)       color="\033[0m"    ;; # Default
  esac
  
  # Only log if level matches configuration
  case "$SUPERMAVEN_LOG_LEVEL" in
    error)   [[ "$level" == "ERROR" ]] && printf "${color}%s - %s - %s\033[0m\n" "$timestamp" "$level" "$message" ;;
    warn)    [[ "$level" =~ ^(ERROR|WARN)$ ]] && printf "${color}%s - %s - %s\033[0m\n" "$timestamp" "$level" "$message" ;;
    info)    [[ "$level" =~ ^(ERROR|WARN|INFO)$ ]] && printf "${color}%s - %s - %s\033[0m\n" "$timestamp" "$level" "$message" ;;
    debug)   echo "${color}%s - %s - %s\033[0m\n" "$timestamp" "$level" "$message" ;;
  esac
}

# Check if supermaven is enabled
function supermaven_is_enabled() {
  [[ "$SUPERMAVEN_ENABLED" == "true" ]]
}

# Validate path exists
function supermaven_path_exists() {
  local path="$1"
  [[ -e "$path" ]]
}
