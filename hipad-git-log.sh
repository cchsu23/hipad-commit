#!/bin/bash
BASEDIR=$(dirname $0)

#git config --global alias.hipad-git-log '!~/.hipad-commit/hipad-git-log.sh'

trap "echo clean temp files;rm ${BASEDIR}/feature1.list;rm ${BASEDIR}/temp.csv;rm ${BASEDIR}/final.csv;rm ${BASEDIR}/statistics.csv;rm ${BASEDIR}/result.txt;exit 1" SIGTERM SIGINT SIGHUP



git_config=".git/config"
candidate_config="${PWD}/${git_config}"
has_only_one_git=0
if [ ! -e "${candidate_config}" ]
then
	echo "Not a valid git repository"
else
	has_only_one_git=1
fi

#search .repo from current folder to parrent foler "/"
path=$PWD
shift 1
while [[ "$path" != "/" ]];
do
    if find "$path" -maxdepth 1 -mindepth 1 -iname ".repo" -print -quit | grep -q .
    then
	echo "path =$path"
	break
    else
    # Note: if you want to ignore symlinks, use "$(realpath -s $path/..)"
    	path="$(readlink -f $path/..)"
    fi
done

repo_prjoct_path="$path/.repo/project.list"
if [ "$path" != "/" ]
then
   echo "success, found the .repo"
   repo_project_num=$(wc -l < $repo_prjoct_path)
   #due to found the .repo ,  clear has_only_one_git to 0
   has_only_one_git=0
else
   echo "can not find any .repo folder"
   if [ "$has_only_one_git" != "0" ]
   then
	   echo "has at least one .git folder"
	   repo_project_num=1
	   path=${PWD}
	   repo_prjoct_path=""
    else
	   repo_project_num=0
	   path=${PWD}
	   repo_prjoct_path=""
	fi
fi

echo "Root path=$path .repo project path =$repo_prjoct_path  total project=$repo_project_num"
#====================================================================
# git log
# -p			Show the patch introduced with each commit.
# --stat		Show statistics for files modified in each commit.
# --shortstat		Display only the changed/insertions/deletions line from the --stat command.
# --name-only		Show the list of files modified after the commit information.
# --name-status		Show the list of files affected with added/modified/deleted information as well.
# --abbrev-commit	Show only the first few characters of the SHA-1 checksum instead of all 40.
# --relative-date	Display the date in a relative format (for example, “2 weeks ago”) instead of using the full date format.
# --graph		Display an ASCII graph of the branch and merge history beside the log output.
# --pretty		Show commits in an alternate format. Options include oneline, short, full, fuller, and format (where you specify your own format).

# --pretty=format
# %H	Commit hash
# %h	Abbreviated commit hash
# %T	Tree hash
# %t	Abbreviated tree hash
# %P	Parent hashes
# %p	Abbreviated parent hashes
# %an	Author name
# %ae	Author email
# %ad	Author date (format respects the --date=option)
# %ar	Author date, relative
# %cn	Committer name
# %ce	Committer email
# %cd	Committer date
# %cr	Committer date, relative
# %s	Subject

# We use %h,%ae,%ad,%s


# git log (filter)
# -(n)			Show only the last n commits
# --since, --after	Limit the commits to those made after the specified date.
# --until, --before	Limit the commits to those made before the specified date.
# --author		Only show commits in which the author entry matches the specified string.
# --committer		Only show commits in which the committer entry matches the specified string.
# --grep		Only show commits with a commit message containing the string
# -S			Only show commits adding or removing code matching the string
# --no-merge
#====================================================================
parameter=()
PROJECT=()
CUSTOMER=()
CATEGORY=()
DIALOG_CANCEL=1
DIALOG_ESC=255

#Get Screen Size
size=$(dialog --stdout --print-maxsize)
SCREEN_WIDTH=$(cut -d " " -f 3 <<< $size)
let "SCREEN_WIDTH += 0"
echo "$SCREEN_WIDTH"
SCREEN_HEIGHT=$(cut -d " " -f 2 <<< $size | cut -d "," -f 1 )
let "SCREEN_HEIGHT += 0"
echo $SCREEN_HEIGHT

HEIGHT=$((SCREEN_HEIGHT/2))
WIDTH=$((SCREEN_WIDTH/2))
CHOICE_HEIGHT=$((SCREEN_HEIGHT/2-4))

