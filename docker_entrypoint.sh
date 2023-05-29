#!/usr/bin/env sh
confd="/etc/opt/simplex"
logd="/var/opt/simplex/"

export ADDR="0.0.0.0"
export PASS=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 15) #set a 15 digit server password. See the comments in smp-server.ini for a description of what this does

# Check if server has been initialized
if [ ! -f "$confd/smp-server.ini" ]; then
  # If not, determine ip or domain
  case "$ADDR" in
    '') printf "Please specify \$ADDR environment variable.\n"; exit 1 ;;
    *[a-zA-Z]*)
      case "$ADDR" in
        *:*) set -- --ip "$ADDR" ;;
        *) set -- -n "$ADDR" ;;
      esac
      ;;
    *) set -- --ip "$ADDR" ;;
  esac

  # Optionally, set password
  case "$PASS" in
    '') set -- "$@" --no-password ;;
    *) set -- "$@" --password "$PASS" ;;
  esac

  # And init certificates and configs
  smp-server init -y -l "$@"
fi

# Backup store log just in case
[ -f "$logd/smp-server-store.log" ] && cp "$logd"/smp-server-store.log "$logd"/smp-server-store.log."$(date +'%FT%T')"

# Finally, run smp-sever. Notice that "exec" here is important:
# smp-server replaces our helper script, so that it can catch INT signal
exec smp-server start +RTS -N -RTS