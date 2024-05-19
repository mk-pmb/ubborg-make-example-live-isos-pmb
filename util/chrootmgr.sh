#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function chrootmgr_cli_main () {
  local TGT_ROOT="$1"; shift
  [ -n "$TGT_ROOT" ] || return 4$(echo E: $FUNCNAME: 'Empty chroot path!' >&2)
  [ "$TGT_ROOT" -ef / ] && return 4$(
    echo E: $FUNCNAME: 'The chroot path must not point to /!' >&2)
  [ "$TGT_ROOT" != / ] || return 4$( # how did that even pass the -ef check?
    echo E: $FUNCNAME: 'Cannot use / as chroot path!' >&2)
  TGT_ROOT="${TGT_ROOT%/}"
  [ -n "$1" ] || return 4$(echo E: $FUNCNAME: 'No task given!' >&2)

  mkdir --parents -- "$TGT_ROOT"
  # ^-- If it wouldn't have existed prior, our upcoming attempt
  #     to resolve it would fail.

  local ROOT_ABS="$(readlink -m -- "$TGT_ROOT")"
  [ "$ROOT_ABS" -ef "$TGT_ROOT" ] || return 4$(
    echo E: $FUNCNAME: 'Failed to resolve the chroot path!' >&2)

  chrootmgr_"$@" || return $?
}


function chrootmgr_remount () {
  chrootmgr_close || return $?
  chrootmgr_mount "$@" || return $?
}


function chrootmgr_list () {
  mount | sed -nre 's~^\S+ on (\S+) type .*$~#\t\1/~p' \
    | grep -Fe $'#\t'"$ROOT_ABS/" | sed -re 's~^#\t~~;s~/$~~'
}


function chrootmgr_close () {
  local MOUNTS=()
  readarray -t MOUNTS < <(chrootmgr_list | tac)
  local CNT="${#MOUNTS[@]}" ITEM=
  for ITEM in "${MOUNTS[@]}"; do
    echo D: $FUNCNAME: "umount ${ITEM/#"$ROOT_ABS/"/"$TGT_ROOT/"}"
    sudo umount "$ITEM" || return $?
  done
  echo D: $FUNCNAME: "done: umounted $CNT inner mountpoint(s)."
}


function chrootmgr_mount () {
  local ARG= HOW= DEV= MPT=
  [ "$#" -ge 1 ] || set -- T:
  while [ "$#" -ge 1 ]; do
    ARG="$1"; shift
    MPT="${ARG#*:}"
    case "$ARG" in
      '#'* ) continue;;
      B: ) set -- B:dev B:run "$@"; continue;;
      B:[a-z]*:* ) # B:inside-mountpoint:host-directory
        HOW='--bind'; DEV="${MPT#*:}"; MPT="${MPT%%:*}";;
      B:[a-z]* ) HOW='--bind'; DEV="/$MPT";;
      T: ) set -- T:dev/pts T:proc T:{sys,tmp}+fs "$@"; continue;;
      T:[a-z]* ) HOW="-t ${MPT//[\/\+]/}"; MPT="${MPT%+*}"; DEV=none;;
      * ) echo E: $FUNCNAME: "Unsupported argument: '$ARG'" >&2; return 4;;
    esac
    printf -- 'D: %s: %- 10s %- 5s %s\n' \
      $FUNCNAME "$HOW" "$DEV" "$TGT_ROOT/$MPT"
    if chrootmgr_list | grep -qxFe "$ROOT_ABS/$MPT"; then
      echo E: $FUNCNAME: "mountpoint is already in use: $TGT_ROOT/$MPT" >&2
      return 8
    fi
    sudo mkdir --parents -- "$ROOT_ABS/$MPT" || return $?
    sudo mount $HOW "$DEV" "$ROOT_ABS/$MPT" || return $?
  done
  echo D: $FUNCNAME: 'done.'
}


function chrootmgr_discard () {
  chrootmgr_close || return $?
  echo D: 'removing files…'
  sudo rm --preserve-root=all --one-file-system --recursive \
    -- "${TGT_ROOT:-/proc/ERROR/EMPTY_TGT_ROOT}" || return $?
  echo D: 'done.'
}











chrootmgr_cli_main "$@"; exit $?
