#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-

function generate_playbook () {
  local PLAN="${CFG[ubborg_plan]}"
  [ -n "$PLAN" ] || return 4$(echo E: $FUNCNAME: 'Empty ubborg_plan.' >&2)
  local PBK="${CFG[playbook]}"
  local FTJ="${PBK%.yaml}.flatTodo.json"
  UBBORG_TGT_HOST="${CFG[bread_hostname]}" ubborg-planner-pmb depsTree \
    --format=flatTodoJson "$PLAN" >"$FTJ" || return $?
  ubborg-playbookie-pmb --yaml-header --pbk-conn=chroot \
    "$FTJ" >"$PBK" || return $?
}


function ansible_guess_proxy () {
  env | sed -nre 's!([a-z]+_proxy)=!\L\1\E = !ip'
}


function generate_ansible_project_config () {
  sed -re 's!^\s+!!' <<<"[defaults]
    callback_whitelist = profile_tasks
    ${CFG[ansible_proxy]}
    "
}


function apply_playbook_to_chroot () {
  generate_ansible_project_config >ansible.cfg || return $?
  local LOG_TPL='tmp.debug.ansible.%.txt'
  local LOG_ALL="${LOG_TPL//%/all}"
  ( echo LOG_CANARY arrives
    sudo -E ansible-playbook --inventory="${CFG[bread_chroot_path]}," \
      -- "${CFG[playbook]}"
    echo LOG_CANARY survived
  ) |& ./util/ansible_unclutter_timings.sed | tee -- "$LOG_ALL"
  local RVS="${PIPESTATUS[*]}"
  [ "$RVS" == '0 0 0' ] || return 4$(
    echo E: $FUNCNAME: "Main pipe failed: rv=[$RVS]" >&2)
  local LOG_WARN="${LOG_TPL//%/warn}"
  grep -C 3 -vPe '^TASK |^ |^\}$|^$' -- "$LOG_ALL" >"$LOG_WARN"

  local CANARY="$(grep -nPe '^' -m 5 -- "$LOG_WARN")"
  case "$CANARY" in
    $'1:LOG_CANARY arrives\n2:LOG_CANARY survived' )
      rm -- "$LOG_WARN"
      return 0;;
    $'1:LOG_CANARY arrives\n2:'* )
      echo W: $FUNCNAME: 'Found warnings in logfile.'
      wc --lines -- "$LOG_ALL" "$LOG_WARN"
      ;;
    * )
      sed -re 's~^~| ~' <<<"$CANARY"
      echo E: $FUNCNAME: 'Canary malfunction.' >&2
      return 8;;
  esac
}










return 0
