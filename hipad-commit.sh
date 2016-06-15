#!/bin/bash

BASEDIR=$(dirname $0)

git config --global commit.template ${BASEDIR}/.gittemplate


trap "echo clean temp files;rm ${BASEDIR}/feature1.list;rm ${BASEDIR}/output.txt;exit 1" SIGTERM SIGINT SIGHUP
#=============================================================================#
# 1.cp .git/COMMIT_EDITMSG to temp file "output.txt"
cp -p $PWD/.git/COMMIT_EDITMSG ${BASEDIR}/output.txt

#=============================================================================#
# 2.parse 1st line [XXX][AAA][BBB][CCC] from .gittemplate and push into array=(XXX,AAA,BBB,CCC)
array=()
s=$(sed -n '1p' ${BASEDIR}/output.txt);
while IFS=']' read -r token s <<< "$s"
do
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
#echo "${array[@]}"

#=============================================================================#
# 3.Check format is at lease 1 "[XXX]", or will use template
if [ "${#array[@]}" == "0" ];
then
	echo "0"
	use_template="yes"
else
	echo "${#array[@]}"
	use_template="no"
fi


echo "$use_template"


#=============================================================================#
# 4.1 .cp .gittemplate to temp file "output.txt"
if [ "$use_template" == "yes" ];
then
	echo "use template now"
	# cat two files into output.txt
	cat ${BASEDIR}/.gittemplate $PWD/.git/COMMIT_EDITMSG > ${BASEDIR}/output.txt
	# 4.2 parse 1st line [XXX][AAA][BBB][CCC] from .gittemplate and push into array=(XXX,AAA,BBB,CCC)
	array=()
	s=$(sed -n '1p' ${BASEDIR}/output.txt);
	while IFS=']' read -r token s <<< "$s"
	do
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

#=============================================================================#
# 5.Get TAG from file list
PROJECT=()
CUTOMER=()
CATEGORY=()
FEATURE=()
TAG=()

TITLE="Hipad Commit"
MENU_PROJECT="PROJECT"
MENU_CUSTOMER="CUSTOMER"
MENU_CATEGORY="CATEGORY"
MENU_FEATURE="FEATURE"

#Get Screen Size
size=$(dialog --stdout --print-maxsize)
SCREEN_WIDTH=$(cut -d " " -f 3 <<< $size)
let "SCREEN_WIDTH += 0"
echo "$SCREEN_WIDTH"
SCREEN_HEIGHT=$(cut -d " " -f 2 <<< $size | cut -d "," -f 1 )
let "SCREEN_HEIGHT += 0"
echo $SCREEN_HEIGHT


#------------
#|          |
#-----------
#|  |   |   |
#------------
HEIGHT=$((SCREEN_HEIGHT/2))
WIDTH=$((SCREEN_WIDTH/3))
CHOICE_HEIGHT=$((SCREEN_HEIGHT/2-4))

#a.get google doc project sheet, and delete duplicated items, and space line . And then sorting 
wget –no-check-certificate -q -O - "https://docs.google.com/spreadsheets/d/1oR1KIbzTh5waDZN2HgOsBLqNbD2w4lderKyAnxI5RJA/pub?gid=1338346914&single=true&output=csv" | sed '/^\s$*/d' | sort | uniq > ${BASEDIR}/project.list

#Convert CR+LR(Windows)  to LF (linux)
dos2unix ${BASEDIR}/project.list

#Parsing project.list
while IFS= read -r line
do
	 PROJECT+=($line)
	 #--no-items Version: 1.1-20111020 does not support
	 PROJECT+=($line)
done < ${BASEDIR}/project.list



#b.get google doc customer sheet, and delete duplicated items, and space line . And then sorting 
wget –no-check-certificate -q -O - "https://docs.google.com/spreadsheets/d/1oR1KIbzTh5waDZN2HgOsBLqNbD2w4lderKyAnxI5RJA/pub?gid=1991161436&single=true&output=csv" | sed '/^\s$*/d' | sort | uniq > ${BASEDIR}/customer.list

#Convert CR+LR(Windows)  to LF (linux)
dos2unix ${BASEDIR}/customer.list

#Parsing customer.list
while IFS= read -r line
do
	 CUSTOMER+=($line)
	 #--no-items Version: 1.1-20111020 does not support
	 CUSTOMER+=($line)
done < ${BASEDIR}/customer.list

#c.get google doc category sheet, and delete duplicated items, and space line . And then sorting 
wget –no-check-certificate -q -O - "https://docs.google.com/spreadsheets/d/1oR1KIbzTh5waDZN2HgOsBLqNbD2w4lderKyAnxI5RJA/pub?gid=1678041552&single=true&output=csv" | sed '/^\s$*/d' | sort | uniq > ${BASEDIR}/category.list

#Convert CR+LR(Windows)  to LF (linux)
dos2unix ${BASEDIR}/category.list

#Parsing category.list
while IFS= read -r line
do
	 CATEGORY+=($line)
	 #--no-items Version: 1.1-20111020 does not support
	 CATEGORY+=($line)
done < ${BASEDIR}/category.list


