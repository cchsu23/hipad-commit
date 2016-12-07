#!/bin/bash
BASEDIR=$(dirname $0)

#git config --global alias.hipad-git-log '!~/.hipad-commit/hipad-git-log.sh'

output_folder="output"
rm -rf ${BASEDIR}/$output_folder
mkdir -p ${BASEDIR}/$output_folder

final_file="${BASEDIR}/$output_folder/final.csv"
statistics_file="${BASEDIR}/$output_folder/statistics.csv"
result_file="${BASEDIR}/$output_folder/result.txt"
temp_file="${BASEDIR}/$output_folder/temp.csv"


trap "echo clean temp files;rm ${BASEDIR}/feature1.list;rm $temp_file; \
rm $final_file;rm $statistic_file;rm $result_file; \
clear;exit 1" SIGTERM SIGINT SIGHUP


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
	
	if [ "$has_only_one_git" != "0" ]
	then
		echo "has at least one .git folder"
		repo_project_num=1
		path=${PWD}
		repo_prjoct_path=""
	else
		echo "can not find any .repo folder"
		exit 1
		#repo_project_num=0
		#path=${PWD}
		#repo_prjoct_path=""
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
#--committer            Only show commits in which the committer entry matches the specified string.
# --grep		Only show commits with a commit message containing the string
# -S			Only show commits adding or removing code matching the string
# --no-merge
#====================================================================
parameter=()
PROJECT=()
CUSTOMER=()
CATEGORY=()
DIALOG_YES=0
DIALOG_NO=1
DIALOG_CANCEL=1
DIALOG_ESC=255
DIALOG_EXTRA=3
total_number=0

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

################################################
# for doing something in the progress dialog. 
# if not do this, some variable can not be outputed 
#
git_log(){
	#echo "$@" > ${BASEDIR}/last_cmd.csv
	git log $@ > $temp_file
}
#################################################


