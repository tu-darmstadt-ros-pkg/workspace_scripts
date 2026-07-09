#!/usr/bin/env bash
# ------------------------------------------------------------------
# ccache <sub‑command>
# ------------------------------------------------------------------

source "$ROSWSS_BASE_SCRIPTS/helper/helper.sh"

: "${CCACHE_DIR:=$ROSWSS_ROOT/.cache/ccache}"

CCACHE_ENV_FILE="$CCACHE_DIR/env"
SRC_DIR=/tmp/ccache-src # shared build tree

_usage() {
  cat <<EOT
$ROSWSS_PREFIX ccache <command>

install [VER|--latest] [PREFIX]   build & install ccache
                                  VER defaults to 4.11.3 when omitted
uninstall                         remove ccache & workspace links
activate                          enable cache for this workspace
deactivate                        disable it
--show-stats                      ccache --show-stats
--zero-stats                      ccache --zero-stats
EOT
}

fail() {
  echo_error "$*"
  return 1
}

run_cmd() {
  echo_note "+ $*"
  "$@"
  local rc=$?
  ((rc == 0)) || fail "command failed ($rc)"
  return $rc
}

# ------------------------------------------------------------------
# build & install
# ------------------------------------------------------------------
install_ccache() {
  local VERSION="${1:-4.11.3}"
  local PREFIX="${2:-/usr/local}"

  # --latest ⇒ look up newest GitHub release tag
  if [[ "$VERSION" == "--latest" ]]; then
    echo_note "Querying GitHub for latest ccache release…"
    VERSION="$(curl -s https://api.github.com/repos/ccache/ccache/releases/latest |
      grep -Po '"tag_name":\s*"\Kv[0-9.]+')"
    [[ -n $VERSION ]] || fail "Could not parse latest version tag"

    VERSION="${VERSION#v}" # drop leading v
    echo_info "Latest version is $VERSION"
  fi

  echo_info "Installing ccache $VERSION into $PREFIX …"

  if [[ -d "$SRC_DIR/.git" ]]; then
    echo_note "Updating existing clone in $SRC_DIR"
    run_cmd git -C "$SRC_DIR" fetch --all --prune
    run_cmd git -C "$SRC_DIR" checkout -f "v${VERSION}" || return 1
    run_cmd git -C "$SRC_DIR" reset --hard "v${VERSION}"
  else
    echo_note "First‑time setup – installing build deps"
    run_cmd sudo apt-get update
    run_cmd sudo apt-get install -y git cmake make \
      libzstd-dev libhiredis-dev

    echo_note "Cloning fresh copy into $SRC_DIR"
    run_cmd git clone --depth 1 --branch "v${VERSION}" \
      https://github.com/ccache/ccache.git "$SRC_DIR" || return 1
  fi

  run_cmd cmake -S "$SRC_DIR" -B "$SRC_DIR/build" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" || return 1

  run_cmd cmake --build "$SRC_DIR/build" -j"$(nproc)" || return 1
  run_cmd sudo cmake --install "$SRC_DIR/build" || return 1

  echo_info "ccache $VERSION installed."
}

# ------------------------------------------------------------------
# uninstall
# ------------------------------------------------------------------
uninstall_ccache() {
  local PREFIX="${1:-/usr/local}"
  echo_warn "Removing ccache, workspace links, and source tree ..."

  if [[ -f "$PREFIX/bin/ccache" ]]; then
    run_cmd sudo rm -f "$PREFIX/bin/ccache"
  fi
  [[ -d "$SRC_DIR" ]] && run_cmd sudo rm -rf "$SRC_DIR"
  run_cmd rm -rf "$CCACHE_DIR"
  echo_info "ccache binaries, source tree, and workspace links removed."
}

# ------------------------------------------------------------------
# dispatcher
# ------------------------------------------------------------------
case "$1" in
install)
  shift
  install_ccache "$@"
  ;;

uninstall)
  shift
  uninstall_ccache "$@"
  ;;

activate)
  # -------------------------------------------------------------
  # 1) Verify ccache exists and is at least 4.x
  # -------------------------------------------------------------
  if ! command -v ccache >/dev/null 2>&1; then
    echo_error "ccache is not installed. Run  '$ROSWSS_PREFIX ccache install'  first."
    return 1
  fi

  INSTALLED_VERSION="$(ccache --version | awk 'NR==1{print $3}')"
  MAJOR="${INSTALLED_VERSION%%.*}" # text before first dot

  if [[ ! $MAJOR =~ ^[0-9]+$ ]] || ((MAJOR < 4)); then
    echo_error "ccache $INSTALLED_VERSION detected (need 4.x). Run '$ROSWSS_PREFIX ccache install' first."
    return 1
  fi

  echo_info "Enabling ccache for this workspace (ccache $INSTALLED_VERSION)"

  # create dir & symlinks
  run_cmd mkdir -p "$CCACHE_DIR"
  run_cmd ln -sf "$(command -v ccache)" "$CCACHE_DIR/gcc"
  run_cmd ln -sf "$(command -v ccache)" "$CCACHE_DIR/g++"

  echo_note "+ create $CCACHE_ENV_FILE"
  # masquerade gcc/g++ in PATH, this way ccache gets properly set also for debian package builds:
  cat >"$CCACHE_ENV_FILE" <<EOF
# add once, not twice:
case ":\$PATH:" in
  *":$CCACHE_DIR:"*) ;;
  *) PATH="$CCACHE_DIR:\$PATH" ;;
esac
export PATH
export CC="$CCACHE_DIR/gcc"
export CXX="$CCACHE_DIR/g++"
export USE_CCACHE=1
export CCACHE_DIR=$CCACHE_DIR
EOF
  ;;

deactivate)
  echo_info "Disabling ccache."
  run_cmd rm -rf "$CCACHE_DIR/env"
  run_cmd rm -rf "$CCACHE_DIR/gcc"
  run_cmd rm -rf "$CCACHE_DIR/g++"
  ;;

--show-stats) run_cmd ccache --show-stats ;;
--zero-stats) run_cmd ccache --zero-stats ;;

"" | -h | --help | help) _usage ;;
*)
  echo_error "Unknown command '$1'"
  _usage
  return 1
  ;;
esac
