#!/bin/bash

# cdo_dup_timestamp
# created:
#        2017-01-20
#        Randy Miller
#        rsm5139@psu.edu

# last modified on 2017-02-14

source uniqList.sh

# main function
function cdo_dup_timestamp()
{
  # Initialize variables
  local ts=""
  local h_mess="$(cat <<-EOF
cdo_dup_timestamp <NetCDF file>

This functions checks for duplicate timestamps in a NetCDF file

Positional Arguments:
$1  name of a NetCDF file
Return Codes:
0   normal return: no errors
1   insufficient arguments
2   duplicate timestamps were found
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
  
  ts=$(cdo showtimestamp "$1") || {
    echo "Problem using 'cdo timestamp' on $1. Check that file exists and is a NetCDF file." >&2
    return 3
  }
  
  uniqList "$ts" " " > /dev/null
  return $?
}