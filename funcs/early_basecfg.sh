#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-

function early_basecfg () {
  local TGT_ROOT="${CFG[bread_chroot_path]}"
  [ -n "$TGT_ROOT" ] || return 4$(echo E: $FUNCNAME: 'Empty chroot path!' >&2)

  tgt_putf /etc/hostname $'\n'"${CFG[bread_hostname]}" || return $?
  early_basecfg__early_files_prefix || return $?
}


function early_basecfg__early_files_prefix () {
  local PFX="$1" KEY= VAL=
  for KEY in "${!CFG[@]}"; do
    [[ "$KEY" == early_file:"$PFX"* ]] || continue
    VAL="${CFG[$KEY]}"
    [ -z "$VAL" ] || tgt_putf "/${KEY#*:}" "$VAL" || return $?
  done
}










return 0