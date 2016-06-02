#!/bin/bash

BASEDIR=$(dirname $0)

git config --global commit.template ${BASEDIR}/.gittemplate

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


# 2.cp .git/COMMIT_EDITMSG to temp file "output.txt"
cp -p $PWD/.git/COMMIT_EDITMSG ${BASEDIR}/output.txt


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
                echo "${array[@]}"
                #echo "NULL"
                break
        fi
done
echo "$array{@}"

# 4.Check format is at lease 1 "[XXX]", or will use template
if [ "${#array[@]}" == "0" ];
then
	echo "0"
	use_template="yes"
else
	echo "${#array[@]}"
	use_template="no"
fi


echo "$use_template"

# 4.1 .cp .gittemplate to temp file "output.txt"
if [ "$use_template" == "yes" ];
then
	echo "use template now"
	# cat two files into output.txt
	cat ${BASEDIR}/.gittemplate $PWD/.git/COMMIT_EDITMSG > ${BASEDIR}/output.txt
	# 4.2 parse 1st line [XXX][AAA][BBB][CCC] from .gittemplate and push into array=(XXX,AAA,BBB,CCC)
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
                echo "${array[@]}"
                #echo "NULL"
                break
        fi
	done
else
	echo "use COMMIT_MSG"
fi



# 5. Replace array() with TAG))
for ((i=0; i<${#array[@]}; i++ ));
do
	if [ "${TAG[$i]}" != "" ];
	then
		sed -i -e "s/${array[$i]}/${TAG[$i]}/g" ${BASEDIR}/output.txt
	else
		:
	fi
done



# 6.Show our final gittemplate
dialog --textbox ${BASEDIR}/output.txt 0 0
clear


#echo "$use_template"
# 7.Move to .git/COMMIT_EDITMSG where we will use
mv -f ${BASEDIR}/output.txt $PWD/.git/COMMIT_EDITMSG
