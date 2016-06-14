#!/bin/bash

BASEDIR=$(dirname $0)

trap "echo clean temp files;rm ${BASEDIR}/temp.csv;exit 1" SIGTERM SIGINT SIGHUP
git_config=".git/config"
keyword="projectname"
candidate_config="${BASEDIR}/${git_config}"

if [ ! -e "${candidate_config}" ]; then
    echo "Not a valid git repository, exit!"
    return
fi

#get projectname from each git repository
proj=`grep ${keyword} ${candidate_config} | sed "s/\t${keyword} = \(.\)/\1/"`;echo "proj=$proj"

#====================================================================
# %h short hash
# %ae author email
# %ad author date
# %s  summary
#====================================================================
git log --pretty=format:"%h,%ae,%ad,%s" > ${BASEDIR}/temp.csv

#count the file size
actualsize=$(wc -c <${BASEDIR}/temp.csv);echo "git log done! file size=$actualsize"

#replace  '['  with ' ' 
sed -i -e 's/\[/\ /g' ${BASEDIR}/temp.csv

#replace  ']'  with ','
sed -i -e 's/]/,/g' ${BASEDIR}/temp.csv


#counting
count=$(wc -l <${BASEDIR}/temp.csv );echo "$proj,$count,$actualsize" >> ${BASEDIR}/count.csv

proj+=","
#add proj each line , ${proj} have the path '/', so use '#' to instead of
sed -i -e "s#^#${proj}#" ${BASEDIR}/temp.csv 



#and then append to final.csv
cat ${BASEDIR}/temp.csv  >> ${BASEDIR}/final.csv

#remove temp file
rm ${BASEDIR}/temp.csv

#count the file size
actualsize=$(wc -c <${BASEDIR}/final.csv);echo "final.csv=$actualsize"

