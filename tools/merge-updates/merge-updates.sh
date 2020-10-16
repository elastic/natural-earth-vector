#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace

if [ $# -ne 2 ]
then
    echo "Wrong number of parameters"
    echo "Please pass the folder and the base name of your shapefile to process. Example:"
    echo "merge-updates.sh 10m_cultural ne_10m_admin_1_label_points"
    echo ""
    exit 1
fi

directory=$1
base_file=$2

shape_file="${directory}/${base_file}.shp"

# Check if the file exists
if [ ! -f "${shape_file}" ]
then
    echo "File does not exist!"
    exit 1
fi

echo "Working with $shape_file"

# Look for filter files
filter_files=$(find "${directory}_fixes/updates" -name "${base_file}_new*.filter")
if [[ -z $filter_files ]]; then 
    echo "No filter files found, just copying original file to the output folder"
    mapshaper \
        -i name=original "${shape_file}" \
        -o "${directory}_fixes/merged/${base_file}.shp"
    exit 0
fi

# For each filter
#   aggregate the filter to the filter string
#   include a merge command

count=0
exec_command="mapshaper -i name=original ${shape_file}"
acc_filter=""
includes_command=" "
target="original"

for file in $filter_files; do
    # echo "FILTER FILE: ${file}"
    (( count+=1 ))
    
    # Filter content
    filter=$(cat "${file}")
    # echo "FILTER: ${filter}"

    if [[ -z $acc_filter ]]; then
        acc_filter="${filter}"
    else
        if [[ ! -z ${filter} ]]; then
            acc_filter+=" && ${filter}"
        fi
    fi

    # Include shapefile
    shape_file="$(echo "$file" | cut -f 1 -d '.').shp"

    if [[ -f ${shape_file} ]]; then
        name="incl_${count}"
        includes_command+="-i name=${name} ${shape_file} "
        target+=",${name}"
    fi
done

# Adds the filter to the command
exec_command+=" -filter target=original \"${acc_filter}\""
exec_command+="${includes_command}"
exec_command+=" -merge-layers force target=\"${target}\" "
exec_command+="-o ${directory}_fixes/merged/${base_file}.shp"
echo "==="
echo $exec_command
echo "==="
eval $exec_command
exit 0
