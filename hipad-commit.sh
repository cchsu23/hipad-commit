#!/bin/bash

BASEDIR=$(dirname $0)

git config --global commit.template $HOME/.gittemplate

#1 Project list
source ${BASEDIR}/import.sh ${BASEDIR}/project.list
PROJECT=$(dialog --clear \
       --backtitle "$BACKTITLE" \
       --title "$TITLE" \
       --menu "$MENU" \
       $HEIGHT $WIDTH $CHOICE_HEIGHT \
       "${OPTIONS[@]}" \
	   2>&1 >/dev/tty)

#2 Feature list
source ${BASEDIR}/import.sh ${BASEDIR}/feature.list
FEATURE=$(dialog --clear \
       --backtitle "$BACKTITLE" \
       --title "$TITLE" \
       --menu "$MENU" \
       $HEIGHT $WIDTH $CHOICE_HEIGHT \
       "${OPTIONS[@]}" \
	   2>&1 >/dev/tty)

#3 test list
#source ${BASEDIR}/import.sh test.list
#TEST=$(dialog --clear \
#       --backtitle "$BACKTITLE" \
#       --title "$TITLE" \
#       --radiolist "$MENU" \
#       $HEIGHT $WIDTH $CHOICE_HEIGHT \
#       "${OPTIONS[@]}" \
#	   2>&1 >/dev/tty)

clear

#cp Golden git template to temp file "output.txt"
cp -p ${BASEDIR}/.gittemplate ${BASEDIR}/output.txt



#1 Replace Project with selection
sed -i -e "s/Project/$PROJECT/g" ${BASEDIR}/output.txt

#2 Replace Component with selection
sed -i -e "s/Component/$FEATURE/g" ${BASEDIR}/output.txt

#3 Replace test with selection
#sed -i -e "s/Test/$TEST/g" ${BASEDIR}/output.txt


# Show our final gittemplate
dialog --textbox ${BASEDIR}/output.txt 0 0
clear

# Move to ~/.gittemplate where we will use
mv -f ${BASEDIR}/output.txt $HOME/.gittemplate
