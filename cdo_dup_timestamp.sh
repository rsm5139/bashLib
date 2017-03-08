#!/bin/bash

# cdo_dup_timestamp
# created:
#        2017-01-20
#        Randy Miller
#        rsm5139@psu.edu

# last modified on 2017-02-20

# This checks for duplicate timestamps in a NetCDF file. The cdo library is required to use this. 
# The process is to print out all of the timestamps, then test the length of the list before and after duplicates are removed. Another function called 'uniqList' is required.

source uniqList.sh

# main function
function cdo_dup_timestamp()
{
  # Initialize variables
  local ts=""
  local h_mess="
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
"

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
  
  # Get the timestamp list using 'cdo showtimestamp'
  ts=$(cdo showtimestamp "$1" 2>/dev/null) || {
    echo "Problem using 'cdo timestamp' on $1. Check that file exists and is a NetCDF file." >&2
    return 3
  }
  
  # Use uniqList command. The commard returns 2 if there are duplicates. The return code is then passed of as the retrun code of this function.
  uniqList "$ts" " " > /dev/null
  return $?
}