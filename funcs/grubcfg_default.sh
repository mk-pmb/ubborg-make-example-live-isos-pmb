#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-

function grubcfg_default () {
  local CPRT='cp --recursive --target-directory='

  local SGD='tmp.supergrub.repo/menus/sgd'
  [ ! -d "$SGD" ] || $CPRT"$GRUB_DIR" -- "$SGD" || return $?

  local CASPER_MENT='
      set kopt="boot=casper"
      set kopt="$kopt file=/cdrom/preseed/ubuntu.seed"
      set kopt="$kopt console-setup/layoutcode=de"
      set kopt="$kopt locale=en_US"
      set kopt="$kopt persistent"
      # set kopt="$kopt quiet splash"
      set kopt="$kopt --"
      linux   /casper/vmlinuz $kopt
      initrd  /casper/initrd.img
      boot
      '

  SGD='"$config_directory"/sgd/main.cfg'
  >"$GRUB_DIR"/grub.cfg unindent "
    loadfont unicode.pf2
    menuentry 'Ubuntu Live Session [built $(
      date --utc +'%F %H:%M UTC')]' {$CASPER_MENT}

    if [ -f $SGD ]; then
      menuentry '' { return 0; }
      set sgdsearch=on
      source $SGD
    fi

    set default=0
    set timeout=10
    " || return $?
}








return 0
