#!/bin/bash
HEIGHT=15
WIDTH=40
CHOICE_HEIGHT=4
BACKTITLE="Hipad commit"
TITLE="$1"
MENU="Choose one of the following options:"

#print parameter 1 
#echo $TITLE


#IFS=$'\n' read -d '' -r -a OPTIONS < $1

OPTIONS=()

while IFS= read -r line
do
	 OPTIONS+=($line)
	 OPTIONS+=($line)

done < $1


#print all OPTIONS  array
echo "${OPTIONS[@]}"

