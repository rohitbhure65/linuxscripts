#!/bin/bash

# ─────────────────────────────────────────────────────────────────
# gtools — Interactive Git Toolkit
# Add to ~/.bashrc:
#   source ~/.gtools.sh
# Then run:
#   gtools
# ─────────────────────────────────────────────────────────────────

# =========================
# Git Aliases
# =========================
alias gst='git status'
alias gad='git add .'
alias gps='git push'
alias gpl='git pull'
alias gco='git checkout'
alias gcb='git checkout -b'
alias glog='git log --oneline --graph --all'
alias glogs='git log --stat'
alias glogc='git log --oneline --decorate --source --pretty=format:"%Cblue %h %Cgreen %ar %Cblue %an %Cyellow %d %Creset %s" --all --graph'
alias gvv='git branch -vv'
alias grmcache='git rm --cached'
alias grmforce='git rm --force'

# =========================
# Git Helper Functions
# =========================

gcm() {
  if [[ -z "$1" ]]; then read -rp "Commit message: " MSG; git commit -m "$MSG"
  else git commit -m "$1"; fi
}

gem() {
  if [[ -z "$1" ]]; then read -rp "Empty commit message: " MSG; git commit --allow-empty -m "$MSG"
  else git commit --allow-empty -m "$1"; fi
}

gac() {
  if [[ -z "$1" ]]; then read -rp "Commit message: " MSG; else MSG="$1"; fi
  git add . && git commit -m "$MSG"
}

gacp() {
  if [[ -z "$1" ]]; then read -rp "Commit message: " MSG; else MSG="$1"; fi
  git add . && git commit -m "$MSG" && git push
}

gnewtag() {
  if [[ -z "$1" ]]; then read -rp "Tag name (e.g. v1.0.0): " TAG; else TAG="$1"; fi
  git tag -a "$TAG" -m "Release $TAG"
  git push origin "$TAG"
  git push --tags
  echo "✓ Tag $TAG pushed"
}

gaddp() { git add -p "$@"; }

gnewbranch() {
  if [[ -z "$1" ]]; then read -rp "New branch name: " BRANCH; else BRANCH="$1"; fi
  git switch -c "$BRANCH"
}

gtrack() {
  if [[ -z "$1" ]]; then read -rp "Branch to track on origin: " BRANCH; else BRANCH="$1"; fi
  git branch --set-upstream-to=origin/"$BRANCH" "$BRANCH"
}

gpushu() {
  if [[ -z "$1" ]]; then BRANCH=$(git rev-parse --abbrev-ref HEAD); echo "Using current: $BRANCH"
  else BRANCH="$1"; fi
  git push -u origin "$BRANCH"
}

gbdel() {
  if [[ -z "$1" ]]; then git branch; read -rp "Branch to delete locally: " BRANCH; else BRANCH="$1"; fi
  git branch -d "$BRANCH"
}

gbdelr() {
  if [[ -z "$1" ]]; then git branch -r; read -rp "Remote branch to delete (without origin/): " BRANCH; else BRANCH="$1"; fi
  git push origin --delete "$BRANCH" && echo "✓ Deleted origin/$BRANCH"
}

grevert-head()     { git revert --no-commit HEAD; }
grevert-last2()    { git revert --no-commit HEAD~2..HEAD; }
grevert-continue() { git revert --continue; }
grevert-abort()    { git revert --abort; }

grevert-range() {
  if [[ -z "$1" || -z "$2" ]]; then
    read -rp "Start commit hash: " START
    read -rp "End commit hash: " END
    git revert --no-commit "$START^..$END"
  else git revert --no-commit "$1^..$2"; fi
}

greset-soft()  { git reset --soft  HEAD~1; }
greset-hard()  { git reset --hard  HEAD~1; }
greset-mixed() { git reset --mixed HEAD~1; }

greset-to() {
  if [[ -z "$1" ]]; then
    git log --oneline -10
    read -rp "Reset to commit hash: " HASH
    git reset --soft "$HASH"
  else git reset --soft "$1"; fi
}

gss() {
  if [[ -z "$1" ]]; then read -rp "Stash message: " MSG; git stash push -m "$MSG"
  else git stash push -m "$1"; fi
}