git_log(){
	#echo "$@" > ${BASEDIR}/last_cmd.csv
	git log $@ > ${BASEDIR}/temp.csv
}

get_data_from_google_sheet() {
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
		 #radiolist 3rd is status
		 PROJECT+=("off")
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
		 #radiolist 3rd is status
		 CUSTOMER+=("off")
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
		 #radiolist 3rd is status
		 CATEGORY+=("off")
		 CATEGORY_MENU+=($line)
		 CATEGORY_MENU+=($line)
	done < ${BASEDIR}/category.list


	#d.get google doc feature "All sheet"  and delete duplicated items, and space line . And then sorting 
	wget –no-check-certificate -q -O - "https://docs.google.com/spreadsheets/d/1oR1KIbzTh5waDZN2HgOsBLqNbD2w4lderKyAnxI5RJA/pub?gid=333944621&single=true&output=csv" | sed '/^\s$*/d' | sort | uniq > ${BASEDIR}/feature.list

	#Convert CR+LR(Windows)  to LF (linux)
	dos2unix ${BASEDIR}/feature.list

}

select_author() {
	VAR=$(dialog \
		--scrollbar \
		--stderr \
		--stdout \
		--title "$1" \
		--inputbox "Author:" $HEIGHT $WIDTH @hipad.com)
	TAG_AUTHOR+=($VAR)
}

select_since_date() {
	#Select date
	year=$(LAN='en_us' date +%Y)
	mon=$(LAN='en_us' date +%m)
	day=$(LAN='en_us' date +%d)

	TAG_SINCE_DATE=$(dialog --stdout --title "$1" \
	--calendar "Select a date:" 0 0 $day $mon $year)

	case $? in
	0)
	 echo "You have entered: $TAG_SINCE_DATE"   ;;
	1)
	 echo "You have pressed Cancel"  ;;
	255)
	 echo "Box closed"   ;;
	esac
}

select_until_date() {
	#Select date
	year=$(LAN='en_us' date +%Y)
	mon=$(LAN='en_us' date +%m)
	day=$(LAN='en_us' date +%d)

	TAG_UNTIL_DATE=$(dialog --stdout --title "$1" \
	--calendar "Select a date:" 0 0 $day $mon $year)

	case $? in
	0)
	 echo "You have entered: $TAG_UNTIL_DATE"   ;;
	1)
	 echo "You have pressed Cancel"  ;;
	255)
	 echo "Box closed"   ;;
	esac
}

select_project() {
	#Create Dialog by file list
	VAR=$(dialog \
	--scrollbar \
	--stderr \
	--stdout \
	--title "$1" \
	--checklist "$1" \
	$HEIGHT $WIDTH $CHOICE_HEIGHT \
	"${PROJECT[@]}" \
	)
	TAG_PROJECT+=($VAR)
}

select_customer() {
	#Create Dialog by file list
	VAR=$(dialog \
	--scrollbar \
	--stderr \
	--stdout \
	--title "$1" \
	--checklist "$1" \
	$HEIGHT $WIDTH $CHOICE_HEIGHT \
	"${CUSTOMER[@]}" \
	)
	TAG_CUSTOMER+=($VAR)
}

select_category() {
	#Create Dialog by file list
	VAR=$(dialog \
	--scrollbar \
	--stderr \
	--stdout \
	--title "$1" \
	--checklist "$1" \
	$HEIGHT $WIDTH $CHOICE_HEIGHT \
	"${CATEGORY[@]}" \
	)
	TAG_CATEGORY+=($VAR)
}

select_feature() {
	#Create Dialog by file list
	CAT_MENU=$(dialog \
	--scrollbar \
	--stderr \
	--stdout \
	--title "Category" \
	--menu "Category" \
	$HEIGHT $WIDTH $CHOICE_HEIGHT \
	"${CATEGORY_MENU[@]}" \
	)

	FEATURE=()
	#Parsing feature.list by google doc feature "All sheet" & "MergeAllFeature"
	cat ${BASEDIR}/feature.list | grep "$CAT_MENU" | cut -d "," -f 1 | sort | uniq > ${BASEDIR}/feature1.list
	while IFS= read -r line
	do
		 FEATURE+=($line)
		 #--no-items Version: 1.1-20111020 does not support
		 FEATURE+=($line)
		 #radiolist 3rd is status
		 FEATURE+=("off")
	done < ${BASEDIR}/feature1.list
	rm ${BASEDIR}/feature1.list

	VAR=$(dialog \
	--scrollbar \
	--stderr \
	--stdout \
	--title "$CAT_MENU" \
	--checklist "$CAT_MENU" \
	$HEIGHT $WIDTH $CHOICE_HEIGHT \
	"${FEATURE[@]}" \
	)
	TAG_FEATURE+=($VAR)
}


