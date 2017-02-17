#!/bin/bash

# cdo_mis_timestamp
# created:
#        2017-01-20
#        Randy Miller
#        rsm5139@psu.edu

# last modified on 2017-02-14

source uniqList.sh

# main function
function cdo_mis_timestamp()
{
  # Initialize variables
  local ts=""
  local new=0
  local old=0
  local time_step=0
  local flex_u=0 && flex_l=0
  local h_mess="$(cat <<-EOF
cdo_mis_timestamp <NetCDF file>

This functions checks for missing timestamps in a NetCDF file

Positional Arguments:
$1  name of a NetCDF file
Return Codes:
0   normal return: no errors
1   insufficient arguments
2   missing timestamps were found
3   file error
127 missing cdo library
EOF
  )"

  # Check for 1 argument
  [ "$#" -lt 1 ] && {
    echo "Too few arguments" >&2
    echo "" >&2
    echo "$h_mess" >&2
    return 1
  }
  
  # Check for CDO command
  cdo --version > /dev/null 2>&1 || {
    echo "Missing CDO library" >&2
    return 127
  }
  
  ts=$(cdo showtimestamp "$1" 2>/dev/null) || {
    echo "Problem using 'cdo timestamp' on $1. Check that file exists and is a NetCDF file." >&2
    return 3
  }
  ts=$(uniqList "$ts" " ")
  [ $? -eq 2 ] && { echo "Warning: duplicates found"; }
  for i in ${ts[@]}; do
    new=$(date -d"$i" '+%s')
    [ $old -eq 0 ] && { old=$new; continue; }
    [ $time_step -eq 0 ] && { 
      time_step=$(( new - old ))
      flex_u=$(( time_step + time_step / 5 ))
      flex_l=$(( time_step - time_step / 5 ))
      old=$new
      continue
    }
    diff=$(( new - old ))
    old=$new
    [ $diff -lt $flex_u ] && [ $diff -gt $flex_l ] && continue
    # This may just be a missing leap day. Check and pass it true.
    [[ "$i" =~ [0-9]{4}-03-01.* ]] && {
      diff=$(( diff - 86400 ))
      [ $diff -lt $flex_u ] && [ $diff -gt $flex_l ] && continue
    }
    echo "Error at $i"
    return 2
  done
  
  return 0
}