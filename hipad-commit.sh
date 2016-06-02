#!/bin/bash

BASEDIR=$(dirname $0)

git config --global commit.template $HOME/.gittemplate


# 1.Get TAG from file list
LIST=("project.list" "team.list" "feature.list" "subfeature.list")
TAG=()
for ((i=0; i<${#LIST[@]}; i++ ));
do
sort -o ${BASEDIR}/sort.txt ${BASEDIR}/${LIST[$i]}
source ${BASEDIR}/import.sh ${BASEDIR}/sort.txt
VAR=$(dialog --clear \
	--backtitle "$BACKTITLE" \
	--title "$TITLE" \
	--menu "$MENU" \
	$HEIGHT $WIDTH $CHOICE_HEIGHT \
	"${OPTIONS[@]}" \
	2>&1 >/dev/tty)
#add $VAR to array TAG
TAG+=($VAR)
done

clear
#echo "${TAG[@]}" 
rm ${BASEDIR}/sort.txt


# 2.cp Golden git template to temp file "output.txt"
cp -p ${BASEDIR}/.gittemplate ${BASEDIR}/output.txt


# 3.parse 1st line [XXX][AAA][BBB][CCC] from .gittemplate and push into array=(XXX,AAA,BBB,CCC)
array=()
s=$(sed -n '1p' ${BASEDIR}/output.txt);
while IFS=']' read -r token s <<< "$s"; do
        #echo "$s"
        #echo "$token"

        if [ "$token" != "" ];
        then
                #echo "$token"
                IFS='[' read -r test token <<< "$token"
                if [ "token" != "" ];
                then
                        array+=($token)
                        #echo "$token"
                else
                        echo "end"
                fi

        else
                #echo "${array[@]}"
                #echo "NULL"
                break
        fi
done
#echo "$array{@}"


# 4. Replace array() with TAG))
for ((i=0; i<${#array[@]}; i++ ));
do
	sed -i -e "s/${array[$i]}/${TAG[$i]}/g" ${BASEDIR}/output.txt
done



# Show our final gittemplate
dialog --textbox ${BASEDIR}/output.txt 0 0
clear

# Move to ~/.gittemplate where we will use
mv -f ${BASEDIR}/output.txt $HOME/.gittemplate
