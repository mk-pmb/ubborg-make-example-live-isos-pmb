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
    ${CFG[ansible_proxy]}
    "
}


function apply_playbook_to_chroot () {
  generate_ansible_project_config >ansible.cfg || return $?
  sudo -E ansible-playbook --inventory="${CFG[bread_chroot_path]}," \
    -- "${CFG[playbook]}" || return $?
}










return 0
