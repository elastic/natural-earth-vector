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
# Check if there is a .filter file
if [ -f "${shape_file}.filter" ]
then
    # Filter content
    filter=$(cat "${shape_file}.filter")
    echo "Filter to apply to original dataset:"
    echo "${filter}"

    # Initial part of the command
    exec_command="mapshaper -i name=original ${shape_file} -filter target=original \"${filter}\" "

    target="original"

    # Search for _new*.shp files to include
    count=0
    while IFS= read -r -d '' file
    do
        (( count+=1 ))
        echo "Including for processing: ${file}"
        exec_command="${exec_command} -i name=new_${count} \"$file\""
        target="${target},new_${count}"
    done <   <(find . -name "${base_file}_new*.shp" -print0)

    exec_command="${exec_command} -merge-layers target=\"${target}\" -o ${directory}/${base_file}_mod.shp"

    eval "$exec_command"
else
    # Generate the new file just from the original
    echo "No filtering file found"
    mapshaper \
        -i name=original "${shape_file}" \
        -o "${directory}/${base_file}_mod.shp"
fi
