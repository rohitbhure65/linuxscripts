#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# String Utilities - String manipulation helpers
# ═══════════════════════════════════════════════════════════════

# ── To Uppercase ───────────────────────────────────────────
to_upper() {
  echo "$1" | tr '[:lower:]' '[:upper:]'
}

# ── To Lowercase ─────────────────────────────────────────
to_lower() {
  echo "$1" | tr '[:upper:]' '[:lower:]'
}

# ── Capitalize ───────────────────────────────────────────
capitalize() {
  local str="$1"
  echo "$(to_upper "${str:0:1}")${str:1}"
}

# ── Trim Whitespace ────────────────────────────────────────
trim() {
  echo "$1" | xargs
}

# ── Contains ────────────────────────────────────────────
contains() {
  local haystack="$1"
  local needle="$2"
  [[ "$haystack" == *"$needle"* ]]
}

# ── Starts With ─────────────────────────────────────────
starts_with() {
  local str="$1"
  local prefix="$2"
  [[ "$str" == "$prefix"* ]]
}

# ── Ends With ─────────────────────────────────────────
ends_with() {
  local str="$1"
  local suffix="$2"
  [[ "$str" == *"$suffix" ]]
}

# ── Replace ───────────────────────────────────────────
replace() {
  local str="$1"
  local old="$2"
  local new="$3"
  echo "${str//"$old"/"$new"}"
}

# ── Split ───────────────────────────────────────────
split() {
  local str="$1"
  local delim="$2"
  echo "$str" | tr "$delim" '\n'
}

# ── Join ───────────────────────────────────────────
join() {
  local delim="$1"
  shift
  echo -n "$*" | tr ' ' "$delim"
}

# ── Repeat ───────────────────────────────────────────
repeat() {
  local char="$1"
  local count="$2"
  printf "%${count}s" | tr ' ' "$char"
}

# ── Pad ───────────────────────────────────────────
pad() {
  local str="$1"
  local width="$2"
  local char="${3:- }"
  local len=${#str}
  local pad_len=$((width - len))
  
  if [[ $pad_len -gt 0 ]]; then
    echo "$str$(repeat "$char" "$pad_len")"
  else
    echo "$str"
  fi
}

# ── Truncate ─────────────────────────────────────────
truncate() {
  local str="$1"
  local width="$2"
  local ellipsis="${3:-...}"
  
  if [[ ${#str} -gt $width ]]; then
    echo "${str:0:$((width - ${#ellipsis}))}$ellipsis"
  else
    echo "$str"
  fi
}

# ── Slugify ─────────────────────────────────────────
slugify() {
  local str="$1"
  str=$(to_lower "$str")
  str=$(replace "$str" " " "-")
  str=$(replace "$str" "[^a-z0-9-]" "")
  echo "$str"
}

# ── CamelCase ─────────────────────────────────────────
camel_case() {
  local str="$1"
  local result=""
  local first=1
  
  for word in $(split "$str" " "); do
    if [[ $first -eq 1 ]]; then
      result=$(to_lower "$word")
      first=0
    else
      result="${result}$(capitalize "$word")"
    fi
  done
  
  echo "$result"
}

# ── Snake Case ─────────────────────────────────────────
snake_case() {
  local str="$1"
  str=$(to_lower "$str")
  str=$(replace "$str" " " "_")
  str=$(replace "$str" "-" "_")
  echo "$str"
}

# ── Kebab Case ─────────────────────────────────────────
kebab_case() {
  local str="$1"
  str=$(to_lower "$str")
  str=$(replace "$str" " " "-")
  str=$(replace "$str" "_" "-")
  echo "$str"
}

# ── Hash (simple) ─────────────────────────────────────────
hash() {
  echo -n "$1" | md5sum | cut -d' ' -f1
}

# ── Random String ─────────────────────────────────────────
random_string() {
  local length="${1:-16}"
  tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c "$length"
}

# ── Escape ───────────────────────────────────────────
escape() {
  local str="$1"
  str=$(replace "$str" '\' '\\')
  str=$(replace "$str" '"' '\"')
  echo "$str"
}

# ── Unescape ─────────────────────────────────────────
unescape() {
  local str="$1"
  str=$(replace "$str" '\\' '\')
  str=$(replace "$str" '\"' '"')
  echo "$str"
}