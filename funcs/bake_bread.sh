#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-

function bake_bread () {
  exec </dev/null
  [ -f "${CFG[playbook]}" ] || vdo generate_playbook || return $?
  local TGT_ROOT="${CFG[bread_chroot_path]}"
  local STAGE="${1:-fresh_loaf}"; shift
  "$FUNCNAME"__"$STAGE" "$@" || return $?
}


function bake_bread__fresh_loaf () {
  vdo ./util/chrootmgr.sh "$TGT_ROOT" mount || return $?
  vdo unpack_cloud_image_tarball || return $?
  vdo early_basecfg || return $?
  bake_bread__initramfs || return $?
  vdo ./util/chrootmgr.sh "$TGT_ROOT" close || return $?
}


function bake_bread__initramfs () {
  vdo in_bread apt-get update || return $?
  local PKG='
    linux-image-lowlatency
    '
  vdo in_bread apt-get --assume-yes install $PKG || return $?
  ./util/sanity_check_file_types.sh "$TGT_ROOT/boot/" \
    {vmlinuz,initrd.img}:{L,f} || return $?
}












return 0
