#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-

function unpack_cloud_image_tarball () {
  local TGT_ROOT="${CFG[bread_chroot_path]:-/proc/ERROR/TGT_ROOT}"
  mkdir --parents -- "$TGT_ROOT" || return $?
  log_rtc_stopwatch 0 ': unpack:'
  local START=$SECONDS
  local UNP=(
    sudo
    tar
    --directory "$TGT_ROOT"
    --extract
    --file "${CFG[cloud_image_tarball]}"
    ${CFG[cloud_image_tar_opt]}
    )
  "${UNP[@]}" || return $?
  log_rtc_stopwatch $SECONDS+1-$START ': done. took ≤ ¤ sec.'
}










return 0
