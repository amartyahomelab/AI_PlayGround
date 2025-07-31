#!/usr/bin/env bash
# scripts/update_secrets.sh
#
# Usage:
#   scripts/update_secrets.sh en   # Base64-encode all values (only if raw)
#   scripts/update_secrets.sh de   # Base64-decode all values (only if encoded)

set -euo pipefail

if [[ $# -ne 1 || ! $1 =~ ^(en|de)$ ]]; then
  echo "Usage: $0 <en|de>"
  echo "  en  = Base64-encode all raw values"
  echo "  de  = Base64-decode all Base64 values"
  exit 1
fi

MODE=$1
SRC="envs/config/secrets.yaml"
TMP="$(mktemp)"

# --- helpers -------------------------------------------------------------
is_b64() {
  # Quick structural check
  [[ $1 =~ ^([A-Za-z0-9+/]{4})*([A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$ ]] \
    || return 1
  # Round-trip test ( catches “looks like” but not really )
  [[ $(printf '%s' "$1" | base64 --decode 2>/dev/null | base64 | tr -d '\n') == "$1" ]]
}

encode() { printf '%s' "$1" | base64 | tr -d '\n'; }
decode() {  # pad, then decode
  local padded="$1"
  while (( ${#padded} % 4 )); do padded="${padded}="; done
  printf '%s' "$padded" | base64 --decode
}
# -------------------------------------------------------------------------

echo "🔄 $([[ $MODE == en ]] && echo 'Encoding (only raw)' || echo 'Decoding (only b64)') values in $SRC …"

while IFS=: read -r raw_key raw_val; do
  indent="${raw_key%%[![:space:]]*}"
  key="${raw_key#$indent}"
  key="${key%"${key##*[![:space:]]}"}"    # trim trailing spaces
  val="${raw_val# }"
  val="${val%"${val##*[![:space:]]}"}"

  # Pass through comments / blanks unchanged
  if [[ -z $key || ${key:0:1} == "#" ]]; then
    echo "$raw_key:$raw_val" >>"$TMP"
    continue
  fi

  if [[ $MODE == en ]]; then
    new_val=$(is_b64 "$val" && echo "$val" || encode "$val")
  else
    new_val=$(is_b64 "$val" && decode "$val" || echo "$val")
  fi

  echo "${indent}${key}: ${new_val}" >>"$TMP"
done <"$SRC"

mv "$TMP" "$SRC"
echo "✅ Done — no double-encoding, no double-decoding."
