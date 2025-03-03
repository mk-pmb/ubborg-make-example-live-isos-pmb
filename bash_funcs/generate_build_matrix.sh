#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-

function generate_build_matrix () {
  local APOS="'" QUOT='"'
  local UBU_VERSIONS=(
    20.04=focal
    )
  local RECIPES=(
    'rescuedisk-pmb:
        test/example_plans/justPrimaryUser
        '
    )

  # local RLS_TAG="rolling/${GITHUB_REF#*-}"
  local RLS_TAG="rolling/auto-ci-release"
  local REPO_URL="https://github.com/$GITHUB_REPOSITORY"
  local RLS_SUBURL="/releases/tag/$RLS_TAG"

  local ESTIMATED_MAX_BUILD_TIME_SECONDS_OVERHEAD=$(( 1 * 60 ))
  local ESTIMATED_MAX_BUILD_TIME_SECONDS_PER_RECIPE=$(( 5 * 60 ))
  local DURA=$(( ESTIMATED_MAX_BUILD_TIME_SECONDS_OVERHEAD ))

  local TASKS= N_TASKS=0 VER= UC= REC=
  for VER in "${UBU_VERSIONS[@]}"; do
    for REC in "${RECIPES[@]}"; do
      UC="${REC%%:*}"
      REC="${REC#*:}"
      for REC in $REC; do
        TASKS+="{
          'ubuntu_version': ${VER%%.*}, 'ubuntu_release': '${VER##*=}',
          'ubborg_usecase': '$UC', 'ubborg_recipe': '$REC'
        }"$',\n'
        (( N_TASKS += 1 ))
        (( DURA += ESTIMATED_MAX_BUILD_TIME_SECONDS_PER_RECIPE ))
      done
    done
  done

  TASKS="[${TASKS%$',\n'}]"
  TASKS="${TASKS//$APOS/$QUOT}"
  <<<"$TASKS" FMT=json fmt_markdown_textblock stepsumm details 'Matrix tasks'
  format_json_for_shell_env --ghout mxtasks=TASKS || return $?

  local ETA_UTS=$(( EPOCHSECONDS + DURA ))
  local ETA_HR='%T UTC, %F'
  # !!          ^-- without seconds, we'd have to round up to not overpromise!
  ETA_HR="$(date --utc --date="@${ETA_UTS:-0}" +"$ETA_HR")"

  ( echo "Building $N_TASKS variation(s)." \
      "This will probably finish before $ETA_HR."
    echo "The release page will be [\`…$RLS_SUBURL\`]($REPO_URL$RLS_SUBURL)."
    echo
  ) >>"$GITHUB_STEP_SUMMARY"
  ghciu_ensure_stepsumm_size_limit || return $?
}


return 0
