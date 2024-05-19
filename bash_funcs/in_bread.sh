#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-

function in_bread () {
  [ -n "$TGT_ROOT" ] || local TGT_ROOT="${CFG[bread_chroot_path]}"
  in_bread__sanity_checks || return $?
  local RESET_LC_VARS="$( env | grep -oPe '^LC_\w+=' )"
  RESET_LC_VARS="${RESET_LC_VARS//$'\n'/ }"
  sudo -E $RESET_LC_VARS chroot "$TGT_ROOT" "$@" || return $?
}


function in_bread__sanity_checks () {
  [ -n "$TGT_ROOT" ] || return 4$(echo E: $FUNCNAME: 'Empty chroot path!' >&2)
  ./util/sanity_check_file_types.sh "$TGT_ROOT/" '
    dev/fd/0:L
    dev/pts/ptmx:c
    proc/self:L
    proc/sys/vm/swappiness:f
    sys/kernel/vmcoreinfo:f
    ' || return $?
}








return 0
