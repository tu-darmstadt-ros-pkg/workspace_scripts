#!/bin/bash

function _analyze_complete() {
  which register-python-argcomplete 2>&1 > /dev/null
  if [ $? -eq 0 ]; then
    for dir in ${ROSWSS_SCRIPTS//:/ }; do
      if [ -x "$dir/analyze.py" ]; then
        local IFS=$'\013'
        local SUPPRESS_SPACE=0
        if compopt +o nospace 2> /dev/null; then
          SUPPRESS_SPACE=1
        fi
        COMPREPLY=( $(IFS="$IFS" \
                      COMP_LINE="$COMP_LINE" \
                      COMP_POINT="$COMP_POINT" \
                      COMP_TYPE="$COMP_TYPE" \
                      _ARGCOMPLETE_COMP_WORDBREAKS="$COMP_WORDBREAKS" \
                      _ARGCOMPLETE=1 \
                      _ARGCOMPLETE_SUPPRESS_SPACE=$SUPPRESS_SPACE \
                      $dir/analyze.py 8>&1 9>&2 > /dev/null 2>&1) )
        if [[ $? != 0 ]]; then
          unset COMPREPLY
        elif [[ $SUPPRESS_SPACE == 1 ]] && [[ "$COMPREPLY" =~ [=/:]$ ]]; then
          compopt -o nospace
        fi
        return
      fi
    done
  else
    echo ""
    echo_note "For autocompletion please install argcomplete using 'pip install --user argcomplete'"
  fi
}

add_completion "analyze" "_analyze_complete"