gsp() { git stash pop; }
gsl() { git stash list; }


# ─────────────────────────────────────────────────────────────────
# gtools — Interactive Menu
# ─────────────────────────────────────────────────────────────────
gtools() {

  local RED='\033[0;31m'
  local GREEN='\033[0;32m'
  local YELLOW='\033[1;33m'
  local CYAN='\033[0;36m'
  local MAGENTA='\033[0;35m'
  local BOLD='\033[1m'
  local DIM='\033[2m'
  local WHITE='\033[1;37m'
  local RESET='\033[0m'

  # ── Helpers ─────────────────────────────────────────────────────
  _need_git() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
      echo -e "${RED}  ✗ Not inside a git repository.${RESET}"
      return 1
    fi
  }

  _confirm_destructive() {
    echo -e "${RED}  ⚠ This is a destructive operation. Type 'yes' to confirm:${RESET}"
    read -rp "  > " _DESTR
    [[ "$_DESTR" != "yes" ]] && echo -e "${RED}  Aborted.${RESET}" && return 1
    return 0
  }

  # ════════════════════════════════════════════════════════════════
  # SECTION A: BASIC
  # ════════════════════════════════════════════════════════════════

  _gst()   { _need_git || return; git status; }
  _gad()   { _need_git || return; git add . && echo -e "${GREEN}  ✓ All files staged.${RESET}"; }
  _gps()   { _need_git || return; git push; }
  _gpl()   { _need_git || return; git pull; }
  _glog()  { _need_git || return; git log --oneline --graph --all; }
  _glogs() { _need_git || return; git log --stat; }
  _glogc() { _need_git || return; git log --oneline --decorate --source --pretty=format:"%Cblue %h %Cgreen %ar %Cblue %an %Cyellow %d %Creset %s" --all --graph; }
  _gvv()   { _need_git || return; git branch -vv; }

  _gco() {
    _need_git || return
    echo -e "${YELLOW}  Available branches:${RESET}"
    git branch -a
    echo ""
    read -rp "  Branch to checkout: " BR
    [[ -z "$BR" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1
    git checkout "$BR"
  }

  _gcb() {
    _need_git || return
    read -rp "  New branch name: " BR
    [[ -z "$BR" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1
    git checkout -b "$BR"
    echo -e "${GREEN}  ✓ Switched to new branch '${BR}'.${RESET}"
  }

  # ════════════════════════════════════════════════════════════════
  # SECTION B: COMMIT
  # ════════════════════════════════════════════════════════════════

  _gcm() {
    _need_git || return
    read -rp "  Commit message: " MSG
    [[ -z "$MSG" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1
    git commit -m "$MSG"
  }

  _gem() {
    _need_git || return
    read -rp "  Empty commit message: " MSG
    [[ -z "$MSG" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1
    git commit --allow-empty -m "$MSG"
  }

  _gac() {
    _need_git || return
    read -rp "  Commit message: " MSG
    [[ -z "$MSG" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1
    git add . && git commit -m "$MSG"
  }

  _gacp() {
    _need_git || return
    read -rp "  Commit message: " MSG
    [[ -z "$MSG" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1
    git add . && git commit -m "$MSG" && git push
    echo -e "${GREEN}  ✓ Staged → Committed → Pushed.${RESET}"
  }

  # ════════════════════════════════════════════════════════════════
  # SECTION C: BRANCH
  # ════════════════════════════════════════════════════════════════

  _gnewbranch() {
    _need_git || return
    read -rp "  New branch name: " BR
    [[ -z "$BR" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1
    git switch -c "$BR"
    echo -e "${GREEN}  ✓ Created and switched to '${BR}'.${RESET}"
  }

  _gpushu() {
    _need_git || return
    local CUR=$(git rev-parse --abbrev-ref HEAD)
    echo -e "${YELLOW}  Current branch: ${GREEN}${CUR}${RESET}"
    read -rp "  Push which branch? (Enter = current): " BR
    BR="${BR:-$CUR}"
    git push -u origin "$BR"
    echo -e "${GREEN}  ✓ Pushed and tracking origin/${BR}.${RESET}"
  }

  _gtrack() {
    _need_git || return
    read -rp "  Branch to track on origin: " BR
    [[ -z "$BR" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1
    git branch --set-upstream-to=origin/"$BR" "$BR"
    echo -e "${GREEN}  ✓ Tracking set.${RESET}"
  }

  _gbdel() {
    _need_git || return
    echo -e "${YELLOW}  Local branches:${RESET}"
    git branch
    echo ""
    read -rp "  Branch to delete locally: " BR
    [[ -z "$BR" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1
    git branch -d "$BR"
  }

  _gbdelr() {
    _need_git || return
    echo -e "${YELLOW}  Remote branches:${RESET}"
    git branch -r
    echo ""
    read -rp "  Remote branch to delete (without origin/): " BR
    [[ -z "$BR" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1
    _confirm_destructive || return 1
    git push origin --delete "$BR" && echo -e "${GREEN}  ✓ Deleted origin/${BR}.${RESET}"
  }

  _gnewtag() {
    _need_git || return
    read -rp "  Tag name (e.g. v1.0.0): " TAG
    [[ -z "$TAG" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1
    git tag -a "$TAG" -m "Release $TAG"
    git push origin "$TAG"
    git push --tags
    echo -e "${GREEN}  ✓ Tag ${TAG} created and pushed.${RESET}"
  }

  _gaddp() {
    _need_git || return
    echo -e "${DIM}  Interactive patch staging — use y/n/s/q to select hunks${RESET}"
    git add -p
  }

  # ════════════════════════════════════════════════════════════════
  # SECTION D: RESET
  # ════════════════════════════════════════════════════════════════

  _greset_soft() {
    _need_git || return
    echo -e "${DIM}  Undoes last commit, keeps changes staged.${RESET}"
    _confirm_destructive || return 1
    git reset --soft HEAD~1
    echo -e "${GREEN}  ✓ Soft reset done.${RESET}"
  }

  _greset_mixed() {
    _need_git || return
    echo -e "${DIM}  Undoes last commit, keeps changes unstaged.${RESET}"
    _confirm_destructive || return 1
    git reset --mixed HEAD~1
    echo -e "${GREEN}  ✓ Mixed reset done.${RESET}"
  }

  _greset_hard() {
    _need_git || return
    echo -e "${RED}  ⚠ HARD RESET — all uncommitted changes will be LOST permanently!${RESET}"
    _confirm_destructive || return 1
    git reset --hard HEAD~1
    echo -e "${GREEN}  ✓ Hard reset done.${RESET}"
  }

  _greset_to() {
    _need_git || return
    echo -e "${YELLOW}  Recent commits:${RESET}"
    git log --oneline -10
    echo ""
    read -rp "  Reset to commit hash: " HASH
    [[ -z "$HASH" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1
    _confirm_destructive || return 1
    git reset --soft "$HASH"
    echo -e "${GREEN}  ✓ Reset to ${HASH}.${RESET}"
  }

  # ════════════════════════════════════════════════════════════════
  # SECTION E: REVERT
  # ════════════════════════════════════════════════════════════════

  _grevert_head() {
    _need_git || return
    echo -e "${DIM}  Reverts HEAD commit without auto-committing.${RESET}"
    git revert --no-commit HEAD
    echo -e "${GREEN}  ✓ HEAD reverted. Review changes, then commit.${RESET}"
  }

  _grevert_last2() {
    _need_git || return
    echo -e "${DIM}  Reverts last 2 commits without auto-committing.${RESET}"
    git revert --no-commit HEAD~2..HEAD
    echo -e "${GREEN}  ✓ Last 2 commits reverted. Review changes, then commit.${RESET}"
  }

  _grevert_range() {
    _need_git || return
    echo -e "${YELLOW}  Recent commits:${RESET}"
    git log --oneline -10
    echo ""
    read -rp "  Start commit hash: " START
    read -rp "  End commit hash  : " END
    [[ -z "$START" || -z "$END" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1
    git revert --no-commit "$START^..$END"
    echo -e "${GREEN}  ✓ Range reverted. Review changes, then commit.${RESET}"
  }

  _grevert_continue() { _need_git || return; git revert --continue; }
  _grevert_abort()    { _need_git || return; git revert --abort && echo -e "${GREEN}  ✓ Revert aborted.${RESET}"; }

  # ════════════════════════════════════════════════════════════════
  # SECTION F: STASH
  # ════════════════════════════════════════════════════════════════

  _gss() {
    _need_git || return
    read -rp "  Stash message: " MSG
    [[ -z "$MSG" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1
    git stash push -m "$MSG"
    echo -e "${GREEN}  ✓ Work stashed.${RESET}"
  }

  _gsp() {
    _need_git || return
    git stash list
    echo ""
    git stash pop
    echo -e "${GREEN}  ✓ Stash popped.${RESET}"
  }

  _gsl() { _need_git || return; git stash list; }

  _gstash_drop() {
    _need_git || return
    git stash list
    echo ""
    read -rp "  Stash index to drop (e.g. 0): " IDX
    [[ -z "$IDX" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1
    git stash drop stash@{"$IDX"}
    echo -e "${GREEN}  ✓ stash@{${IDX}} dropped.${RESET}"
  }

  _gstash_apply() {
    _need_git || return
    git stash list
    echo ""
    read -rp "  Stash index to apply (e.g. 0, Enter = latest): " IDX
    if [[ -z "$IDX" ]]; then
      git stash apply
    else
      git stash apply stash@{"$IDX"}
    fi
    echo -e "${GREEN}  ✓ Stash applied (not dropped).${RESET}"
  }

  # ════════════════════════════════════════════════════════════════
  # SECTION G: FILE OPS
  # ════════════════════════════════════════════════════════════════

  _grmcache() {
    _need_git || return
    read -rp "  File to untrack (keep on disk): " FILE
    [[ -z "$FILE" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1
    git rm --cached "$FILE"
    echo -e "${GREEN}  ✓ '${FILE}' untracked.${RESET}"
  }

  _grmforce() {
    _need_git || return
    read -rp "  File to force-delete from git: " FILE
    [[ -z "$FILE" ]] && echo -e "${RED}  ✗ Empty.${RESET}" && return 1
    _confirm_destructive || return 1
    git rm --force "$FILE"
    echo -e "${GREEN}  ✓ '${FILE}' force deleted.${RESET}"
  }

  # ════════════════════════════════════════════════════════════════
  # MAIN MENU
  # ════════════════════════════════════════════════════════════════
  while true; do
    echo ""
    echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║            🔧  gtools — Git Interactive Toolkit             ║${RESET}"
    echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${BOLD}${YELLOW}  ━━ BASIC ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${GREEN} 1)${RESET} 📋  Status              ${DIM}-- git status${RESET}"
    echo -e "  ${GREEN} 2)${RESET} ➕  Stage all files     ${DIM}-- git add .${RESET}"
    echo -e "  ${GREEN} 3)${RESET} ⬆️   Push               ${DIM}-- git push${RESET}"
    echo -e "  ${GREEN} 4)${RESET} ⬇️   Pull               ${DIM}-- git pull${RESET}"
    echo -e "  ${GREEN} 5)${RESET} 🔀  Checkout branch     ${DIM}-- git checkout <branch>${RESET}"
    echo -e "  ${GREEN} 6)${RESET} 🌿  Create new branch   ${DIM}-- git checkout -b <branch>${RESET}"
    echo -e "  ${GREEN} 7)${RESET} 📊  Log graph           ${DIM}-- git log --oneline --graph --all${RESET}"
    echo -e "  ${GREEN} 8)${RESET} 📈  Log with stats      ${DIM}-- git log --stat${RESET}"
    echo -e "  ${GREEN} 9)${RESET} 🎨  Log colorful        ${DIM}-- git log --pretty=format:... --graph${RESET}"
    echo -e "  ${GREEN}10)${RESET} 🔗  Branch tracking     ${DIM}-- git branch -vv${RESET}"
    echo ""
    echo -e "${BOLD}${YELLOW}  ━━ COMMIT ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${GREEN}11)${RESET} 💾  Commit staged       ${DIM}-- git commit -m <msg>${RESET}"
    echo -e "  ${GREEN}12)${RESET} 🕳   Empty commit        ${DIM}-- git commit --allow-empty -m <msg>${RESET}"
    echo -e "  ${GREEN}13)${RESET} ⚡  Stage + Commit      ${DIM}-- git add . && git commit -m <msg>${RESET}"
    echo -e "  ${CYAN}14)${RESET} 🚀  Stage + Commit + Push${DIM}-- git add . && git commit -m && git push${RESET}"
    echo ""
    echo -e "${BOLD}${YELLOW}  ━━ BRANCH ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${GREEN}15)${RESET} 🌿  New branch (switch) ${DIM}-- git switch -c <branch>${RESET}"
    echo -e "  ${GREEN}16)${RESET} 📤  Push + set upstream ${DIM}-- git push -u origin <branch>${RESET}"
    echo -e "  ${GREEN}17)${RESET} 🔗  Track remote branch ${DIM}-- git branch --set-upstream-to${RESET}"
    echo -e "  ${RED}18)${RESET} 🗑   Delete local branch  ${DIM}-- git branch -d <branch>${RESET}"
    echo -e "  ${RED}19)${RESET} 🗑   Delete remote branch ${DIM}-- git push origin --delete <branch>${RESET}"
    echo -e "  ${GREEN}20)${RESET} 🏷   Create & push tag   ${DIM}-- git tag -a <tag> && git push --tags${RESET}"
    echo -e "  ${GREEN}21)${RESET} 🧩  Patch stage (hunk)  ${DIM}-- git add -p${RESET}"
    echo ""
    echo -e "${BOLD}${YELLOW}  ━━ RESET ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${MAGENTA}22)${RESET} ↩️   Reset soft          ${DIM}-- git reset --soft HEAD~1  (keeps staged)${RESET}"
    echo -e "  ${MAGENTA}23)${RESET} ↩️   Reset mixed         ${DIM}-- git reset --mixed HEAD~1 (keeps unstaged)${RESET}"
    echo -e "  ${RED}24)${RESET} 💀  Reset hard ⚠         ${DIM}-- git reset --hard HEAD~1 (discards all)${RESET}"
    echo -e "  ${MAGENTA}25)${RESET} 🎯  Reset to hash       ${DIM}-- git reset --soft <hash>${RESET}"
    echo ""
    echo -e "${BOLD}${YELLOW}  ━━ REVERT ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${MAGENTA}26)${RESET} ⏪  Revert HEAD         ${DIM}-- git revert --no-commit HEAD${RESET}"
    echo -e "  ${MAGENTA}27)${RESET} ⏪  Revert last 2       ${DIM}-- git revert --no-commit HEAD~2..HEAD${RESET}"
    echo -e "  ${MAGENTA}28)${RESET} 🎯  Revert range        ${DIM}-- git revert --no-commit <a>^..<b>${RESET}"
    echo -e "  ${GREEN}29)${RESET} ✅  Revert continue      ${DIM}-- git revert --continue${RESET}"
    echo -e "  ${RED}30)${RESET} ❌  Revert abort         ${DIM}-- git revert --abort${RESET}"
    echo ""
    echo -e "${BOLD}${YELLOW}  ━━ STASH ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${GREEN}31)${RESET} 📦  Stash save           ${DIM}-- git stash push -m <msg>${RESET}"
    echo -e "  ${GREEN}32)${RESET} 📤  Stash pop            ${DIM}-- git stash pop${RESET}"
    echo -e "  ${GREEN}33)${RESET} 📋  Stash list           ${DIM}-- git stash list${RESET}"
    echo -e "  ${GREEN}34)${RESET} 🔍  Stash apply (keep)   ${DIM}-- git stash apply stash@{n}${RESET}"
    echo -e "  ${RED}35)${RESET} 🗑   Stash drop           ${DIM}-- git stash drop stash@{n}${RESET}"
    echo ""
    echo -e "${BOLD}${YELLOW}  ━━ FILE OPS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${RED}36)${RESET} 🚫  Untrack file         ${DIM}-- git rm --cached <file>${RESET}"
    echo -e "  ${RED}37)${RESET} 💥  Force delete file ⚠  ${DIM}-- git rm --force <file>${RESET}"
    echo ""
    echo -e "${BOLD}${YELLOW}  ━━ HELP ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "  ${CYAN}38)${RESET} 📖  Show cheatsheet      ${DIM}-- ghelp${RESET}"
    echo ""
    echo -e "  ${RED} 0)${RESET} 🚪  Exit"
    echo ""
    read -rp "  Choose option [0-38]: " CHOICE

    echo ""
    case "$CHOICE" in
       1) _gst ;;
       2) _gad ;;
       3) _gps ;;
       4) _gpl ;;
       5) _gco ;;
       6) _gcb ;;
       7) _glog ;;
       8) _glogs ;;
       9) _glogc ;;
      10) _gvv ;;
      11) _gcm ;;
      12) _gem ;;
      13) _gac ;;
      14) _gacp ;;
      15) _gnewbranch ;;
      16) _gpushu ;;
      17) _gtrack ;;
      18) _gbdel ;;
      19) _gbdelr ;;
      20) _gnewtag ;;
      21) _gaddp ;;
      22) _greset_soft ;;
      23) _greset_mixed ;;
      24) _greset_hard ;;
      25) _greset_to ;;
      26) _grevert_head ;;
      27) _grevert_last2 ;;
      28) _grevert_range ;;
      29) _grevert_continue ;;
      30) _grevert_abort ;;
      31) _gss ;;
      32) _gsp ;;
      33) _gsl ;;
      34) _gstash_apply ;;
      35) _gstash_drop ;;
      36) _grmcache ;;
      37) _grmforce ;;
      38) ghelp ;;
       0) echo -e "${CYAN}  Goodbye! 🔧${RESET}"; echo ""; return 0 ;;
       *) echo -e "${RED}  ✗ Invalid option. Choose 0-38.${RESET}" ;;
    esac

    echo ""
    read -rp "  Press Enter to return to menu..." _PAUSE
  done
}


