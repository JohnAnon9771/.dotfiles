#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MITAMAE_VERSION="v1.14.4"
MITAMAE_BIN="$DOTFILES_DIR/bin/mitamae"
ARCH="x86_64-linux"

DRY_RUN=false

show_help() {
  cat << EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  --dry-run    Show what would be done without making changes
  -h, --help   Show this help message

Examples:
  $(basename "$0")              # Run normally
  $(basename "$0") --dry-run    # Dry-run mode
EOF
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      exit 1
      ;;
  esac
done

log() { echo -e "\033[1;34m==>\033[0m $*"; }
err() { echo -e "\033[1;31m[ERROR]\033[0m $*" >&2; exit 1; }

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

NODE_FILE="$DOTFILES_DIR/nodes/$(hostname).rb"

if [[ ! -f "$NODE_FILE" ]]; then
  NODE_FILE="$DOTFILES_DIR/nodes/archlinux.rb"
  log "No node file for '$(hostname)'. Using archlinux.rb fallback."
fi

if [[ ! -f "$NODE_FILE" ]]; then
  log "No node file found. Using base.rb."
  NODE_FILE="$DOTFILES_DIR/base.rb"
fi

log "Running mitamae with node: $NODE_FILE"

MITAMAE_ARGS=("local" "--log-level=${MITAMAE_LOG_LEVEL:-info}")

if [[ "$DRY_RUN" == "true" ]]; then
  MITAMAE_ARGS+=("--dry-run")
  log "DRY RUN MODE - No changes will be made"
fi

MITAMAE_ARGS+=("$NODE_FILE")

"$MITAMAE_BIN" "${MITAMAE_ARGS[@]}"

log "Done!"