#!/bin/bash

# ─────────────────────────────────────────────────────────────────
# dtools — Interactive Docker Toolkit
#
# INSTALL:
#   cp .dtools.sh ~/.dtools.sh
#   echo 'source ~/.dtools.sh' >> ~/.bashrc
#   source ~/.bashrc
#
# USAGE:
#   dtools        → Launch interactive menu (starts Docker automatically)
#   dhelp         → Show full cheatsheet
#   dps / dpsa    → Quick container list
#   dsh <name>    → Shell into container
#   dlogs <name>  → Tail container logs
#
# BEHAVIOR:
#   • Docker Desktop auto-starts when you run `dtools`
#   • Docker Desktop auto-stops when you exit via option 0
#   • If terminal is force-closed, EXIT trap also stops Docker
# ─────────────────────────────────────────────────────────────────


# =================================================================
# DOCKER ALIASES  (available without launching menu)
# =================================================================
alias dps='docker ps'
alias dpsa='docker ps -a'
alias dimg='docker images'
alias dcu='docker compose up'
alias dcud='docker compose up -d'
alias dcd='docker compose down'
alias dcl='docker compose logs -f'
alias dprune='docker system prune -a'


# =================================================================
# QUICK HELPER FUNCTIONS  (usable directly from terminal)
# =================================================================

dstop() {
  if [[ -z "$1" ]]; then
    echo "Stopping ALL running containers..."
    docker stop $(docker ps -q) 2>/dev/null && echo "✓ All stopped" || echo "No containers running"
  else
    docker stop "$1" && echo "✓ Stopped: $1"
  fi
}

drm() {
  if [[ -z "$1" ]]; then
    echo "Removing ALL stopped containers..."
    docker rm $(docker ps -aq) 2>/dev/null && echo "✓ All removed" || echo "Nothing to remove"
  else
    docker rm "$1" && echo "✓ Removed: $1"
  fi
}

dsh() {
  if [[ -z "$1" ]]; then
    echo "Running containers:"
    docker ps --format "  {{.Names}}\t{{.Image}}\t{{.Status}}" | column -t
    echo ""
    read -rp "Enter container name to shell into: " CONTAINER
  else
    CONTAINER="$1"
  fi
  docker exec -it "$CONTAINER" /bin/sh -c "bash 2>/dev/null || sh"
}

dlogs() {
  if [[ -z "$1" ]]; then
    echo "Running containers:"
    docker ps --format "  {{.Names}}\t{{.Image}}\t{{.Status}}" | column -t
    echo ""
    read -rp "Enter container name to tail logs: " CONTAINER
  else
    CONTAINER="$1"
  fi
  docker logs -f "$CONTAINER"
}

dclean() {
  echo "🧹 Docker Full Cleanup"
  echo "  [1] Stopped containers only"
  echo "  [2] Unused images only"
  echo "  [3] Unused volumes only"
  echo "  [4] Everything (containers + images + volumes + networks)"
  echo ""
  read -rp "Choose [1-4]: " OPT
  case $OPT in
    1) docker container prune -f && echo "✓ Containers cleaned" ;;
    2) docker image prune -a -f  && echo "✓ Images cleaned"     ;;
    3) docker volume prune -f    && echo "✓ Volumes cleaned"    ;;
    4) docker system prune -a --volumes -f && echo "✓ Full cleanup done" ;;
    *) echo "Invalid option" ;;
  esac
}


# =================================================================
# INTERNAL: Docker lifecycle helpers
# =================================================================

_docker_start() {
  local RED='\033[0;31m'
  local GREEN='\033[0;32m'
  local CYAN='\033[0;36m'
  local DIM='\033[2m'
  local RESET='\033[0m'

  # Already running? Skip.
  if docker info &>/dev/null 2>&1; then
    echo -e "${GREEN}  ✓ Docker is already running.${RESET}"
    return 0
  fi

  echo -e "${CYAN}  🐳 Starting Docker Desktop...${RESET}"
  systemctl --user enable docker-desktop 2>/dev/null
  systemctl --user start docker-desktop  2>/dev/null

  echo -e "${DIM}  Waiting for Docker daemon to be ready...${RESET}"
  local TRIES=0
  until docker info &>/dev/null 2>&1; do
    if [[ $TRIES -ge 20 ]]; then
      echo -e "${RED}  ✗ Docker did not become ready after 40 seconds.${RESET}"
      echo -e "${RED}    Please start Docker Desktop manually and retry.${RESET}"
      return 1
    fi
    printf "${DIM}.${RESET}"
    sleep 2
    ((TRIES++))
  done
  echo ""
  echo -e "${GREEN}  ✓ Docker is ready.${RESET}"
  return 0
}

