#!/bin/bash

# name of function
# created:
#        YYYY-MM-DD
#        Randy Miller
#        rsm5139@psu.edu

# last modified on YYYY-MM-DD

# purpose: short description of the purpose of the function
# input: input arguments
# output: what is output, if anything
# return codes: a list of return code meanings

# source list
source functions/func1.sh || exit

func1
echo $?