get_data_from_google_sheet() {
if [ "$use_local_list" == "0" ]
then
	#a.get google doc project sheet, and delete duplicated items, and space line . And then sorting 
	wget –no-check-certificate -q -O - "https://docs.google.com/spreadsheets/d/1oR1KIbzTh5waDZN2HgOsBLqNbD2w4lderKyAnxI5RJA/pub?gid=1338346914&single=true&output=csv" | sed '/^\s$*/d' | sort | uniq > ${BASEDIR}/project.list

	#Convert CR+LR(Windows)  to LF (linux)
	dos2unix ${BASEDIR}/project.list
fi
	#Parsing project.list
	while IFS= read -r line
	do
		 PROJECT+=($line)
		 #--no-items Version: 1.1-20111020 does not support
		 PROJECT+=($line)
		 #radiolist 3rd is status
		 PROJECT+=("off")
	done < ${BASEDIR}/project.list

if [ "$use_local_list" == "0" ]
then
	#b.get google doc customer sheet, and delete duplicated items, and space line . And then sorting 
	wget –no-check-certificate -q -O - "https://docs.google.com/spreadsheets/d/1oR1KIbzTh5waDZN2HgOsBLqNbD2w4lderKyAnxI5RJA/pub?gid=1991161436&single=true&output=csv" | sed '/^\s$*/d' | sort | uniq > ${BASEDIR}/customer.list

	#Convert CR+LR(Windows)  to LF (linux)
	dos2unix ${BASEDIR}/customer.list
fi
	#Parsing customer.list
	while IFS= read -r line
	do
		 CUSTOMER+=($line)
		 #--no-items Version: 1.1-20111020 does not support
		 CUSTOMER+=($line)
		 #radiolist 3rd is status
		 CUSTOMER+=("off")
	done < ${BASEDIR}/customer.list

if [ "$use_local_list" == "0" ]
then
	#c.get google doc category sheet, and delete duplicated items, and space line . And then sorting 
	wget –no-check-certificate -q -O - "https://docs.google.com/spreadsheets/d/1oR1KIbzTh5waDZN2HgOsBLqNbD2w4lderKyAnxI5RJA/pub?gid=1678041552&single=true&output=csv" | sed '/^\s$*/d' | sort | uniq > ${BASEDIR}/category.list

	#Convert CR+LR(Windows)  to LF (linux)
	dos2unix ${BASEDIR}/category.list
fi
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

if [ "$use_local_list" == "0" ]
then
	#d.get google doc feature "All sheet"  and delete duplicated items, and space line . And then sorting 
	wget –no-check-certificate -q -O - "https://docs.google.com/spreadsheets/d/1oR1KIbzTh5waDZN2HgOsBLqNbD2w4lderKyAnxI5RJA/pub?gid=333944621&single=true&output=csv" | sed '/^\s$*/d' | sort | uniq > ${BASEDIR}/feature.list

	#Convert CR+LR(Windows)  to LF (linux)
	dos2unix ${BASEDIR}/feature.list
fi

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

input_custom_grep(){
	VAR=$(dialog \
		--scrollbar \
		--stderr \
		--stdout \
		--title "$1" \
		--inputbox "Custom String, delimited by space:" $HEIGHT $WIDTH "test1 test2 test3")

	for word in $VAR
	do
		TAG_CUSTOM_STRING+=($word)
	done
}

print_and_show() {
	#do sort and uniq
	TAG_AUTHOR=($(echo ${TAG_AUTHOR[@]} | tr [:space:] '\n' | awk '!a[$0]++'))
	TAG_PROJECT=($(echo ${TAG_PROJECT[@]} | tr [:space:] '\n' | awk '!a[$0]++'))
	TAG_CUSTOMER=($(echo ${TAG_CUSTOMER[@]} | tr [:space:] '\n' | awk '!a[$0]++'))
	TAG_CATEGORY=($(echo ${TAG_CATEGORY[@]} | tr [:space:] '\n' | awk '!a[$0]++'))
	TAG_FEATURE=($(echo ${TAG_FEATURE[@]} | tr [:space:] '\n' | awk '!a[$0]++'))
	TAG_CUSTOM_STRING=($(echo ${TAG_CUSTOM_STRING[@]} | tr [:space:] '\n' | awk '!a[$0]++'))
	echo "============================Filter========================" > $result_file
	echo "Committer: ${TAG_AUTHOR[@]}" >> $result_file
	echo "Since Date: $TAG_SINCE_DATE" >> $result_file
	echo "Until Date: $TAG_UNTIL_DATE" >> $result_file
	echo "Project: ${TAG_PROJECT[@]}" >> $result_file
	echo "Customer: ${TAG_CUSTOMER[@]}" >> $result_file
	echo "Category: ${TAG_CATEGORY[@]}" >> $result_file
	echo "Feature: ${TAG_FEATURE[@]}" >> $result_file
	echo "Custom String: ${TAG_CUSTOM_STRING[@]}" >> $result_file
	echo "==========================================================" >> $result_file

	dialog \
	--scrollbar \
	--stderr \
	--stdout \
	--title "Git Log Parameter" \
	--textbox $result_file $HEIGHT $WIDTH
}

put_tag_into_parameter() {
	#======================Put Tags into parameter==================
	parameter+=$(echo "--pretty=format:"%h,%cn,%ae,%ad,%s" ")
	parameter+=$(echo "--no-merges ")
	#parameter+=$(echo "--committer @hipad.com ")
	#parameter+=$(echo "--grep Common ")

	for ((i=0; i<${#TAG_AUTHOR[@]}; i++ ));
	do
		if [ "${TAG_AUTHOR[$i]}" != "" ];
		then
			parameter+=$(echo "--committer=${TAG_AUTHOR[$i]} ")
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

	for ((i=0; i<${#TAG_CUSTOM_STRING[@]}; i++ ));
	do
		if [ "${TAG_CUSTOM_STRING[$i]}" != "" ];
		then
			parameter+=$(echo "--grep=${TAG_CUSTOM_STRING[$i]} ")
		else
			:
		fi
	done

	echo "Cmdline: ${parameter[@]}" >> $result_file
}

if [ "$repo_project_num" != "0" ]
then

	#sync or not
	use_local_list=1
	dialog \
	--scrollbar \
	--stderr \
	--stdout \
	--title "$TITLE" \
	--defaultno \
	--yesno  "Sync from google sheet?" 0 0

	exit_status=$?
	case $exit_status in
	$DIALOG_YES)
	clear
	echo "Yes"
	use_local_list=0
	;;
	$DIALOG_NO)
	clear
	echo "No"
	use_local_list=1
	;;
	$DIALOG_ESC)
	clear
	echo "Program aborted." >&2
	exit 1
	;;
	esac
	#get data form google sheet here
	get_data_from_google_sheet

	#git format-patch or not
	git_format_patch=0
	dialog \
	--scrollbar \
	--stderr \
	--stdout \
	--title "$TITLE" \
	--defaultno \
	--yesno  "Git Format-Patch with All searched patch?" 0 0

	exit_status=$?
	case $exit_status in
	$DIALOG_YES)
	clear
	echo "Yes"
	git_format_patch=1
	;;
	$DIALOG_NO)
	clear
	echo "No"
	git_format_patch=0
	;;
	$DIALOG_ESC)
	clear
	echo "Program aborted." >&2
	exit 1
	;;
	esac
	#==============================Filter Start==============================#


	while true; do





		exec 3>&1
		selection=$(dialog \
		--backtitle "Hipad Git Log" \
		--title "Filter Menu" \
		--clear \
		--ok-label "Select" \
		--cancel-label "Repo forall -c git log" \
		--extra-button \
		--extra-label "Git log" \
		--menu "Press ESC to exit the program\nPlease Select:\n" $HEIGHT $WIDTH $CHOICE_HEIGHT \
		"1" "Filter by Committer" \
		"2" "Filter by Since Date" \
		"3" "Filter by Until Date" \
		"4" "Filter by Hipad Commit Project" \
		"5" "Filter by Hipad Commit Customer" \
		"6" "Filter by Hipad Commit Category" \
		"7" "Filter by Hipad Commit Feature" \
		"8" "Filter by Input Custom String" \
		2>&1 1>&3)
		exit_status=$?
		exec 3>&-

		case $exit_status in
		$DIALOG_CANCEL)
		clear
		echo "Start to git log on total .repo"
		break
		;;
		$DIALOG_EXTRA)
		clear
		echo "Start to git log just on local one git"
		has_only_one_git=1
		repo_project_num=1
		print_and_show
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
		select_author "Filter by Committer"
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
		8 )
		input_custom_grep "Filter by Input Custom String"
		;;
		esac
	
		print_and_show
	done




	put_tag_into_parameter
	
	SECONDS=0
	#==============================Progress Start==============================#
	dialog --title "Total Projct $repo_project_num" --gauge "Search each git repository..." 10 100 < <(
	rm $final_file &> /dev/null
	rm $statistics_file &> /dev/null
	for (( i=1; i<=$repo_project_num; i++ ))
	do
		if [ "$has_only_one_git" != "0" ]
		then
			file=$PWD
		else	
			file=$(sed -n "${i},${i}p" $repo_prjoct_path)
			cd "$path/$file"
		fi
		
		#=================Git log===================#
		git_log "${parameter[@]}"

		#add newline to the file
		sed -i -e '$a\' $temp_file

		#count the file size
		actualsize=$(wc -c <$temp_file)
		echo "git log done! file size=$actualsize"

		#replace  '['  with ' ' 
		sed -i -e 's/\[/\ /g' $temp_file

		#replace  ']'  with ','
		sed -i -e 's/]/,/g' $temp_file

		proj=$file
		proj+=","
		#add proj each line , ${proj} have the path '/', so use '#' to instead of
		sed -i -e "s#^#${proj}#" $temp_file

		#and then append to final.csv
		cat $temp_file  >> $final_file
		
		#counting
		count=$(wc -l < $temp_file)
		echo "$i,$proj,$count" >> $statistics_file
		total=$((total+ count))

		# Do git format-patch
		if [ "$git_format_patch" == "1" ]
		then
			for (( j=1; j <= $count; j++ ))
			do
				if [ "$j" == "1" ]
				then
					mkdir -p ${BASEDIR}/$output_folder/$file
				fi
				commit_id=$(sed -n "$j"p $temp_file | cut -d "," -f 2);
				git format-patch $commit_id -1 -o ${BASEDIR}/$output_folder/$file
		                find ${BASEDIR}/$output_folder/$file -name '*.patch' -exec bash -c 'mv "$0" "${0/0001/'"${commit_id}"'}"' {} \; 2>/dev/null 
			done
		fi

		#remove temp file
		rm $temp_file

		
		percentage=$((100*(i)/$repo_project_num))
		#echo "$percentage"
cat <<EOF
XXX
$percentage
Searching [$i th] git repository $path/$file   
Elasped $SECONDS seconds
Found $total commit
XXX
EOF

	done
	)
fi #end of if [ "$repo_project_num" != "0" ]

#add newline to the file
sed -i -e '$a\' $statistics_file &> /dev/null
#add newline to the file
sed -i -e '$a\' $final_file &> /dev/null

total_number=$(wc -l < $final_file) &> /dev/null
#count the file size
#actualsize=$(wc -c <$final_file) &> /dev/null
#echo "final.csv=$actualsize ,Elapsed time: $SECONDS seconds"

echo "Final Result CVS file: $final_file" >> $result_file
echo "Statistics CVS file: $statistics_file" >> $result_file
echo "This File: $result_file" >> $result_file
echo "Elapsed Time: $SECONDS seconds" >> $result_file
echo "Total Commit: $total_number" >> $result_file

dialog \
--scrollbar \
--stderr \
--stdout \
--title "Result" \
--textbox $result_file $((SCREEN_HEIGHT/2+4)) $((SCREEN_WIDTH))

