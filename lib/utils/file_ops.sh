#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# File Operations - Safe file manipulation
# ═══════════════════════════════════════════════════════════════

source "${LIB_DIR}/utils/logger.sh"

# ── Create Directory ───────────────────────────────────────
ensure_dir() {
  local dir="$1"
  if [[ ! -d "$dir" ]]; then
    mkdir -p "$dir" || {
      log_error "Failed to create directory: $dir"
      return 1
    }
    log_debug "Created directory: $dir"
  fi
  return 0
}

# ── Write File (atomic) ────────────────────────────────────────
write_file() {
  local path="$1"
  local content="$2"
  local dir
  
  # Extract directory
  dir="$(dirname "$path")"
  ensure_dir "$dir" || return 1
  
  # Write atomically using temp file
  local temp
  temp=$(mktemp)
  
  echo "$content" > "$temp" || {
    log_error "Failed to write temp file"
    rm -f "$temp"
    return 1
  }
  
  mv "$temp" "$path" || {
    log_error "Failed to move temp file to: $path"
    rm -f "$temp"
    return 1
  }
  
  log_debug "Wrote file: $path"
  return 0
}

# ── Append to File ───────────────────────────────────────────
append_file() {
  local path="$1"
  local content="$2"
  
  ensure_dir "$(dirname "$path")" || return 1
  echo "$content" >> "$path"
  log_debug "Appended to: $path"
}

# ── Read File ────────────────────────────────────────────────
read_file() {
  local path="$1"
  if [[ -f "$path" ]]; then
    cat "$path"
  fi
}

# ── File Exists ────────────────────────────────────────────
file_exists() {
  [[ -f "$1" ]]
}

# ── Dir Exists ──────────────────────────────────────────────
dir_exists() {
  [[ -d "$1" ]]
}

# ── Copy File ────────────────────────────────────────────────
copy_file() {
  local src="$1"
  local dest="$2"
  
  if [[ ! -f "$src" ]]; then
    log_error "Source not found: $src"
    return 1
  fi
  
  ensure_dir "$(dirname "$dest")" || return 1
  cp "$src" "$dest" || {
    log_error "Failed to copy: $src -> $dest"
    return 1
  }
  
  log_debug "Copied: $src -> $dest"
  return 0
}

# ── Remove File ────────────────────────────────────────────
remove_file() {
  local path="$1"
  
  if [[ -f "$path" ]]; then
    rm -f "$path"
    log_debug "Removed file: $path"
  fi
}

# ── Remove Directory ────────────────────────────────────���───
remove_dir() {
  local path="$1"
  
  if [[ -d "$path" ]]; then
    rm -rf "$path"
    log_debug "Removed directory: $path"
  fi
}

# ── List Files ────────────────────────────────────────────────
list_files() {
  local dir="$1"
  local pattern="${2:-*}"
  
  if [[ -d "$dir" ]]; then
    find "$dir" -maxdepth 1 -type f -name "$pattern" | sort
  fi
}

# ── Count Lines ────────────────────────────────────────────────
count_lines() {
  local path="$1"
  if [[ -f "$path" ]]; then
    wc -l < "$path" | tr -d ' '
  else
    echo "0"
  fi
}

# ── Get Size ────────────────────────────────────────────────
get_size() {
  local path="$1"
  if [[ -f "$path" ]]; then
    stat -f%z "$path" 2>/dev/null || stat -c%s "$path" 2>/dev/null
  elif [[ -d "$path" ]]; then
    du -sh "$path" 2>/dev/null | cut -f1
  else
    echo "0"
  fi
}