#!/usr/bin/env bash
_roswss_ccache_complete() {
  local cur prev
  _get_comp_words_by_ref cur prev

  local top_cmds="install uninstall activate deactivate --show-stats --zero-stats --help"

  # ccache <command>
  if [[ $COMP_CWORD -eq 2 ]]; then
    COMPREPLY=($(compgen -W "$top_cmds" -- "$cur"))
    return
  fi

  # ccache install <version‑spec>
  if [[ $COMP_CWORD -eq 3 && $prev == install ]]; then
    # offer --latest plus the default pinned version
    COMPREPLY=($(compgen -W "4.11.3 --latest" -- "$cur"))
    return
  fi
}
complete -F _roswss_ccache_complete roswss_ccache