#Create Dialog by file list
VAR=$(dialog \
	--scrollbar \
	--stderr \
	--stdout \
	--title "$TITLE" \
	--begin 0 0 \
	--textbox ${BASEDIR}/output.txt $((SCREEN_HEIGHT/2)) $SCREEN_WIDTH \
	--and-widget --begin $((SCREEN_HEIGHT/2)) 0 --keep-window --default-item --nocancel \
	--menu "$MENU_PROJECT" \
	$HEIGHT $WIDTH $CHOICE_HEIGHT \
	"${PROJECT[@]}" \
	--and-widget --begin $((SCREEN_HEIGHT/2)) $((SCREEN_WIDTH/3)) --keep-window  --default-item Hipad --nocancel \
	--menu "$MENU_CUSTOMER" \
	$HEIGHT $WIDTH $CHOICE_HEIGHT \
	"${CUSTOMER[@]}" \
	--and-widget --begin $((SCREEN_HEIGHT/2)) $((SCREEN_WIDTH/3*2)) --keep-window  --nocancel \
	--menu "$MENU_CATEGORY" \
	$HEIGHT $WIDTH $CHOICE_HEIGHT \
	"${CATEGORY[@]}")
#add $VAR to TAG()
TAG+=($VAR)

echo "TAG1 = ${TAG[@]}"


#customer=$(echo ${TAG[1]} | tr '[:upper:]' '[:lower:]')
#echo "customer = $customer"

#category=$(echo ${TAG[2]} | tr '[:upper:]' '[:lower:]')
#echo "category = $category"

#check the feature/$team/$customer.list if exist or not
#mkdir -p ${BASEDIR}/feature/$team
#( [ ! -f ${BASEDIR}/feature/$team/$customer.list ]) && echo "Feature_${TAG[2]}" > ${BASEDIR}/feature/$team/$customer.list


#d.get google doc feature "All sheet"  and delete duplicated items, and space line . And then sorting 
wget –no-check-certificate -q -O - "https://docs.google.com/spreadsheets/d/1oR1KIbzTh5waDZN2HgOsBLqNbD2w4lderKyAnxI5RJA/pub?gid=333944621&single=true&output=csv" | sed '/^\s$*/d' | sort | uniq > ${BASEDIR}/feature.list
#d.get google doc feature "MergeAllFeature"  and delete duplicated items, and space line . And then sorting, loading is so slow , so disable
#wget –no-check-certificate -q -O - "https://docs.google.com/spreadsheets/d/1oR1KIbzTh5waDZN2HgOsBLqNbD2w4lderKyAnxI5RJA/pub?gid=594540229&single=true&output=csv" > ${BASEDIR}/feature.list

#Convert CR+LR(Windows)  to LF (linux)
dos2unix ${BASEDIR}/feature.list

#Parsing feature.list by google doc feature "All sheet" & "MergeAllFeature"
cat ${BASEDIR}/feature.list | grep "${TAG[2]}" | cut -d "," -f 1 | sort | uniq > ${BASEDIR}/feature1.list
while IFS= read -r line
do
	 FEATURE+=($line)
	 #--no-items Version: 1.1-20111020 does not support
	 FEATURE+=($line)
done < ${BASEDIR}/feature1.list
rm ${BASEDIR}/feature1.list



#------------
#|         |
#- ---------|
#|    |     |
#------------

HEIGHT=$((SCREEN_HEIGHT/2))
WIDTH=$((SCREEN_WIDTH/2))
CHOICE_HEIGHT=$((SCREEN_HEIGHT/2-4))


VAR=$(dialog \
	--scrollbar \
	--stderr \
	--stdout \
	--title "$TITLE" \
	--begin 0 0 \
	--textbox ${BASEDIR}/output.txt $((SCREEN_HEIGHT/2)) $SCREEN_WIDTH \
	--and-widget --begin $((SCREEN_HEIGHT/2)) 0 --keep-window  --nocancel  \
	--menu "${TAG[2]}" \
	$((SCREEN_HEIGHT/2)) $WIDTH $((SCREEN_HEIGHT-4)) \
	"${FEATURE[@]}" \
	--and-widget --begin $((SCREEN_HEIGHT/2)) $((SCREEN_WIDTH/2)) --keep-window --nocancel \
	--inputbox "BugID:" $((SCREEN_HEIGHT/2)) $((SCREEN_WIDTH/2)) \#)
#add $VAR to TAG()
TAG+=($VAR)

clear
echo "TAG2 = ${TAG[@]}"
#=============================================================================#
# 6. Replace array() with TAG()
echo "Array = ${array[@]}"
echo "Number of Array = ${#array[@]}"
for ((i=0; i<${#array[@]}; i++ ));
do
	if [ "${TAG[$i]}" != "" ];
	then
		#replace all
		#sed -i -e "s/${array[$i]}/${TAG[$i]}/g" ${BASEDIR}/output.txt
		#repalce first match occurrence     ex:  sed '0,/bash/s//sed/' text
		sed -i -e "0,/${array[$i]}/s//${TAG[$i]}/" ${BASEDIR}/output.txt
	else
		:
	fi
done

#unnessaray
#=============================================================================#
# 7.Show our final gittemplate
#dialog --textbox ${BASEDIR}/output.txt 0 0
#clear

#=============================================================================#
# 8.Move to .git/COMMIT_EDITMSG where we will use
mv -f ${BASEDIR}/output.txt $PWD/.git/COMMIT_EDITMSG
