autoload -U compinit
compinit

function _supermaven_complete() {
  local curcontext="$curcontext" state line
  typeset -A opt_args

  _arguments \
    '1: :->command' \
    '*: :->args'

  case $state in
    command)
      local commands=(
        'start:Start Supermaven'
        'stop:Stop Supermaven'
        'restart:Restart Supermaven'
        'status:Check Supermaven status'
      )
      _describe -t commands 'commands' commands
      ;;
    args)
      case $line[1] in
        start|stop|restart|status)
          # No additional arguments needed
          ;;
      esac
      ;;
  esac
}
