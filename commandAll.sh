#!/bin/bash

# bashLib.sh
# created:
#     Randy Miller
#     rsm5139@psu.edu
#     2016-06-09

# last modified on 2016-06-09

# usage: . bashLib.sh

##################################################################
# Purpose: Executes a command on every file in a directory
# Arguments:
#   $1 -> Command
# Flags:
#   -r -> Search subdirectories for files
#   -d -> Perform commands on directories intstead of files
#   --prefix "<path/to/directory>" -> Directory to execute
#   --options "<options/flags>" -> String of options and flags
#                                  to be passed to the command.
#                                  The filename will be placed 
#                                  after the options.
#   --ext "<extension to include>" -> List of extensions of files
#                                     to include. EXP ".txt.nc"
#                                     Default is all files
##################################################################
function usage()
{
  echo "Usage: commandAll [-r -d --prefix \"<path/to/directory>\" --options \"<options/flags>\" --ext \"<extensions to include>\"] command"
  echo ""
  echo "  command: command to execute"
  echo "        EXP: \"echo\""
  echo "  -r: search subdirectories"
  echo "  -d: perform commands on directories instead of files"
  echo "  --prefix \"<path/to/directory>\": directory to execute"
  echo "  --options \"<options/flags>\": String of options and flags to be passed to the command. The filename will be placed after the options."
  echo "        EXP: --options \"-rf\" command"
  echo "        RESULT: command -rf filename"
  echo "  --ext: List of extensions of files to include"
  echo "        EXP: --ext \".txt.nc\""
  echo "        RESULT: only filename.txt and filename.nc will be passed to the command"
  echo "        DEFAULT: all files are passed to the command"
}

[ "$#" -lt 1 ] && usage && return 0

# Set defaults
command_str=""
prefix=""
options=""
ext=""
r=1
d=1

# Get arguments
while [[ $# > 0 ]]; do
  arg="$1"
  case "$arg" in
    -r )
      r=0
      ;;
    -d )
      d=0
      ;;
    --options )
      options="$2"
      shift
      ;;
    --ext )
      ext="$2"
      shift
      ;;
    --prefix )
      prefix="$2"
      shift
      ;;
    -* )
      echo "  Error: ${arg} is not a valid flag"
      usage
      return 1
      ;;
    * )
      command_str="$1"
  esac
  shift
done

# Loop through directory
old_ifs=$IFS
IFS=$(echo -en "\n\b")
for name in $prefix/*; do
  # Is name a directory?
  if [ -d "$name" ]; then
    # yes -> Is -r set?
    if [ "$r" == "0" ]; then
      # yes -> Start recursion
      # Is -d set?
      if [ "$d" == "0" ]; then
        # yes -> Call commandAll with -d option set
        cmd_str="commandAll -d -r --options \"${options}\" --ext \"${ext}\" --prefix \"$name\" \"${command_str}\""
        eval "$cmd_str"
      else
        # no -> Call commandAll without -d flag
        cmd_str="commandAll -r --options \"${options}\" --ext \"${ext}\" --prefix \"$name\" \"${command_str}\""
        eval "$cmd_str"
      fi
    fi
    # Is -d set?
    if [ "$d" == "0" ]; then
      # yes -> Execute command on name
      cmd_str="${command_str} ${options} \"${name}\""
      eval "$cmd_str"
    fi
  # Is ext set?
  elif [ "$ext" != "" ]; then
    # yes -> is file extension in ext?
    file_ext="${name##*.}"
    if [ -z "${ext##*$file_ext*}" ]; then
      # yes -> Execute command on name
      cmd_str="${command_str} ${options} \"${name}\""
      eval "$cmd_str"
    fi
  else
    # Execute command on name
    cmd_str="${command_str} ${options} \"${name}\""
    eval "$cmd_str"
  fi
done
IFS="$old_ifs"