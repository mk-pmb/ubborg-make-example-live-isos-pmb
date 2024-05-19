#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-

function sanity_check_file_types () {
  local PREFIX="$1"; shift
  local ITEM= CRIT=
  for ITEM in $*; do
    CRIT="${ITEM##*:}"
    ITEM="$PREFIX${ITEM%:*}"
    test -"$CRIT" "$ITEM" || return 4$(
      echo E: $FUNCNAME: "failed -$CRIT: $ITEM" >&2)
  done
  [ -n "$CRIT" ] || return 4$(
      echo E: $FUNCNAME: 'no filenames given!' >&2)
}

[ "$1" == --lib ] && return 0; sanity_check_file_types "$@"; exit $?