if [ "$repo_project_num" != "0" ]
then
	#get data form google sheet here
	get_data_from_google_sheet
	#==============================Filter Start==============================#


	while true; do

		exec 3>&1
		selection=$(dialog \
		--backtitle "Hipad Git Log" \
		--title "Filter Menu" \
		--clear \
		--ok-label "Select" \
		--cancel-label "Hipad Git log" \
		--menu "Press ESC to exit the program\nPlease Select:\n" $HEIGHT $WIDTH $CHOICE_HEIGHT \
		"1" "Filter by Author" \
		"2" "Filter by Since Date" \
		"3" "Filter by Until Date" \
		"4" "Filter by Hipad Commit Project" \
		"5" "Filter by Hipad Commit Customer" \
		"6" "Filter by Hipad Commit Category" \
		"7" "Filter by Hipad Commit Feature" \
		2>&1 1>&3)
		exit_status=$?
		exec 3>&-

		case $exit_status in
		$DIALOG_CANCEL)
		clear
		echo "Start to git log"
		break
		;;
		$DIALOG_ESC)
		clear
		echo "Program aborted." >&2
		exit 1
		;;
		esac

		case $selection in
		0 )
		clear
		echo "Program terminated."
		;;
		1 )
		select_author "Filter by Author"
		;;
		2 )
		select_since_date "Filter by Since Date"
		;;
		3 )
		select_until_date "Filter by Until Date"
		;;
		4 )
		select_project "Filter by Hipad Commit Project"
		;;
		5 )
		select_customer "Filter by Hipad Commit Customer"
		;;
		6 )
		select_category "Filter by Hipad Commit Category"
		;;
		7 )
		select_feature "Filter by Hipad Commit Feature"
		;;
		esac
	
		#do sort and uniq
		TAG_AUTHOR=($(echo ${TAG_AUTHOR[@]} | tr [:space:] '\n' | awk '!a[$0]++'))
		TAG_PROJECT=($(echo ${TAG_PROJECT[@]} | tr [:space:] '\n' | awk '!a[$0]++'))
		TAG_CUSTOMER=($(echo ${TAG_CUSTOMER[@]} | tr [:space:] '\n' | awk '!a[$0]++'))
		TAG_CATEGORY=($(echo ${TAG_CATEGORY[@]} | tr [:space:] '\n' | awk '!a[$0]++'))
		TAG_FEATURE=($(echo ${TAG_FEATURE[@]} | tr [:space:] '\n' | awk '!a[$0]++'))

		echo "Author: ${TAG_AUTHOR[@]}" > ${BASEDIR}/result.txt
		echo "Since Date: $TAG_SINCE_DATE" >> ${BASEDIR}/result.txt
		echo "Until Date: $TAG_UNTIL_DATE" >> ${BASEDIR}/result.txt
		echo "Project: ${TAG_PROJECT[@]}" >> ${BASEDIR}/result.txt
		echo "Customer: ${TAG_CUSTOMER[@]}" >> ${BASEDIR}/result.txt
		echo "Category: ${TAG_CATEGORY[@]}" >> ${BASEDIR}/result.txt
		echo "Feature: ${TAG_FEATURE[@]}" >> ${BASEDIR}/result.txt
		
		dialog \
		--scrollbar \
		--stderr \
		--stdout \
		--title "Git Log Parameter" \
		--textbox ${BASEDIR}/result.txt $HEIGHT $WIDTH
	done




	#======================Put Tags into parameter==================
	parameter+=$(echo "--pretty=format:"%h,%ae,%ad,%s" ")
	#parameter+=$(echo "--author @hipad.com ")
	#parameter+=$(echo "--grep Common ")

	for ((i=0; i<${#TAG_AUTHOR[@]}; i++ ));
	do
		if [ "${TAG_AUTHOR[$i]}" != "" ];
		then
			parameter+=$(echo "--author=${TAG_AUTHOR[$i]} ")
		else
			:
		fi
	done

	if [ "$TAG_SINCE_DATE" != "" ]
	then
		parameter+=$(echo "--since=$TAG_SINCE_DATE ")
	fi

	if [ "$TAG_UNTIL_DATE" != "" ]
	then
		parameter+=$(echo "--until=$TAG_UNTIL_DATE ")
	fi

	for ((i=0; i<${#TAG_PROJECT[@]}; i++ ));
	do
		if [ "${TAG_PROJECT[$i]}" != "" ];
		then
			parameter+=$(echo "--grep=${TAG_PROJECT[$i]} ")
		else
			:
		fi
	done

	for ((i=0; i<${#TAG_CUSTOMER[@]}; i++ ));
	do
		if [ "${TAG_CUSTOMER[$i]}" != "" ];
		then
			parameter+=$(echo "--grep=${TAG_CUSTOMER[$i]} ")
		else
			:
		fi
	done


	for ((i=0; i<${#TAG_CATEGORY[@]}; i++ ));
	do
		if [ "${TAG_CATEGORY[$i]}" != "" ];
		then
			parameter+=$(echo "--grep=${TAG_CATEGORY[$i]} ")
		else
			:
		fi
	done
	
	for ((i=0; i<${#TAG_FEATURE[@]}; i++ ));
	do
		if [ "${TAG_FEATURE[$i]}" != "" ];
		then
			parameter+=$(echo "--grep=${TAG_FEATURE[$i]} ")
		else
			:
		fi
	done

	echo "Cmdline: ${parameter[@]}" >> ${BASEDIR}/result.txt
	
	SECONDS=0
	#==============================Progress Start==============================#
	dialog --title "Total Projct $repo_project_num" --gauge "Search each git repository..." 10 100 < <(
	rm ${BASEDIR}/final.csv &> /dev/null
	rm ${BASEDIR}/statistics.csv &> /dev/null
	#rm ${BASEDIR}/path.csv &> /dev/null
	for (( i=1; i<=$repo_project_num; i++ ))
	do
		if [ "$has_only_one_git" != "0" ]
		then
			file=$PWD
		else	
			file=$(sed -n "${i},${i}p" $repo_prjoct_path)
			cd "$path/$file"
			#echo "$i,$PWD" >> ${BASEDIR}/path.csv
		fi
		
		#=================Git log===================#
		git_log "${parameter[@]}"

		#add newline to the file
		sed -i -e '$a\' ${BASEDIR}/temp.csv

		#count the file size
		actualsize=$(wc -c <${BASEDIR}/temp.csv)
		echo "git log done! file size=$actualsize"

		#replace  '['  with ' ' 
		sed -i -e 's/\[/\ /g' ${BASEDIR}/temp.csv

		#replace  ']'  with ','
		sed -i -e 's/]/,/g' ${BASEDIR}/temp.csv

		proj=$file
		proj+=","
		#add proj each line , ${proj} have the path '/', so use '#' to instead of
		sed -i -e "s#^#${proj}#" ${BASEDIR}/temp.csv

		#and then append to final.csv
		cat ${BASEDIR}/temp.csv  >> ${BASEDIR}/final.csv
		
		#counting
		count=$(wc -l < ${BASEDIR}/temp.csv )
		echo "$i,$proj,$count" >> ${BASEDIR}/statistics.csv

		

		#remove temp file
		rm ${BASEDIR}/temp.csv

		
		percentage=$((100*(i)/$repo_project_num))
		#echo "$percentage"
cat <<EOF
XXX
$percentage
$i Search each git repository $path/$file
XXX
EOF

	done
	)
fi #end of if [ "$repo_project_num" != "0" ]

echo "Final Result CVS file: ${BASEDIR}/final.csv" >> ${BASEDIR}/result.txt
echo "Statistics CVS file: ${BASEDIR}/statistics.csv" >> ${BASEDIR}/result.txt
echo "This File: ${BASEDIR}/result.txt" >> ${BASEDIR}/result.txt
echo "Elapsed time: $SECONDS seconds" >> ${BASEDIR}/result.txt

dialog \
--scrollbar \
--stderr \
--stdout \
--title "Result" \
--textbox ${BASEDIR}/result.txt $HEIGHT $WIDTH
		
#add newline to the file
sed -i -e '$a\' ${BASEDIR}/statistics.csv &> /dev/null
#add newline to the file
sed -i -e '$a\' ${BASEDIR}/final.csv &> /dev/null

#count the file size
actualsize=$(wc -c <${BASEDIR}/final.csv) &> /dev/null
echo "final.csv=$actualsize"






