#!/bin/bash

# uniqList
# created:
#        2017-01-19
#        Randy Miller
#        rsm5139@psu.edu

# last modified on 2017-01-20

# main function
function uniqList()
{
  # Initialize variables
  local delim=','
  local str=''
  local sort_options='-u'
  local h_mess="$(cat <<-EOF
uniqList [-f] <deliminited string> [delimiter]

Takes a delimited string and returns a sorted delimited string with only the unique elements from the original string.
Can also check for duplicates.

Flags:
-f  case insensitive
Positional Arguments:
$1  delimited string
$2  delimiter (default: ',')
Return Codes:
0   normal return: no errors
1   function call argument errors
2   indicates list had duplicate entries

Example:
uniqList -f "World hello world" " "
->  hello world

uniqList "cats,dogs,birds,cats"
->  birds,cats,dogs
EOF
  )"

  # Check for at least 1 argument
  [ "$#" -lt 1 ] && {
    echo "Too few arguments" >&2
    echo "" >&2
    echo "$h_mess" >&2
    return 1
  }

  # If flag is set, then change the sort options
  [ "$1" == "-f" ] && { sort_options="-u -f"; shift; }

  # Is the string argument set?
  [ -z "$1" ] && {
    echo "String argument no set" >&2
    echo "" >&2
    echo "$h_mess" >&2
    return 1
  }
  str="$1"

  # If delimiter is specified, then set it
  [ -z "$2" ] || delim="$2"

  # The heart of this is the 'sort -u' part. It sorts the items and only leaves
  # unique elements. The ending 'sed' removes the delimiter that may appear at the
  # front or end of the string.
  str=$(echo "$str" | tr "$delim" '\n' | sort $sort_options | tr '\n' "$delim" | sed -e "s/$delim$//" -e "s/^$delim//")

  # Echo the new delimited list
  echo "$str"

  # An additional test to see if elements were removed from the list
  IFS="$delim" read -a arr1 <<<"$1"
  IFS="$delim" read -a arr2 <<<"$str"
  
  [ ${#arr1[@]} -eq ${#arr2[@]} ] || return 2

  return 0
}

# test function, if applicable
function test_uniqList()
{
  local t=$(uniqList -f "World hello world" " ")
  local rc=-1
  echo "output: $t"
  [ "$t" == "hello World" ] && { echo "Test 1 passed"; } || { echo "Test 1 failed"; }
  uniqList -f "World hello world" " " > /dev/null
  rc=$?
  echo "return code: $rc"
  [ $rc -eq 2 ] && { echo "Test 2 passed"; } || { echo "Expected return code of 2"; }
  uniqList -f "one,two,three" "," > /dev/null
  rc=$?
  echo "return code: $rc"
  [ $rc -eq 0 ] && { echo "Test 3 passed"; } || { echo "Expected return code of 0"; }
  return 0
}