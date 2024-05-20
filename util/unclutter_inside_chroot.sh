#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function unclutter_inside_chroot () {
  cd / || return $?
  mount | grep -Fe ' on /dev type ' && return 4$(
    echo E: 'Unexpected /dev mountpoint!' >&2)

  apt-get clean || return $?
  rm -- /boot/*.old 2>/dev/null || true
  chmod --recursive a+r -- /boot || return $?

  rmdir /var/log/*/ 2>/dev/null || true

  local D=( # Directories that we want to leave empty.
    /tmp
    /usr/lib/firmware/
    /usr/lib/modules
    /var/cache/apt/archives
    )

  local L=(
    /etc/apt/sources.list
    # ^-- Setting up proper apt sources will be the playbook's job,
    #     and it should use named list files in ….list.d/ instead.

    /etc/machine-id
    /var/lib/dbus/machine-id
    /var/log/alternatives.log
    /var/log/dpkg.log
    )
  local DU_OPT=(
    --no-dereference
    --summarize
    --apparent-size
    # --bytes
    # --block-size=M
    # --block-size=K
    --human-readable
    )
  local DU_LOG='/var/log/unclutter_bytes_saved.log'
  for R in "${D[@]}" "${L[@]}"; do
    [ -e "$R" -o -L "$R" ] || continue
    [ ! -d "$R" ] || umount "$R" || true
    echo -n 'unclutter [bytes]: '
    du "${DU_OPT[@]}" -- "$R" | sort -V | tee --append -- "$DU_LOG"
    rm -rf -- "$R" || return $?
  done

  # Re-create the directories that we had overkilled:
  mkdir --parents -- "${D[@]}" || return $?
}





unclutter_inside_chroot "$@"; exit $?
