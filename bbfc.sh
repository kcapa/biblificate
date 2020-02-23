#!/bin/bash

unset cache
declare -A cache

declare -a s m l
# "small" type
s=(
  [0]=⁰
  [1]=¹
  [2]=²
  [3]=³
  [4]=⁴
  [5]=⁵
  [6]=⁶
  [7]=⁷
  [8]=⁸
  [9]=⁹
)
# "medium" type
m=(
  [0]=₀
  [1]=₁
  [2]=₂
  [3]=₃
  [4]=₄
  [5]=₅
  [6]=₆
  [7]=₇
  [8]=₈
  [9]=₉
)
# "large" type
l=(
  [0]=0
  [1]=1
  [2]=2
  [3]=3
  [4]=4
  [5]=5
  [6]=6
  [7]=7
  [8]=8
  [9]=9
)

while IFS=$'\n' read TEXT ;do 
  case $TEXT in
    ' '* )  data=0 ;;
    '' )    data=0 ;;
    * )
        # filter out problem characters
        TEXT="${TEXT//[$'\t'|$'\0']}"
        # filter out problem lines
        case $TEXT in
          [\[*]  )   data=0 ;;
        esac

        # if line seen previously then drop it
        if [ "${cache["$TEXT"]}" = "1" ]; then
          data=0
        else
          data=1
        fi
    ;;
  esac

  # new paragraph detection - if previous accept not seen then this is a new paragraph
  #   * always needs to be a newline separating fields
  if [ "${old_data:=0}" -ne "$data" ]; then 
    if [ "${old_data}" -ne 1 ]; then
      newpara=1
      inpara=1
    fi
  fi

  if [ "$data" -eq 1 ]; then 
    # record everything seen so far so it can be de-duplicated (e.g. chorus/hook)
    cache["$TEXT"]=1
    if [ "$inpara" = 1 ]; then
      # increment verse number
      (( v++ ))

      unset n
      while read -n 1 d;do
        # number each line
        [[ ! "$d" =~ $^ ]] || continue
        if [ "$newpara" = 1 ]; then
          # the first verse number in every paragraph gets medium-sized font
          n+="${m[$d]}"
        else
          # regular verses get small-sized font
          n+="${s[$d]}"
        fi
      done <<< $v

      case $v in
        # the first verse of each chapter gets large font
        1 )     n=${l[$v]} ;;
      esac

      if [ "$newpara" = 1 ]; then
        # separate new paragraphs by two newlines
        echo
        echo
      fi

      # apply punctuation by default on every verse
      case ${TEXT:${#TEXT}-1:${#TEXT}-1} in
        "!"|"?"|"." ) : ;;
        # default punctuation .
        * )   TEXT+=.
      esac

      echo -n ${n} $TEXT" "

      newpara=0
    fi
  else
    inpara=0
    newpara=0
    savepara=0
  fi

  old_data=$data
done <<< "$(
# v input
  xmllint --html --xpath 'string(//body//div[@class="lyrics"])' /dev/stdin 2>/dev/null
)" | fold -w 50 -s | pr -2 -T -w 110 -s'          '
#  ^ output
