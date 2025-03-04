#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-

# […]

function qemu_boot () {
  qemu_boot__ensure_kernel_modules || return $?

  local KVM_DEV='/dev/kvm'
  echo -n D: 'Checking kvm device: '
  ls -lF -- "$KVM_DEV" || return $?
  [ -w "$KVM_DEV" ] || return 4$(echo E: >&2 \
    "You don't have write permission for the KVM device '$KVM_DEV'." \
    "Your may need to add yourself to the user group that owns it.")

  local ISO_IMG="$(resolve_cfg_path_vars '<iso_output_path>')"
  local BOOT_CMD=(
    qemu-system-"$(uname -m)"
    -machine pc
    -enable-kvm
    -cpu host
    -smp 1        # number of CPUs in guest
    -m 1G         # guest RAM size
    -mem-prealloc
    -display gtk
    -bios '/usr/share/ovmf/OVMF.fd' #  apt-get install ovmf
    -drive file="$ISO_IMG",media=cdrom
    -netdev user,id=net0 -device virtio-net,netdev=net0
    )
  qemu_boot__pid_helper &
  disown "$!"
}



function qemu_boot__ensure_kernel_modules () {
  local CPU_VNDS="$(LANG=C lscpu | sed -nre 's~^Vendor ID:\s+~~p' | sort -u)"
  [ -n "$CPU_VNDS" ] || return 4$(
    echo E: $FUNCNAME: 'Unable to identify any CPU vendor!' >&2)

  local MOD_WANT=
  CPU_VNDS=" ${CPU_VNDS//$'\n'/ } "
  [[ "$CPU_VNDS" == *' GenuineIntel '* ]] && MOD_WANT+=' kvm_intel'
  [[ "$CPU_VNDS" == *' AuthenticAMD '* ]] && MOD_WANT+=' kvm_amd'
  [ -n "$MOD_WANT" ] || return 4$(echo E: $FUNCNAME: >&2 \
    "Unable to decide kvm kernel module for these CPU vendors:${CPU_VNDS% }")
  MOD_WANT+=' vhost_net'

  local MISS="$(printf -- '%s\n' $MOD_WANT | grep -vxFf <(
    lsmod | grep -oe '^\w*'))"
  if [ -z "$MISS" ]; then
    echo D: "All required kernel modules are already loaded:$MOD_WANT"
    return 0
  fi
  MISS="${MISS//$'\n'/ }"
  echo D: $FUNCNAME: "Loading missing kernel modules: $MISS"
  for MISS in $MISS ; do sudo modprobe "$MISS"; done
  echo "D: Waiting for newly loaded kernel modules to become available:"
  sleep 2s

  MISS="$(printf -- '%s\n' $MOD_WANT | grep -vxFf <(
    lsmod | grep -oe '^\w*'))"
  if [ -z "$MISS" ]; then
    echo "D: All previously missing kernel modules have are now loaded."
    return 0
  fi
  MISS="${MISS//$'\n'/ }"
  echo W: "Failed to load these kernel modules (still missing): $MISS"
  return 8
}


function qemu_boot__pid_helper () {
  local BFN="tmp.qemu.$BASHPID"
  BOOT_CMD+=( -pidfile "$BFN".pid )
  # ^-- Enable to verify that "exec" worked as expected.

  local QMP_SOCK="$BFN".qmp.sock
  BOOT_CMD+=( -qmp unix:"$QMP_SOCK",server,nowait )

  echo D: "Gonna exec: ${BOOT_CMD[*]}"
  echo D: "Your QMP socket (https://wiki.qemu.org/Documentation/QMP) will be" \
    "'$QMP_SOCK'. To connect, run:" \
    "rlwrap -C qemu-qmp socat UNIX-CONNECT:'$QMP_SOCK' stdio"
  exec "${BOOT_CMD[@]}"
}







return 0
