#####################################
# KILL PORTS FUNCTION
#####################################
# Auto detect and kill — no argument needed
killports() {
  echo "Scanning for active listening ports..."
  echo ""

  # Get all listening ports with process info
  local PORT_LIST
  PORT_LIST=$(sudo lsof -iTCP -sTCP:LISTEN -n -P 2>/dev/null | awk 'NR>1 {
    split($9, a, ":")
    port = a[length(a)]
    print port"\t"$2"\t"$1
  }' | sort -u)

  if [[ -z "$PORT_LIST" ]]; then
    echo "No active ports found."
    return 0
  fi

  # Show all found ports
  echo "Active ports:"
  echo "─────────────────────────────────"
  printf "  %-8s %-8s %s\n" "PORT" "PID" "PROCESS"
  echo "─────────────────────────────────"
  while IFS=$'\t' read -r port pid proc; do
    printf "  %-8s %-8s %s\n" "$port" "$pid" "$proc"
  done <<< "$PORT_LIST"
  echo "─────────────────────────────────"
  echo ""

  # Ask which port to kill
  read -rp "Enter port to kill (or 'all' to kill all, q to quit): " CHOICE

  if [[ "$CHOICE" == "q" ]]; then
    echo "Cancelled."
    return 0
  fi

  if [[ "$CHOICE" == "all" ]]; then
    while IFS=$'\t' read -r port pid proc; do
      sudo kill -9 "$pid" 2>/dev/null && echo "✓ Killed port $port (PID: $pid → $proc)"
    done <<< "$PORT_LIST"
    return 0
  fi

  # Kill specific port
  local TARGET_PIDS
  TARGET_PIDS=$(sudo lsof -t -i:"$CHOICE" 2>/dev/null)
  if [[ -z "$TARGET_PIDS" ]]; then
    echo "No process found on port $CHOICE"
    return 1
  fi

  sudo kill -9 $TARGET_PIDS 2>/dev/null && echo "✓ Killed port $CHOICE"
}


#####################################
# SKILL URL
#####################################
skillurl() {
  local url="$1"
  local mode="${2:-ultra}"

  npx skillui --url "$url" --mode "$mode"
}
