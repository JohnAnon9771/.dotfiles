#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MITAMAE_VERSION="v1.14.4"
MITAMAE_BIN="$DOTFILES_DIR/bin/mitamae"
ARCH="x86_64-linux"

log() { echo -e "\033[1;34m==>\033[0m $*"; }
err() { echo -e "\033[1;31m[ERROR]\033[0m $*" >&2; exit 1; }

# Download mitamae if not present
if [[ ! -x "$MITAMAE_BIN" ]]; then
  log "Downloading mitamae $MITAMAE_VERSION..."
  mkdir -p "$DOTFILES_DIR/bin"
  curl -fsSL \
    "https://github.com/itamae-kitchen/mitamae/releases/download/${MITAMAE_VERSION}/mitamae-${ARCH}.tar.gz" \
    | tar xz -C "$DOTFILES_DIR/bin"
  mv "$DOTFILES_DIR/bin/mitamae-${ARCH}" "$MITAMAE_BIN"
  chmod +x "$MITAMAE_BIN"
  log "mitamae downloaded."
fi

# Detecta o hostname para escolher o node
NODE_FILE="$DOTFILES_DIR/nodes/$(hostname).rb"

if [[ ! -f "$NODE_FILE" ]]; then
  log "No node file found for '$(hostname)'. Using base.rb directly."
  NODE_FILE="$DOTFILES_DIR/base.rb"
fi

log "Running mitamae with node: $NODE_FILE"
"$MITAMAE_BIN" local \
  --log-level="${MITAMAE_LOG_LEVEL:-info}" \
  "$NODE_FILE"

log "Done!"
