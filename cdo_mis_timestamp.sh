#!/bin/bash

# cdo_mis_timestamp
# created:
#        2017-01-20
#        Randy Miller
#        rsm5139@psu.edu

# last modified on 2017-02-16

# This checks for missing timestamps in a NetCDF file. The cdo library is required to use this. Leaps days are ignored by defualt due to some model output skipping leap days. If timestamps are irregular, some other validation method is recomended.
# Note: due to differences in the way Macs use the 'date' command, this will give errors on a Mac. 

source uniqList.sh

# main function
function cdo_mis_timestamp()
{
  # Initialize variables
  local                ts="" # Array for 'cdo showtimestamp' output
  local       new_str_date=0 # Datestring
  local       old_str_date=0 # Datestring
  local                new=0 # Date in seconds
  local                old=0 # Date in seconds
  local          time_step=0 # Seconds between timestamps
  local             ld=false # Leap day flag
  local               tmp="" # For temp values
  local    predicted_date="" # The predicted value for the next timestamp
  local h_mess="$(cat <<-EOF
cdo_mis_timestamp <NetCDF file>

This functions checks for missing timestamps in a NetCDF file

Positional Arguments:
$1  name of a NetCDF file
Flags:
[ -l ] Don't ignore leap days
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
  
  # Check for flag
  [ "$1" == "-l" ] && {
    ld=true
    shift
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
  
  # uniqList is a function that returns a list of only uniques values, and will return 2 if there were duplicates
  ts=$(uniqList "$ts" " ")
  [ $? -eq 2 ] && { echo "Warning: duplicates found"; }
  
  # Start loop through the timestamps, checking that each new step is the expected value. Some checks are in place in case the value is not the expected value, but should otherwise be correct. (Example, monthly datasets aren't usually equally spaced due to their being varying numbers of days in a month.)
  for i in ${ts[@]}; do
    new_str_date=$(date -d"$i" --rfc-3339=seconds)
    
    # This only triggers on the first loop
    [ $old_str_date -eq 0 ] && { old_str_date="$new_str_date"; continue; }
    
    # Get the seconds version of the dates
    old=$(date -d"$old_str_date" '+%s')
    new=$(date -d"$new_str_date" '+%s')
    
    # This only triggers on the second loop
    [ $time_step -eq 0 ] && { 
      time_step=$(( new - old ))
      [ $time_step -le 0 ] && return 2
      continue
    }
    
    # Use date string manipulation to predict the next timestamp
    tmp=$(( old + time_step ))
    predicted_date=$(date -d @$tmp --rfc-3339=seconds)
    echo "predicted: $predicted_date"
    echo "actual:    $new_str_date"
  done
  
  return 0
}