#!/bin/bash

# cdo_mis_timestamp
# created:
#        2017-01-20
#        Randy Miller
#        rsm5139@psu.edu

# last modified on 2017-02-20

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
  local h_mess="
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
"

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
    [ "$old_str_date" == "0" ] && { old_str_date="$new_str_date"; continue; }
    
    # Get the seconds version of the dates
    old=$(date -d"$old_str_date" '+%s')
    new=$(date -d"$new_str_date" '+%s')
    
    # This only triggers on the second loop
    [ $time_step -eq 0 ] && { 
      time_step=$(( new - old ))
      [ $time_step -le 0 ] && return 2
      old_str_date="$new_str_date"
      continue
    }
    
    # Use date string manipulation to predict the next timestamp
    tmp=$(( old + time_step ))
    predicted_date=$(date -d @$tmp --rfc-3339=seconds)
    
    # Is the new timestamp within a 11% error margin? Then pass it
    # Note: 11% is the worst-case scenario for how much regularly-spaced data can be off while technically being accurate. It's the error margin between a 28 day month and a 31 day month
    [ $(( new + time_step / 9 )) -gt $tmp ] && [ $(( new - time_step / 9 )) -lt $tmp ] && {
      old_str_date="${new_str_date}"
      continue
    }
    
    # Is this a missing leap day? We can pass or fail the check depending on user flag '-l'
    $ld || {
      [[ "${predicted_date:0:10}" =~ [0-9]{4}-02-29 ]] && [[ "${new_str_date:0:10}" =~ [0-9]{4}-03-01 ]] && {
      old_str_date="${new_str_date}"
      continue
      }
    }
    
    # Leap days could still affect annual data or data with longer sampling frequencies. A date trick could be used here to increment by year
    # Note: 31536000 is the number of seconds in a year. 
    [ 31536000 -le $time_step ] && {
      tmp=$(( time_step / 31536000 ))
      predicted_date=$(date -d "$old_str_date+$tmp years" --rfc-3339=seconds)
      [ "${predicted_date:0:4}" == "${new_str_date:0:4}" ] && {
        old_str_date="${new_str_date}"
        continue
      }
    }
    
    # If we are here, it looks like it's a missing timestamp
    echo "Error before $new_str_date" >&2
    return 2
  done
  
  return 0
}