#!/bin/bash
HEIGHT=30
WIDTH=60
CHOICE_HEIGHT=25
BACKTITLE="Hipad commit"
TITLE="$1"
MENU="Choose one of the following options:"


#IFS=$'\n' read -d '' -r -a OPTIONS < $1

OPTIONS=()

while IFS= read -r line
do
	 OPTIONS+=($line)
	 OPTIONS+=($line)

done < $1


#print all OPTIONS  array
echo "${OPTIONS[@]}"