# ─────────────────────────────────────────────────────────────────
# ghelp — Git Cheatsheet  (just type: ghelp)
# ─────────────────────────────────────────────────────────────────
ghelp() {
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
  echo -e "${BOLD}${CYAN}║           🔧  gtools — Git Cheatsheet                       ║${RESET}"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
  echo ""

  printf "  ${BOLD}${WHITE}%-24s %-40s %s${RESET}\n" "OPTION / ALIAS" "WHAT IT DOES" "ACTUAL GIT COMMAND"
  echo -e "$DIV"

  # ── BASIC ──────────────────────────────────────────────────────
  echo -e "  ${BOLD}${YELLOW}» Basic${RESET}"
  printf "  ${GREEN}%-24s${RESET} ${WHITE}%-40s${RESET} ${DIM}%s${RESET}\n" "gtools → 1  / gst"   "Check current changes & state"      "git status"
  printf "  ${GREEN}%-24s${RESET} ${WHITE}%-40s${RESET} ${DIM}%s${RESET}\n" "gtools → 2  / gad"   "Stage all changed files"            "git add ."
  printf "  ${GREEN}%-24s${RESET} ${WHITE}%-40s${RESET} ${DIM}%s${RESET}\n" "gtools → 3  / gps"   "Push commits to remote"             "git push"
  printf "  ${GREEN}%-24s${RESET} ${WHITE}%-40s${RESET} ${DIM}%s${RESET}\n" "gtools → 4  / gpl"   "Pull latest from remote"            "git pull"
  printf "  ${GREEN}%-24s${RESET} ${WHITE}%-40s${RESET} ${DIM}%s${RESET}\n" "gtools → 5  / gco"   "Switch to existing branch"          "git checkout <branch>"
  printf "  ${GREEN}%-24s${RESET} ${WHITE}%-40s${RESET} ${DIM}%s${RESET}\n" "gtools → 6  / gcb"   "Create + switch to new branch"      "git checkout -b <branch>"
  printf "  ${GREEN}%-24s${RESET} ${WHITE}%-40s${RESET} ${DIM}%s${RESET}\n" "gtools → 7  / glog"  "Visual branch/commit graph"         "git log --oneline --graph --all"
  printf "  ${GREEN}%-24s${RESET} ${WHITE}%-40s${RESET} ${DIM}%s${RESET}\n" "gtools → 8  / glogs" "Log with file change counts"        "git log --stat"
  printf "  ${GREEN}%-24s${RESET} ${WHITE}%-40s${RESET} ${DIM}%s${RESET}\n" "gtools → 9  / glogc" "Colorful decorated graph log"       "git log --pretty=format:... --graph"
  printf "  ${GREEN}%-24s${RESET} ${WHITE}%-40s${RESET} ${DIM}%s${RESET}\n" "gtools → 10 / gvv"   "See branch + tracking remote"       "git branch -vv"
  echo -e "$DIV"

  # ── COMMIT ─────────────────────────────────────────────────────
  echo -e "  ${BOLD}${YELLOW}» Commit${RESET}"
  printf "  ${GREEN}%-24s${RESET} ${WHITE}%-40s${RESET} ${DIM}%s${RESET}\n" "gtools → 11 / gcm"   "Commit staged files"                "git commit -m <msg>"
  printf "  ${GREEN}%-24s${RESET} ${WHITE}%-40s${RESET} ${DIM}%s${RESET}\n" "gtools → 12 / gem"   "Commit with no file changes"        "git commit --allow-empty -m <msg>"
  printf "  ${GREEN}%-24s${RESET} ${WHITE}%-40s${RESET} ${DIM}%s${RESET}\n" "gtools → 13 / gac"   "Stage all + commit"                 "git add . && git commit -m <msg>"
  printf "  ${CYAN}%-24s${RESET}  ${WHITE}%-40s${RESET} ${DIM}%s${RESET}\n" "gtools → 14 / gacp ⚡" "Stage + commit + push (one shot)"  "git add . && git commit -m && git push"
  echo -e "$DIV"

  # ── BRANCH ─────────────────────────────────────────────────────
  echo -e "  ${BOLD}${YELLOW}» Branch${RESET}"
  printf "  ${GREEN}%-24s${RESET} ${WHITE}%-40s${RESET} ${DIM}%s${RESET}\n" "gtools → 15 / gnewbranch" "Create + switch to new branch"  "git switch -c <branch>"
  printf "  ${GREEN}%-24s${RESET} ${WHITE}%-40s${RESET} ${DIM}%s${RESET}\n" "gtools → 16 / gpushu"     "Push + set upstream"            "git push -u origin <branch>"
  printf "  ${GREEN}%-24s${RESET} ${WHITE}%-40s${RESET} ${DIM}%s${RESET}\n" "gtools → 17 / gtrack"     "Link local to remote branch"    "git branch --set-upstream-to"
  printf "  ${RED}%-24s${RESET}   ${WHITE}%-40s${RESET} ${DIM}%s${RESET}\n" "gtools → 18 / gbdel"      "Delete branch locally"          "git branch -d <branch>"
  printf "  ${RED}%-24s${RESET}   ${WHITE}%-40s${RESET} ${DIM}%s${RESET}\n" "gtools → 19 / gbdelr"     "Delete branch on remote"        "git push origin --delete <branch>"
  printf "  ${GREEN}%-24s${RESET} ${WHITE}%-40s${RESET} ${DIM}%s${RESET}\n" "gtools → 20 / gnewtag"    "Create tag + push to remote"    "git tag -a <tag> && git push --tags"
  printf "  ${GREEN}%-24s${RESET} ${WHITE}%-40s${RESET} ${DIM}%s${RESET}\n" "gtools → 21 / gaddp"      "Interactive patch staging"      "git add -p"
  echo -e "$DIV"

  # ── RESET ──────────────────────────────────────────────────────
  echo -e "  ${BOLD}${YELLOW}» Reset${RESET}"
  printf "  ${MAGENTA}%-24s${RESET} ${WHITE}%-40s${RESET} ${DIM}%s${RESET}\n" "gtools → 22 / greset-soft"  "Undo commit, keep staged"     "git reset --soft HEAD~1"
  printf "  ${MAGENTA}%-24s${RESET} ${WHITE}%-40s${RESET} ${DIM}%s${RESET}\n" "gtools → 23 / greset-mixed" "Undo commit, keep unstaged"   "git reset --mixed HEAD~1"
  printf "  ${RED}%-24s${RESET}   ${WHITE}%-40s${RESET} ${DIM}%s${RESET}\n"   "gtools → 24 / greset-hard"  "Undo commit + discard all ⚠"  "git reset --hard HEAD~1"
  printf "  ${MAGENTA}%-24s${RESET} ${WHITE}%-40s${RESET} ${DIM}%s${RESET}\n" "gtools → 25 / greset-to"    "Reset to any commit hash"     "git reset --soft <hash>"
  echo -e "$DIV"

  # ── REVERT ─────────────────────────────────────────────────────
  echo -e "  ${BOLD}${YELLOW}» Revert${RESET}"
  printf "  ${MAGENTA}%-24s${RESET} ${WHITE}%-40s${RESET} ${DIM}%s${RESET}\n" "gtools → 26 / grevert-head"     "Undo HEAD, no auto-commit"  "git revert --no-commit HEAD"
  printf "  ${MAGENTA}%-24s${RESET} ${WHITE}%-40s${RESET} ${DIM}%s${RESET}\n" "gtools → 27 / grevert-last2"    "Undo last 2 commits"        "git revert --no-commit HEAD~2..HEAD"
  printf "  ${MAGENTA}%-24s${RESET} ${WHITE}%-40s${RESET} ${DIM}%s${RESET}\n" "gtools → 28 / grevert-range"    "Undo a commit range"        "git revert --no-commit <a>^..<b>"
  printf "  ${GREEN}%-24s${RESET}  ${WHITE}%-40s${RESET} ${DIM}%s${RESET}\n"  "gtools → 29 / grevert-continue" "Continue after conflicts"   "git revert --continue"
  printf "  ${RED}%-24s${RESET}   ${WHITE}%-40s${RESET} ${DIM}%s${RESET}\n"   "gtools → 30 / grevert-abort"    "Cancel the revert"          "git revert --abort"
  echo -e "$DIV"

  # ── STASH ──────────────────────────────────────────────────────
  echo -e "  ${BOLD}${YELLOW}» Stash${RESET}"
  printf "  ${GREEN}%-24s${RESET} ${WHITE}%-40s${RESET} ${DIM}%s${RESET}\n" "gtools → 31 / gss"  "Save work temporarily"              "git stash push -m <msg>"
  printf "  ${GREEN}%-24s${RESET} ${WHITE}%-40s${RESET} ${DIM}%s${RESET}\n" "gtools → 32 / gsp"  "Restore + remove last stash"        "git stash pop"
  printf "  ${GREEN}%-24s${RESET} ${WHITE}%-40s${RESET} ${DIM}%s${RESET}\n" "gtools → 33 / gsl"  "See all saved stashes"              "git stash list"
  printf "  ${GREEN}%-24s${RESET} ${WHITE}%-40s${RESET} ${DIM}%s${RESET}\n" "gtools → 34"        "Apply stash, keep it in list"       "git stash apply stash@{n}"
  printf "  ${RED}%-24s${RESET}   ${WHITE}%-40s${RESET} ${DIM}%s${RESET}\n" "gtools → 35"        "Drop a specific stash ⚠"            "git stash drop stash@{n}"
  echo -e "$DIV"

  # ── FILE OPS ───────────────────────────────────────────────────
  echo -e "  ${BOLD}${YELLOW}» File Operations${RESET}"
  printf "  ${RED}%-24s${RESET} ${WHITE}%-40s${RESET} ${DIM}%s${RESET}\n" "gtools → 36 / grmcache" "Untrack file, keep on disk"     "git rm --cached <file>"
  printf "  ${RED}%-24s${RESET} ${WHITE}%-40s${RESET} ${DIM}%s${RESET}\n" "gtools → 37 / grmforce" "Force delete tracked file ⚠"    "git rm --force <file>"
  echo -e "$DIV"

  printf "  ${CYAN}%-24s${RESET} ${WHITE}%-40s${RESET} ${DIM}%s${RESET}\n"  "gtools → 38 / ghelp"   "Show this cheatsheet"           "-"
  printf "  ${CYAN}%-24s${RESET} ${WHITE}%-40s${RESET} ${DIM}%s${RESET}\n"  "gtools"                 "Launch interactive menu"        "-"
  echo ""

  echo -e "  ${BOLD}Legend:${RESET}  ${GREEN}■${RESET} Safe   ${MAGENTA}■${RESET} Rewrites history   ${RED}■${RESET} Destructive / deletes   ${CYAN}■${RESET} Meta / Tools"
  echo ""
}
