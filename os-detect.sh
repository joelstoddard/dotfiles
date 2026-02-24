#!/usr/bin/env bash

set -euo pipefail

OS=""
DISTRO=""
PKG_MANAGER=""
HAS_GUI="unknown"

# --- OS detection ---
case "$(uname -s)" in
  Darwin)
    OS="macos"
    PKG_MANAGER="brew"
    HAS_GUI="yes"
    ;;

  Linux)
    OS="linux"

    # Detect distro via /etc/os-release (standard)
    if [[ -f /etc/os-release ]]; then
      . /etc/os-release

      case "$ID" in
        debian|ubuntu|linuxmint|pop)
          DISTRO="debian"
          PKG_MANAGER="apt"
          HAS_GUI="no"   # assume server unless proven otherwise
          ;;
        arch)
          DISTRO="arch"
          PKG_MANAGER="pacman"
          HAS_GUI="yes"
          ;;
        *)
          DISTRO="$ID"
          PKG_MANAGER="unknown"
          ;;
      esac
    fi
    ;;

  MINGW*|MSYS*|CYGWIN*)
    OS="windows"
    PKG_MANAGER="winget"  # or choco/scoop if you prefer
    HAS_GUI="yes"
    ;;
esac

# --- Optional: detect GUI presence on Linux ---
if [[ "$OS" == "linux" ]]; then
  if [[ -n "${DISPLAY-}" || -n "${WAYLAND_DISPLAY-}" ]]; then
    HAS_GUI="yes"
  fi
fi

# --- Output / exports ---
export OS DISTRO PKG_MANAGER HAS_GUI

echo "Detected OS:       $OS"
echo "Detected distro:   ${DISTRO:-n/a}"
echo "Package manager:   ${PKG_MANAGER:-n/a}"
echo "GUI available:     $HAS_GUI"