_docker_stop() {
  local GREEN='\033[0;32m'
  local YELLOW='\033[1;33m'
  local RESET='\033[0m'

  echo -e "${YELLOW}  🐳 Stopping Docker Desktop...${RESET}"
  systemctl --user stop    docker-desktop 2>/dev/null
  systemctl --user disable docker-desktop 2>/dev/null
  echo -e "${GREEN}  ✓ Docker Desktop stopped & disabled.${RESET}"
}


# =================================================================
# dtools — Interactive Menu
# =================================================================
dtools() {

  # ── Colors ──────────────────────────────────────────────────────
  local RED='\033[0;31m'
  local GREEN='\033[0;32m'
  local YELLOW='\033[1;33m'
  local CYAN='\033[0;36m'
  local MAGENTA='\033[0;35m'
  local BOLD='\033[1m'
  local DIM='\033[2m'
  local WHITE='\033[1;37m'
  local RESET='\033[0m'

  # ── Auto-start Docker ────────────────────────────────────────────
  echo ""
  echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${CYAN}║          🐳  dtools — Docker Interactive Toolkit             ║${RESET}"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
  echo ""

  _docker_start || return 1

  # ── EXIT trap: stop Docker if terminal is force-closed ──────────
  # (clean exit via option 0 also calls _docker_stop explicitly)
  trap '_docker_stop' EXIT

  # ── Helpers ─────────────────────────────────────────────────────

  _confirm_destructive() {
    echo -e "${RED}  ⚠  This is a destructive operation. Type 'yes' to confirm:${RESET}"
    read -rp "  > " _DESTR
    [[ "$_DESTR" != "yes" ]] && echo -e "${RED}  Aborted.${RESET}" && return 1
    return 0
  }

  _pick_container() {
    local LABEL="${1:-container}"
    echo -e "${YELLOW}  Running containers:${RESET}"
    docker ps --format "  {{.Names}}\t{{.Image}}\t{{.Status}}" | column -t
    echo ""
    read -rp "  Enter ${LABEL} name: " PICKED_CONTAINER
    [[ -z "$PICKED_CONTAINER" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1
    echo "$PICKED_CONTAINER"
  }

  _pick_any_container() {
    local LABEL="${1:-container}"
    echo -e "${YELLOW}  All containers (including stopped):${RESET}"
    docker ps -a --format "  {{.Names}}\t{{.Image}}\t{{.Status}}" | column -t
    echo ""
    read -rp "  Enter ${LABEL} name: " PICKED_CONTAINER
    [[ -z "$PICKED_CONTAINER" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1
    echo "$PICKED_CONTAINER"
  }

  # ══════════════════════════════════════════════════════════════
  # SECTION A: INSPECT
  # ══════════════════════════════════════════════════════════════

  _dps() {
    echo -e "${BOLD}${CYAN}🟢 Running Containers:${RESET}"
    docker ps
  }

  _dpsa() {
    echo -e "${BOLD}${CYAN}📦 All Containers (including stopped):${RESET}"
    docker ps -a
  }

  _dimg() {
    echo -e "${BOLD}${CYAN}🖼  Local Images:${RESET}"
    docker images
  }

  _dinspect() {
    local C
    C=$(_pick_any_container "container to inspect")
    [[ -z "$C" ]] && return 1
    docker inspect "$C"
  }

  _dstats() {
    echo -e "${BOLD}${CYAN}📊 Live Container Stats (Ctrl+C to exit):${RESET}"
    docker stats
  }

  _dport() {
    local C
    C=$(_pick_any_container "container to check ports")
    [[ -z "$C" ]] && return 1
    echo -e "${BOLD}${CYAN}🔌 Port mappings for '${C}':${RESET}"
    docker port "$C"
  }

  _ddf() {
    echo -e "${BOLD}${CYAN}💾 Docker Disk Usage:${RESET}"
    docker system df
  }

  # ══════════════════════════════════════════════════════════════
  # SECTION B: COMPOSE
  # ══════════════════════════════════════════════════════════════

  _dcu() {
    echo -e "${YELLOW}  Starting services (attached)...${RESET}"
    docker compose up
  }

  _dcud() {
    echo -e "${YELLOW}  Starting services in background...${RESET}"
    docker compose up -d
    echo -e "${GREEN}  ✓ Services started in detached mode.${RESET}"
  }

  _dcub() {
    echo -e "${YELLOW}  Building + starting services (detached)...${RESET}"
    docker compose up -d --build
    echo -e "${GREEN}  ✓ Build + start done.${RESET}"
  }

  _dcd() {
    echo -e "${YELLOW}  Stopping + removing compose containers...${RESET}"
    docker compose down
    echo -e "${GREEN}  ✓ Compose down.${RESET}"
  }

  _dcdv() {
    echo -e "${RED}  ⚠  This will also remove volumes!${RESET}"
    _confirm_destructive || return 1
    docker compose down -v
    echo -e "${GREEN}  ✓ Compose down (with volumes).${RESET}"
  }

  _dcl() {
    echo -e "${YELLOW}  Following compose logs (Ctrl+C to exit)...${RESET}"
    docker compose logs -f
  }

  _dcps() {
    echo -e "${BOLD}${CYAN}📋 Compose Services Status:${RESET}"
    docker compose ps
  }

  _dcrestart() {
    read -rp "  Service name to restart (blank = all): " SVC
    if [[ -z "$SVC" ]]; then
      docker compose restart
      echo -e "${GREEN}  ✓ All services restarted.${RESET}"
    else
      docker compose restart "$SVC"
      echo -e "${GREEN}  ✓ '${SVC}' restarted.${RESET}"
    fi
  }

  # ══════════════════════════════════════════════════════════════
  # SECTION C: CONTAINER OPS
  # ══════════════════════════════════════════════════════════════

  _dstop_one() {
    local C
    C=$(_pick_container "container to stop")
    [[ -z "$C" ]] && return 1
    docker stop "$C" && echo -e "${GREEN}  ✓ Stopped '${C}'.${RESET}"
  }

  _dstop_all() {
    echo -e "${YELLOW}  Stopping ALL running containers...${RESET}"
    _confirm_destructive || return 1
    docker stop $(docker ps -q) 2>/dev/null \
      && echo -e "${GREEN}  ✓ All stopped.${RESET}" \
      || echo -e "${YELLOW}  No containers running.${RESET}"
  }

  _dstart() {
    local C
    C=$(_pick_any_container "stopped container to start")
    [[ -z "$C" ]] && return 1
    docker start "$C" && echo -e "${GREEN}  ✓ Started '${C}'.${RESET}"
  }

  _drestart() {
    local C
    C=$(_pick_container "container to restart")
    [[ -z "$C" ]] && return 1
    docker restart "$C" && echo -e "${GREEN}  ✓ Restarted '${C}'.${RESET}"
  }

  _drm_one() {
    local C
    C=$(_pick_any_container "container to remove")
    [[ -z "$C" ]] && return 1
    _confirm_destructive || return 1
    docker rm "$C" && echo -e "${GREEN}  ✓ Removed '${C}'.${RESET}"
  }

  _drm_all() {
    echo -e "${YELLOW}  Removing ALL stopped containers...${RESET}"
    _confirm_destructive || return 1
    docker rm $(docker ps -aq) 2>/dev/null \
      && echo -e "${GREEN}  ✓ All removed.${RESET}" \
      || echo -e "${YELLOW}  Nothing to remove.${RESET}"
  }

  _dsh() {
    local C
    C=$(_pick_container "container to shell into")
    [[ -z "$C" ]] && return 1
    echo -e "${CYAN}  Shelling into '${C}' (bash → sh fallback)...${RESET}"
    docker exec -it "$C" /bin/sh -c "bash 2>/dev/null || sh"
  }

  _dlogs_one() {
    local C
    C=$(_pick_container "container to tail logs")
    [[ -z "$C" ]] && return 1
    read -rp "  Lines to show (default 100): " LINES
    LINES="${LINES:-100}"
    docker logs -f --tail "$LINES" "$C"
  }

  _dexec() {
    local C
    C=$(_pick_container "container to run command in")
    [[ -z "$C" ]] && return 1
    read -rp "  Command to run: " CMD
    [[ -z "$CMD" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1
    docker exec -it "$C" $CMD
  }

  _dcopy_from() {
    local C
    C=$(_pick_any_container "container to copy from")
    [[ -z "$C" ]] && return 1
    read -rp "  Container path (e.g. /app/file.txt): " SRC
    read -rp "  Local destination path             : " DEST
    [[ -z "$SRC" || -z "$DEST" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1
    docker cp "${C}:${SRC}" "$DEST" && echo -e "${GREEN}  ✓ Copied to ${DEST}.${RESET}"
  }

  _dcopy_to() {
    local C
    C=$(_pick_any_container "container to copy to")
    [[ -z "$C" ]] && return 1
    read -rp "  Local file path                    : " SRC
    read -rp "  Container destination (e.g. /app/) : " DEST
    [[ -z "$SRC" || -z "$DEST" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1
    docker cp "$SRC" "${C}:${DEST}" && echo -e "${GREEN}  ✓ Copied to container.${RESET}"
  }

  # ══════════════════════════════════════════════════════════════
  # SECTION D: IMAGES
  # ══════════════════════════════════════════════════════════════

  _dpull() {
    read -rp "  Image to pull (e.g. nginx:latest): " IMG
    [[ -z "$IMG" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1
    docker pull "$IMG"
  }

  _dbuild() {
    read -rp "  Image tag name (e.g. myapp:v1): " TAG
    read -rp "  Dockerfile path (default: .)  : " CTX
    CTX="${CTX:-.}"
    [[ -z "$TAG" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1
    docker build -t "$TAG" "$CTX"
    echo -e "${GREEN}  ✓ Image '${TAG}' built.${RESET}"
  }

  _drmi() {
    echo -e "${YELLOW}  Local images:${RESET}"
    docker images
    echo ""
    read -rp "  Image to remove (name:tag or ID): " IMG
    [[ -z "$IMG" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1
    _confirm_destructive || return 1
    docker rmi "$IMG" && echo -e "${GREEN}  ✓ Image removed.${RESET}"
  }

  _dtag() {
    echo -e "${YELLOW}  Local images:${RESET}"
    docker images
    echo ""
    read -rp "  Source image (name:tag): " SRC_IMG
    read -rp "  New tag      (name:tag): " NEW_TAG
    [[ -z "$SRC_IMG" || -z "$NEW_TAG" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1
    docker tag "$SRC_IMG" "$NEW_TAG" && echo -e "${GREEN}  ✓ Tagged as '${NEW_TAG}'.${RESET}"
  }

  _dpush_img() {
    echo -e "${YELLOW}  Local images:${RESET}"
    docker images
    echo ""
    read -rp "  Image to push (name:tag): " IMG
    [[ -z "$IMG" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1
    docker push "$IMG"
  }

  # ══════════════════════════════════════════════════════════════
  # SECTION E: VOLUMES & NETWORKS
  # ══════════════════════════════════════════════════════════════

  _dvls() {
    echo -e "${BOLD}${CYAN}💽 Docker Volumes:${RESET}"
    docker volume ls
  }

  _dvrm() {
    docker volume ls
    echo ""
    read -rp "  Volume name to remove: " VOL
    [[ -z "$VOL" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1
    _confirm_destructive || return 1
    docker volume rm "$VOL" && echo -e "${GREEN}  ✓ Volume '${VOL}' removed.${RESET}"
  }

  _dnls() {
    echo -e "${BOLD}${CYAN}🌐 Docker Networks:${RESET}"
    docker network ls
  }

  _dnrm() {
    docker network ls
    echo ""
    read -rp "  Network name to remove: " NET
    [[ -z "$NET" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1
    _confirm_destructive || return 1
    docker network rm "$NET" && echo -e "${GREEN}  ✓ Network '${NET}' removed.${RESET}"
  }

  # ══════════════════════════════════════════════════════════════
  # SECTION F: CLEANUP
  # ══════════════════════════════════════════════════════════════

  _dclean_containers() {
    _confirm_destructive || return 1
    docker container prune -f && echo -e "${GREEN}  ✓ Stopped containers removed.${RESET}"
  }

  _dclean_images() {
    _confirm_destructive || return 1
    docker image prune -a -f && echo -e "${GREEN}  ✓ Unused images removed.${RESET}"
  }

  _dclean_volumes() {
    _confirm_destructive || return 1
    docker volume prune -f && echo -e "${GREEN}  ✓ Unused volumes removed.${RESET}"
  }

  _dclean_all() {
    echo -e "${RED}  ⚠  This removes ALL unused containers, images, volumes & networks!${RESET}"
    _confirm_destructive || return 1
    docker system prune -a --volumes -f && echo -e "${GREEN}  ✓ Full cleanup done.${RESET}"
  }

  # ══════════════════════════════════════════════════════════════
  # MAIN MENU LOOP
  # ══════════════════════════════════════════════════════════════
  while true; do
    echo ""
    echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║          🐳  dtools — Docker Interactive Toolkit             ║${RESET}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${BOLD}${YELLOW}  ━━ INSPECT ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${GREEN} 1)${RESET} 🟢  Running containers    ${DIM}-- docker ps${RESET}"
    echo -e "  ${GREEN} 2)${RESET} 📦  All containers        ${DIM}-- docker ps -a${RESET}"
    echo -e "  ${GREEN} 3)${RESET} 🖼   Local images          ${DIM}-- docker images${RESET}"
    echo -e "  ${GREEN} 4)${RESET} 🔍  Inspect container     ${DIM}-- docker inspect <name>${RESET}"
    echo -e "  ${GREEN} 5)${RESET} 📊  Live stats            ${DIM}-- docker stats${RESET}"
    echo -e "  ${GREEN} 6)${RESET} 🔌  Port mappings         ${DIM}-- docker port <name>${RESET}"
    echo -e "  ${GREEN} 7)${RESET} 💾  Disk usage            ${DIM}-- docker system df${RESET}"
    echo ""
    echo -e "${BOLD}${YELLOW}  ━━ COMPOSE ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${GREEN} 8)${RESET} ▶️   Compose up            ${DIM}-- docker compose up${RESET}"
    echo -e "  ${GREEN} 9)${RESET} ▶️   Compose up -d         ${DIM}-- docker compose up -d${RESET}"
    echo -e "  ${GREEN}10)${RESET} 🔨  Compose up --build    ${DIM}-- docker compose up -d --build${RESET}"
    echo -e "  ${RED}11)${RESET} ⏹   Compose down           ${DIM}-- docker compose down${RESET}"
    echo -e "  ${RED}12)${RESET} 💥  Compose down -v ⚠      ${DIM}-- docker compose down -v${RESET}"
    echo -e "  ${GREEN}13)${RESET} 📋  Compose status        ${DIM}-- docker compose ps${RESET}"
    echo -e "  ${GREEN}14)${RESET} 📜  Compose logs          ${DIM}-- docker compose logs -f${RESET}"
    echo -e "  ${GREEN}15)${RESET} 🔄  Compose restart       ${DIM}-- docker compose restart [service]${RESET}"
    echo ""
    echo -e "${BOLD}${YELLOW}  ━━ CONTAINER OPS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${GREEN}16)${RESET} ⏹   Stop one container    ${DIM}-- docker stop <name>${RESET}"
    echo -e "  ${RED}17)${RESET} ⏹   Stop ALL containers   ${DIM}-- docker stop \$(docker ps -q)${RESET}"
    echo -e "  ${GREEN}18)${RESET} ▶️   Start container       ${DIM}-- docker start <name>${RESET}"
    echo -e "  ${GREEN}19)${RESET} 🔄  Restart container     ${DIM}-- docker restart <name>${RESET}"
    echo -e "  ${RED}20)${RESET} 🗑   Remove one container  ${DIM}-- docker rm <name>${RESET}"
    echo -e "  ${RED}21)${RESET} 🗑   Remove ALL stopped    ${DIM}-- docker rm \$(docker ps -aq)${RESET}"
    echo -e "  ${GREEN}22)${RESET} 🖥   Shell into container  ${DIM}-- docker exec -it <name> bash/sh${RESET}"
    echo -e "  ${GREEN}23)${RESET} 📜  Tail container logs   ${DIM}-- docker logs -f --tail N <name>${RESET}"
    echo -e "  ${GREEN}24)${RESET} ⚡  Run command in ctner  ${DIM}-- docker exec -it <name> <cmd>${RESET}"
    echo -e "  ${GREEN}25)${RESET} 📁  Copy FROM container   ${DIM}-- docker cp <name>:/path ./local${RESET}"
    echo -e "  ${GREEN}26)${RESET} 📁  Copy TO container     ${DIM}-- docker cp ./local <name>:/path${RESET}"
    echo ""
    echo -e "${BOLD}${YELLOW}  ━━ IMAGES ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${GREEN}27)${RESET} ⬇️   Pull image            ${DIM}-- docker pull <image:tag>${RESET}"
    echo -e "  ${GREEN}28)${RESET} 🔨  Build image           ${DIM}-- docker build -t <tag> .${RESET}"
    echo -e "  ${RED}29)${RESET} 🗑   Remove image ⚠        ${DIM}-- docker rmi <image>${RESET}"
    echo -e "  ${GREEN}30)${RESET} 🏷   Tag image             ${DIM}-- docker tag <src> <new:tag>${RESET}"
    echo -e "  ${GREEN}31)${RESET} ⬆️   Push image            ${DIM}-- docker push <image:tag>${RESET}"
    echo ""
    echo -e "${BOLD}${YELLOW}  ━━ VOLUMES & NETWORKS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${GREEN}32)${RESET} 💽  List volumes          ${DIM}-- docker volume ls${RESET}"
    echo -e "  ${RED}33)${RESET} 🗑   Remove volume ⚠       ${DIM}-- docker volume rm <name>${RESET}"
    echo -e "  ${GREEN}34)${RESET} 🌐  List networks         ${DIM}-- docker network ls${RESET}"
    echo -e "  ${RED}35)${RESET} 🗑   Remove network ⚠      ${DIM}-- docker network rm <name>${RESET}"
    echo ""
    echo -e "${BOLD}${YELLOW}  ━━ CLEANUP ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${MAGENTA}36)${RESET} 🧹  Remove stopped ctners ${DIM}-- docker container prune -f${RESET}"
    echo -e "  ${MAGENTA}37)${RESET} 🧹  Remove unused images  ${DIM}-- docker image prune -a -f${RESET}"
    echo -e "  ${MAGENTA}38)${RESET} 🧹  Remove unused volumes ${DIM}-- docker volume prune -f${RESET}"
    echo -e "  ${RED}39)${RESET} 💀  Full nuke all ⚠        ${DIM}-- docker system prune -a --volumes -f${RESET}"
    echo ""
    echo -e "${BOLD}${YELLOW}  ━━ HELP ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${CYAN}40)${RESET} 📖  Show cheatsheet       ${DIM}-- dhelp${RESET}"
    echo ""
    echo -e "  ${RED} 0)${RESET} 🚪  Exit  ${DIM}(stops Docker Desktop)${RESET}"
    echo ""
    read -rp "  Choose option [0-40]: " CHOICE

    echo ""
    case "$CHOICE" in
       1) _dps ;;
       2) _dpsa ;;
       3) _dimg ;;
       4) _dinspect ;;
       5) _dstats ;;
       6) _dport ;;
       7) _ddf ;;
       8) _dcu ;;
       9) _dcud ;;
      10) _dcub ;;
      11) _dcd ;;
      12) _dcdv ;;
      13) _dcps ;;
      14) _dcl ;;
      15) _dcrestart ;;
      16) _dstop_one ;;
      17) _dstop_all ;;
      18) _dstart ;;
      19) _drestart ;;
      20) _drm_one ;;
      21) _drm_all ;;
      22) _dsh ;;
      23) _dlogs_one ;;
      24) _dexec ;;
      25) _dcopy_from ;;
      26) _dcopy_to ;;
      27) _dpull ;;
      28) _dbuild ;;
      29) _drmi ;;
      30) _dtag ;;
      31) _dpush_img ;;
      32) _dvls ;;
      33) _dvrm ;;
      34) _dnls ;;
      35) _dnrm ;;
      36) _dclean_containers ;;
      37) _dclean_images ;;
      38) _dclean_volumes ;;
      39) _dclean_all ;;
      40) dhelp ;;
       0)
          # Disable trap first (we're doing a clean exit, not crash)
          trap - EXIT
          echo -e "${CYAN}  Goodbye! 🐳${RESET}"
          _docker_stop
          echo ""
          return 0
          ;;
       *) echo -e "${RED}  ✗ Invalid option. Choose 0-40.${RESET}" ;;
    esac

    echo ""
    read -rp "  Press Enter to return to menu..." _PAUSE
  done
}


