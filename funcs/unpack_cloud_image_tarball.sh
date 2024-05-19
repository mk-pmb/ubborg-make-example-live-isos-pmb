#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-

function unpack_cloud_image_tarball () {
  local TGT_ROOT="${CFG[bread_chroot_path]:-/proc/ERROR/TGT_ROOT}"
  mkdir --parents -- "$TGT_ROOT"
  log_rtc_stopwatch 0 ': start.'
  SECONDS=0
  local UNP=(
    sudo
    tar
    --directory "$TGT_ROOT"
    --extract
    --file "${CFG[cloud_image_tarball]}"
    ${CFG[cloud_image_tar_opt]}
    )
  "${UNP[@]}" || return $?
  log_rtc_stopwatch $SECONDS+1 ': done. took ≤ ¤ sec.'
}










return 0
