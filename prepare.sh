#! /bin/bash



if [[ $# -eq 0 ]]; then
    echo "Please select a project px"
else
    if [[ $1 == "p1" ]];then
	    echo "Preparing for project 1"
        dtrx submissions_p1.zip
        mv submissions_p1 p1_gradingDir
        ./process_p1_mkdir.sh
        ./process_p1_copy.sh
    elif [[ $1 == "p2" ]]; then
	    echo "Preparing for project 2"
        dtrx submissions_p2.zip
        mv submissions_p2 p2_gradingDir
        ./process_p2_mkdir.sh
        ./process_p2_copy.sh
    fi
fi
