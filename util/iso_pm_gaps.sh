#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function pmgaps_cli_init () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  [ -f "$1" ] || return 4$(echo E: 'Expected argument: iso_file' >&2)
  exec < <(head --bytes=32K -- "$1" | hd -v)
  pmgaps_read || return $?
}


function pmgaps_read () {
  local PRINT_OFFSET=( printf -- '%08x  %s\n' )
  local LN= OFFS= HEX= PREV_HEX=
  local VERBATIM=0 REPEATED=0 PAD_START=0
  local PM_REC_CNT_TOTAL= PM_REC_CNT_SEEN=0
  while IFS= read -r LN; do
    OFFS="${LN%% *}"
    LN="${LN#* }"
    LN="${LN# }"
    [ "$LN" != "$OFFS" ] || continue
    [ "${OFFS:0:1}" == 0 ] || continue
    let OFFS="0x$OFFS"
    [ "$OFFS" -ge 1 ] || continue
    HEX="${LN%%|*}"
    LN="${LN#*|}"
    HEX="${HEX//00 /__ }"
    if [ "$PAD_START" == "$OFFS" ]; then
      LN+='  # Start of padding area'
      PREV_HEX=
    fi
    pmgaps_decide_line || return $?
    [ "$PAD_START" -ge 1 ] || continue
    if [ "$HEX" == "$PREV_HEX" ]; then
      (( REPEATED += 1 ))
    else
      REPEATED=0
      PREV_HEX="$HEX"
    fi
    case "$REPEATED" in
      0 ) "${PRINT_OFFSET[@]}" "$OFFS" "$HEX |$LN";;
      1 ) echo '*';;
    esac
    [ "$VERBATIM" != stop ] || break
  done
}


function pmgaps_decide_line () {
  if [ "$VERBATIM" -ge 1 ]; then
    (( VERBATIM -= 1 ))
    return 0
  fi
  case "$HEX" in
    '50 4d '* ) pmgaps_found_pm_line || return $?;;
    *[^_\ ]* )
      [ "$PAD_START" -ge 1 ] || return 0
      if [ "$PM_REC_CNT_SEEN" -ge "${PM_REC_CNT_TOTAL:-0}" ]; then
        VERBATIM='stop'
        LN+='  # End of apple partition map'
      else
        LN+='  # ??'
      fi
      ;;
  esac
}


function pmgaps_found_pm_line () {
  # Is it at a boundary?
  local PM_BLKSZ=$(( 2 * 1024 ))
  local VAL=
  (( VAL = OFFS % PM_BLKSZ ))
  if [ "$VAL" != 0 ]; then
    "${PRINT_OFFSET[@]}" "$OFFS" '# stray PM (not at boundary)'
    return 0
  fi

  if [ "$PAD_START" -ge 1 ]; then
    (( VAL = OFFS - PAD_START ))
    # "${PRINT_OFFSET[@]}" $(( OFFS - 1
    #   )) "# last byte of padding ($VAL bytes total)"
    echo "#= pm_${PM_REC_CNT_SEEN}_pad=$PAD_START+$VAL"
  fi

  VAL="${HEX:12:11}"
  VAL="${VAL//_/0}"
  VAL="${VAL// /}"
  let VAL="0x$VAL"
  if [ -z "$PM_REC_CNT_TOTAL" ]; then
    PM_REC_CNT_TOTAL="$VAL"
    echo "#= n_pm_recs=$VAL"
  elif [ "$VAL" == "$PM_REC_CNT_TOTAL" ]; then
    true
  else
    echo W: "Invalid PM record: Total number of PM records is given as" \
      "$VAL but the first PM record declared $PM_REC_CNT_TOTAL." >&2
  fi
  (( PM_REC_CNT_SEEN += 1 ))

  # "${PRINT_OFFSET[@]}" "$OFFS" '# Next: PM record'
  LN+="  # Start of PM record $PM_REC_CNT_SEEN of $PM_REC_CNT_TOTAL"
  # The PM record is 512 bytes and they are protected by a checksum.

  (( PAD_START = OFFS + 512 ))
  VERBATIM=31
  # The padding is arbitrary data (zeroed-out by default) that we can
  # fill with anything we want.

  echo "#= pm_${PM_REC_CNT_SEEN}_rec=$OFFS"
}










pmgaps_cli_init "$@"; exit $?
