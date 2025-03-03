#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function milestone () { printf -- '## %(%T)T (%ss): %s\n' -1 $SECONDS "$*"; }


function prepare_inside_chroot () {
  cd / || return $?
  SECONDS=0
  mount | grep -Fe ' on /dev type ' && return 4$(
    echo E: 'Unexpected /dev mountpoint!' >&2)

  milestone 'Test network connection inside chroot:'
  wget --no-verbose --output-document=/dev/null --tries=1 --timeout=10 \
    -- http://archive.ubuntu.com/ubuntu || return $?
  milestone 'Network seems to work.'
  echo

  easy_divert '
    /etc/apt/sources.list
    /etc/casper.conf
    /etc/fstab
    ' || return $?

  sed -rf <(echo '
    s~^(LABEL=)cloudimg-rootfs(\s+/\s)~\1livecdroot\2~
    ') -- /etc/fstab.dpkg-orig >/etc/fstab || return $?

  local VAL=/sbin/initctl
  [ ! -f "$VAL" ] || return 4$(
    echo E: "$VAL exists => you may be affected by" \
      'https://bugs.launchpad.net/ubuntu/+source/upstart/+bug/430224' >&2)

  ze_apt_install || return $?

  milestone 'All done.'
}


function ze_apt_install () {
  milestone 'apt update, upgrade, install packages:'
  grep -nPe . -- /etc/apt/apt.conf.d/00proxy

  if [[ " $OVEN_FLAGS " == *' skip_inner_apt '* ]]; then
    echo D: $FUNCNAME: 'Skipping as requested via OVEN_FLAGS.'
    return 0
  fi

  local PKG=(
    apt-transport-https
    casper
    linux-image-lowlatency
    ubuntu-minimal
    ubuntu-standard
    )

  local SHUTUP='/etc/dpkg/dpkg.cfg.d/non_interactive'
  >"$SHUTUP" sed -nre 's~\s+~~;/\S/p' <<<"
    force-confnew
    # ^- Always install maintainer's version files (discard local changes)
    "

  apt-get update || return $?
  apt-get --assume-yes full-upgrade || return $?
  apt-get --assume-yes install "${PKG[@]}" || return $?
  rm -- "$SHUTUP" || return $?
  echo
}


function easy_divert () {
  set -- $*
  milestone $FUNCNAME:
  local F= O=
  for F in "$@"; do
    O="$F".dpkg-orig
    dpkg-divert --local --rename --divert "$O" --add "$F" || return $?
    [ ! -f "$F" ] || [ -f "$O" ] || continue
    echo -n 'copy: '
    cp --verbose --no-target-directory -- "$O" "$F" || return $?
  done
  milestone $FUNCNAME: done.
  echo
}







prepare_inside_chroot "$@"; exit $?
