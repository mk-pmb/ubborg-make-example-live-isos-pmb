#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-

function cloud_image_tarball () {
  local DL_URL="$(resolve_cfg_path_vars '<cloud_image_url>')"
  DL_URL="${DL_URL%%'#'*}"
  local SAVE_AS="$(resolve_cfg_path_vars '<cloud_image_tarball>')"
  local DL_BFN="$DL_URL"
  DL_BFN="${DL_BFN%%'?'*}"
  DL_BFN="${DL_BFN##*/}"
  [ -n "$DL_BFN" ] || return 4$(echo E: $FUNCNAME: >&2 \
    "Cannot determine file basename from URL '$DL_URL'!")
  case "$SAVE_AS" in
    */ ) SAVE_AS+="$DL_BFN";;
  esac

  mkdir --parents -- "$(dirname -- "$SAVE_AS")"
  local OPT='--continue --progress=dot:mega'
  # OPT+=' --no-verbose --show-progress'
  log_rtc_stopwatch 0 ': download/verify:'
  local START=$SECONDS
  wget $OPT --output-document="$SAVE_AS" -- "$DL_URL" || return $?$(
    echo E: $FUNCNAME: "Failed to download '$SAVE_AS' <- '$DL_URL'!" >&2)
  log_rtc_stopwatch $SECONDS+1-$START ': done. took ≤ ¤ sec.'

  case "$1" in
    download | ensure ) return 0;;
    unpack ) ;;
  esac

  echo
  local TGT_ROOT="${CFG[bread_chroot_path]:-/proc/ERROR/TGT_ROOT}"
  mkdir --parents -- "$TGT_ROOT/etc" || return $?
  vdo sudo find "$TGT_ROOT"/etc/ -type f -name '*.dpkg-orig' \
    -delete || return $?

  log_rtc_stopwatch 0 ': unpack:'
  START=$SECONDS
  local UNP=(
    sudo
    tar
    --directory "$TGT_ROOT"
    --extract
    --file "$SAVE_AS"
    ${CFG[cloud_image_tar_opt]}
    )
  "${UNP[@]}" || return $?
  log_rtc_stopwatch $SECONDS+1-$START ': done. took ≤ ¤ sec.'
}








