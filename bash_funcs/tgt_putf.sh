#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-

function tgt_putf () {
  [ -n "$TGT_ROOT" ] || return 4$(echo E: $FUNCNAME: 'Empty chroot path!' >&2)
  local CHMOD=
  if [ "$1" == +chmod ]; then shift; CHMOD="$1"; shift; fi
  local DEST="${1#/}"; shift
  local SRC="$1"; shift
  case "$DEST" in
    */ ) DEST+="$(basename -- "$SRC")";;
  esac

  case "$SRC" in
    = ) exec <"/$DEST" || return $?; SRC=-;;
  esac

  DEST="$TGT_ROOT/$DEST"
  sudo mkdir --parents -- "$(dirname -- "$DEST")"
  sudo rm -- "$DEST" &>/dev/null # Avoid symlinks etc.
  echo -n "Writing $DEST: "
  case "$SRC" in
    $'\n'* )
      exec < <(unindent "$SRC")
      shift;;
    - ) ;;
    * ) exec <"$SRC" || return $?;;
  esac
  sudo tee -- "$DEST" >/dev/null || return $?
  sudo stat -c %s -- "$DEST" || return $?
  if [ "$DBGLV" -ge 4 ]; then
    sudo nl -ba -- "$DEST" || return $?
    echo
  fi
  sudo grep -HnPe '\a' -- "$DEST" >&2 || true

  # Do chmod last because we might give up or own read access:
  [ -z "$CHMOD" ] || sudo chmod --verbose "$CHMOD" -- "$DEST" || return $?
}


return 0
