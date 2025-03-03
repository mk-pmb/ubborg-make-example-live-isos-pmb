#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-

function bake_bread () {
  exec </dev/null
  export DEBIAN_FRONTEND=noninteractive
  local TGT_ROOT="${CFG[bread_chroot_path]}"
  local ISO_ROOT='tmp.isofiles'
  [ "$#" -ge 1 ] || set -- full
  set -- "$@" ,
  local STEP=()
  while [ "$#" -ge 1 ]; do case "$1" in
    , )
      [ -z "${STEP[*]}" ] || "$FUNCNAME"__"${STEP[@]}" || return $?
      STEP=()
      shift;;
    * ) STEP+=( "$1" ); shift;;
  esac; done
}


function bake_bread__purge () {
  ./util/chrootmgr.sh "$TGT_ROOT" close || return $?
  local R="safer_sudo_rm_rf --stopwatch 'Discard old %:' --skip-missing"
  eval "${R//%/bread crumbs}" "$TGT_ROOT" || return $?
  eval "${R//%/ISO files}"    "$ISO_ROOT" || return $?

  local L=(
    "${CFG[playbook]}"
    "${CFG[playbook]%.yaml}.flatTodo.json"
    )
  for R in "$L"; do
    [ -f "$R" ] || [ -L "$R" ] || continue
    rm -- "$R" || return $?
  done
  ./util/chrootmgr.sh "$TGT_ROOT" close || return $?
}


function bake_bread__full () {
  [ -f "${CFG[playbook]}" ] || vdo generate_playbook || return $?

  local APT_CACHE="tmp.cache/${CFG[bread_release_codename]}/apt"
  mkdir --parents -- "$APT_CACHE" || return $?
  APT_CACHE="B:var/cache/apt/archives:$APT_CACHE"
  vdo ./util/chrootmgr.sh "$TGT_ROOT" remount T: "$APT_CACHE" || return $?

  vdo cloud_image_tarball unpack || return $?
  vdo early_basecfg || return $?
  bake_bread__prepare_inside || return $?
  vdo ./util/chrootmgr.sh "$TGT_ROOT" close || return $?
  bake_bread__isoprep || return $?
  bake_bread__isoify || return $?
}


function bake_bread__inside_script () {
  local B="$1"_inside_chroot.sh
  local I="/usr/local/bin/$B"
  tgt_putf +chmod 0700 "$I" "util/$B" || return $?
  vdo in_bread "$I" || return $?
  sudo rm -- "$TGT_ROOT$I" || return $?
}


function bake_bread__prepare_inside () {
  bake_bread__inside_script prepare || return $?
  if [[ " $OVEN_FLAGS " == *' skip_inner_apt '* ]]; then
    echo D: $FUNCNAME: 'inner apt was skipped => not sanity-checking.'
  else
    ./util/sanity_check_file_types.sh "$TGT_ROOT/boot/" \
      {vmlinuz,initrd.img}:{L,f} || return $?
  fi

  vdo apply_playbook_to_chroot || return $?

  bake_bread__inside_script unclutter || return $?
}


function bake_bread__isoprep () {
  vdo ./util/chrootmgr.sh "$TGT_ROOT" close || return $?
  [ -n "$ISO_ROOT" ] || return 4$(echo E: 'Empty bread_isotmp_path!' >&2)

  if [[ " $OVEN_FLAGS " == *' skip_isoprep '* ]]; then
    echo D: $FUNCNAME: 'Skipping as requested via OVEN_FLAGS.'
    return 0
  fi

  mkdir --parents -- "$ISO_ROOT"/casper || return $?
  cp --recursive --target-directory="$ISO_ROOT"/casper \
    "$TGT_ROOT"/boot/{initrd,vmlinuz}* || return $?
  vdo bake_bread__usbcreator_compat || return $?

  # We do not have choice any about the initial GRUB config path,
  # because it is hard-coded into the GRUB image.
  local GRUB_DIR="$ISO_ROOT"/boot/grub # Ubuntu
  # local GRUB_DIR="$ISO_ROOT"/EFI/debian" # Debian signed EFI GRUB

  mkdir --parents -- "$GRUB_DIR" || return $?
  GRUB_DIR="$GRUB_DIR" vdo ${CFG[hook_isoprep_grubcfg]} || return $?

  vdo ${CFG[hook_isoprep_done]} || return $?
}


function bake_bread__isoify () {
  if [[ " $OVEN_FLAGS " == *' skip_isoify '* ]]; then
    echo D: $FUNCNAME: 'Skipping as requested via OVEN_FLAGS.'
    return 0
  fi

  vdo bake_bread__pack_squashfs || return $?
  vdo ${CFG[hook_isoify_squashed]} || return $?
  local ISO_IMG="$(resolve_cfg_path_vars '<iso_output_path>')"

  mkdir --parents -- "$(dirname -- "$ISO_IMG")"
  [ ! -f "$ISO_IMG" ] || rm -- "$ISO_IMG" || return $?

  # NB: No '--' before $ISO_ROOT in next command!
  vdo grub-mkrescue --output="$ISO_IMG" "$ISO_ROOT" || return $?

  vdo ${CFG[hook_isoify_done]} || return $?
  bake_bread__present_result_files "$ISO_IMG" || return $?
}


function bake_bread__usbcreator_compat () {
  local REQ="# This file is required for Ubuntu's USB Creator."
  echo "$REQ" >"$ISO_ROOT"/ubuntu || return $?

  local D="$ISO_ROOT"/.disk V=
  mkdir --parents -- "$D"
  local H=(
    base_installable="$REQ"
    cd_type='full_cd/single'
    info='Ubborg Live ISO'
    release_notes_url=''
    )
  for V in "${H[@]}"; do
    echo "${V#*=}" >"$ISO_ROOT/.disk/${V%%=*}" || return $?
  done
}


function bake_bread__pack_squashfs () {
  echo -n 'Weighing the bread: '
  sudo du --human-readable --summarize -- "$TGT_ROOT" || return $?
  local SQ="$ISO_ROOT"/casper/filesystem.squashfs
  local START=$SECONDS
  if [ -f "$SQ" ]; then
    echo D: $FUNCNAME: "file already exists: $SQ"
  else
    log_rtc_stopwatch 0 ': start.'
    sudo mksquashfs "$TGT_ROOT" "$SQ" || return $?
    log_rtc_stopwatch $SECONDS+1-$START ': done. took ≤ ¤ sec.'
  fi
  bake_bread__present_result_files "$SQ" || return $?
}


function bake_bread__present_result_files () {
  echo D: "These are your freshly baked ISO files:"
  sudo chown --reference . -- "$@" || return $?
  du --human-readable -- "$@" || return $?
}















return 0