# =================================================================
# dhelp — Docker Cheatsheet  (type: dhelp)
# =================================================================
dhelp() {
  local BOLD='\033[1m'
  local DIM='\033[2m'
  local RED='\033[0;31m'
  local GREEN='\033[0;32m'
  local YELLOW='\033[1;33m'
  local CYAN='\033[0;36m'
  local MAGENTA='\033[0;35m'
  local WHITE='\033[1;37m'
  local RESET='\033[0m'

  local DIV="${DIM}────────────────────────────────────────────────────────────────────────────────────────────────────${RESET}"

  echo ""
  echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${CYAN}║           🐳  dtools — Docker Cheatsheet                     ║${RESET}"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
  echo ""

  printf "  ${BOLD}${WHITE}%-26s %-38s %s${RESET}\n" "OPTION / ALIAS" "WHAT IT DOES" "ACTUAL DOCKER COMMAND"
  echo -e "$DIV"

  # ── LIFECYCLE ─────────────────────────────────────────────────
  echo -e "  ${BOLD}${YELLOW}» Docker Lifecycle (auto-managed by dtools)${RESET}"
  printf "  ${CYAN}%-26s${RESET} ${WHITE}%-38s${RESET} ${DIM}%s${RESET}\n" "dtools (launch)"   "Start Docker + open menu"         "systemctl --user start docker-desktop"
  printf "  ${CYAN}%-26s${RESET} ${WHITE}%-38s${RESET} ${DIM}%s${RESET}\n" "dtools → 0 (exit)" "Stop Docker + close menu"         "systemctl --user stop docker-desktop"
  echo -e "$DIV"

  # ── INSPECT ───────────────────────────────────────────────────
  echo -e "  ${BOLD}${YELLOW}» Inspect${RESET}"
  printf "  ${GREEN}%-26s${RESET} ${WHITE}%-38s${RESET} ${DIM}%s${RESET}\n" "dtools → 1  / dps"    "List running containers"            "docker ps"
  printf "  ${GREEN}%-26s${RESET} ${WHITE}%-38s${RESET} ${DIM}%s${RESET}\n" "dtools → 2  / dpsa"   "List all containers (+ stopped)"    "docker ps -a"
  printf "  ${GREEN}%-26s${RESET} ${WHITE}%-38s${RESET} ${DIM}%s${RESET}\n" "dtools → 3  / dimg"   "List all local images"              "docker images"
  printf "  ${GREEN}%-26s${RESET} ${WHITE}%-38s${RESET} ${DIM}%s${RESET}\n" "dtools → 4"           "Full inspect of container"          "docker inspect <name>"
  printf "  ${GREEN}%-26s${RESET} ${WHITE}%-38s${RESET} ${DIM}%s${RESET}\n" "dtools → 5"           "Live CPU/mem stats"                 "docker stats"
  printf "  ${GREEN}%-26s${RESET} ${WHITE}%-38s${RESET} ${DIM}%s${RESET}\n" "dtools → 6"           "Show port mappings"                 "docker port <name>"
  printf "  ${GREEN}%-26s${RESET} ${WHITE}%-38s${RESET} ${DIM}%s${RESET}\n" "dtools → 7"           "Docker disk usage"                  "docker system df"
  echo -e "$DIV"

  # ── COMPOSE ───────────────────────────────────────────────────
  echo -e "  ${BOLD}${YELLOW}» Compose${RESET}"
  printf "  ${GREEN}%-26s${RESET} ${WHITE}%-38s${RESET} ${DIM}%s${RESET}\n" "dtools → 8  / dcu"    "Start services (attached)"          "docker compose up"
  printf "  ${GREEN}%-26s${RESET} ${WHITE}%-38s${RESET} ${DIM}%s${RESET}\n" "dtools → 9  / dcud"   "Start services (detached/bg)"       "docker compose up -d"
  printf "  ${GREEN}%-26s${RESET} ${WHITE}%-38s${RESET} ${DIM}%s${RESET}\n" "dtools → 10"          "Build + start (detached)"           "docker compose up -d --build"
  printf "  ${RED}%-26s${RESET}   ${WHITE}%-38s${RESET} ${DIM}%s${RESET}\n" "dtools → 11 / dcd"    "Stop + remove compose containers"   "docker compose down"
  printf "  ${RED}%-26s${RESET}   ${WHITE}%-38s${RESET} ${DIM}%s${RESET}\n" "dtools → 12"          "Down + remove volumes ⚠"            "docker compose down -v"
  printf "  ${GREEN}%-26s${RESET} ${WHITE}%-38s${RESET} ${DIM}%s${RESET}\n" "dtools → 13"          "Compose services status"            "docker compose ps"
  printf "  ${GREEN}%-26s${RESET} ${WHITE}%-38s${RESET} ${DIM}%s${RESET}\n" "dtools → 14 / dcl"    "Follow compose logs live"           "docker compose logs -f"
  printf "  ${GREEN}%-26s${RESET} ${WHITE}%-38s${RESET} ${DIM}%s${RESET}\n" "dtools → 15"          "Restart compose service"            "docker compose restart [service]"
  echo -e "$DIV"

  # ── CONTAINER OPS ─────────────────────────────────────────────
  echo -e "  ${BOLD}${YELLOW}» Container Operations${RESET}"
  printf "  ${GREEN}%-26s${RESET} ${WHITE}%-38s${RESET} ${DIM}%s${RESET}\n" "dtools → 16 / dstop"  "Stop one container"                 "docker stop <name>"
  printf "  ${RED}%-26s${RESET}   ${WHITE}%-38s${RESET} ${DIM}%s${RESET}\n" "dtools → 17"          "Stop ALL running containers ⚠"      "docker stop \$(docker ps -q)"
  printf "  ${GREEN}%-26s${RESET} ${WHITE}%-38s${RESET} ${DIM}%s${RESET}\n" "dtools → 18"          "Start a stopped container"          "docker start <name>"
  printf "  ${GREEN}%-26s${RESET} ${WHITE}%-38s${RESET} ${DIM}%s${RESET}\n" "dtools → 19"          "Restart a container"                "docker restart <name>"
  printf "  ${RED}%-26s${RESET}   ${WHITE}%-38s${RESET} ${DIM}%s${RESET}\n" "dtools → 20 / drm"    "Remove one container ⚠"             "docker rm <name>"
  printf "  ${RED}%-26s${RESET}   ${WHITE}%-38s${RESET} ${DIM}%s${RESET}\n" "dtools → 21"          "Remove ALL stopped containers ⚠"    "docker rm \$(docker ps -aq)"
  printf "  ${GREEN}%-26s${RESET} ${WHITE}%-38s${RESET} ${DIM}%s${RESET}\n" "dtools → 22 / dsh"    "Shell into container"               "docker exec -it <name> bash/sh"
  printf "  ${GREEN}%-26s${RESET} ${WHITE}%-38s${RESET} ${DIM}%s${RESET}\n" "dtools → 23 / dlogs"  "Tail container logs"                "docker logs -f --tail N <name>"
  printf "  ${GREEN}%-26s${RESET} ${WHITE}%-38s${RESET} ${DIM}%s${RESET}\n" "dtools → 24"          "Run command in container"           "docker exec -it <name> <cmd>"
  printf "  ${GREEN}%-26s${RESET} ${WHITE}%-38s${RESET} ${DIM}%s${RESET}\n" "dtools → 25"          "Copy file FROM container"           "docker cp <name>:/path ./local"
  printf "  ${GREEN}%-26s${RESET} ${WHITE}%-38s${RESET} ${DIM}%s${RESET}\n" "dtools → 26"          "Copy file TO container"             "docker cp ./local <name>:/path"
  echo -e "$DIV"

  # ── IMAGES ────────────────────────────────────────────────────
  echo -e "  ${BOLD}${YELLOW}» Images${RESET}"
  printf "  ${GREEN}%-26s${RESET} ${WHITE}%-38s${RESET} ${DIM}%s${RESET}\n" "dtools → 27"          "Pull image from registry"           "docker pull <image:tag>"
  printf "  ${GREEN}%-26s${RESET} ${WHITE}%-38s${RESET} ${DIM}%s${RESET}\n" "dtools → 28"          "Build image from Dockerfile"        "docker build -t <tag> ."
  printf "  ${RED}%-26s${RESET}   ${WHITE}%-38s${RESET} ${DIM}%s${RESET}\n" "dtools → 29"          "Remove local image ⚠"               "docker rmi <image>"
  printf "  ${GREEN}%-26s${RESET} ${WHITE}%-38s${RESET} ${DIM}%s${RESET}\n" "dtools → 30"          "Tag an image"                       "docker tag <src> <new:tag>"
  printf "  ${GREEN}%-26s${RESET} ${WHITE}%-38s${RESET} ${DIM}%s${RESET}\n" "dtools → 31"          "Push image to registry"             "docker push <image:tag>"
  echo -e "$DIV"

  # ── VOLUMES & NETWORKS ────────────────────────────────────────
  echo -e "  ${BOLD}${YELLOW}» Volumes & Networks${RESET}"
  printf "  ${GREEN}%-26s${RESET} ${WHITE}%-38s${RESET} ${DIM}%s${RESET}\n" "dtools → 32"          "List all volumes"                   "docker volume ls"
  printf "  ${RED}%-26s${RESET}   ${WHITE}%-38s${RESET} ${DIM}%s${RESET}\n" "dtools → 33"          "Remove a volume ⚠"                  "docker volume rm <name>"
  printf "  ${GREEN}%-26s${RESET} ${WHITE}%-38s${RESET} ${DIM}%s${RESET}\n" "dtools → 34"          "List all networks"                  "docker network ls"
  printf "  ${RED}%-26s${RESET}   ${WHITE}%-38s${RESET} ${DIM}%s${RESET}\n" "dtools → 35"          "Remove a network ⚠"                 "docker network rm <name>"
  echo -e "$DIV"

  # ── CLEANUP ───────────────────────────────────────────────────
  echo -e "  ${BOLD}${YELLOW}» Cleanup${RESET}"
  printf "  ${MAGENTA}%-26s${RESET} ${WHITE}%-38s${RESET} ${DIM}%s${RESET}\n" "dtools → 36"          "Remove stopped containers"          "docker container prune -f"
  printf "  ${MAGENTA}%-26s${RESET} ${WHITE}%-38s${RESET} ${DIM}%s${RESET}\n" "dtools → 37"          "Remove unused images"               "docker image prune -a -f"
  printf "  ${MAGENTA}%-26s${RESET} ${WHITE}%-38s${RESET} ${DIM}%s${RESET}\n" "dtools → 38"          "Remove unused volumes"              "docker volume prune -f"
  printf "  ${RED}%-26s${RESET}   ${WHITE}%-38s${RESET} ${DIM}%s${RESET}\n"   "dtools → 39 / dprune" "Nuke everything unused ⚠"           "docker system prune -a --volumes -f"
  echo -e "$DIV"

  printf "  ${CYAN}%-26s${RESET} ${WHITE}%-38s${RESET} ${DIM}%s${RESET}\n"  "dtools → 40 / dhelp"  "Show this cheatsheet"               "-"
  printf "  ${CYAN}%-26s${RESET} ${WHITE}%-38s${RESET} ${DIM}%s${RESET}\n"  "dtools"               "Launch interactive menu"            "-"
  echo ""

  echo -e "  ${BOLD}Legend:${RESET}  ${GREEN}■${RESET} Safe   ${MAGENTA}■${RESET} Modifies state   ${RED}■${RESET} Destructive / deletes   ${CYAN}■${RESET} Meta / Tools"
  echo ""
}
