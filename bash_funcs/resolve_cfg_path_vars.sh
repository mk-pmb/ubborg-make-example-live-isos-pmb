#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-

function resolve_cfg_path_vars () {
  local MAX_DEPTH=10
  case "$1" in
    +[0-9] | +[0-9][0-9] ) MAX_DEPTH="${1:1}"; shift;;
  esac
  local INPUT= KEY= BUF=
  local DEPTH_REMAIN= ANY_INSERTED=
  while [ "$#" -ge 1 ]; do
    BUF="$1"; shift
    DEPTH_REMAIN="$MAX_DEPTH"
    while [ "$DEPTH_REMAIN" -ge 1 ]; do
      INPUT="$BUF"
      BUF=
      (( DEPTH_REMAIN -= 1 ))
      ANY_INSERTED=
      while [ -n "$INPUT" ]; do
        case "$INPUT" in
        *'<'*'>'* )
          BUF+="${INPUT%%'<'*}"
          INPUT="${INPUT#*'<'}"
          KEY="${INPUT%%'>'*}"
          case "$KEY" in
            '' | *[^A-Za-z0-9_-]* ) BUF+="<$KEY>";;
            * ) ANY_INSERTED=+; BUF+="${CFG["$KEY"]}";;
          esac
          INPUT="${INPUT#*'>'}"
          ;;
        * ) BUF+="$INPUT"; INPUT=;;
      esac; done
      [ -n "$ANY_INSERTED" ] || break
    done # DEPTH_REMAIN
    echo "$BUF"
  done # $#
}










return 0
