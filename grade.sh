#! /usr/bin/env bash

set -e

printUsage()
{
    echo "Usage: ./grade.sh -p n -d dir"
    echo "  n:   project number starting from 1 to 6"
    echo "  dir: working dir"
}

OPTIND=1

pn=0
WD=""
while getopts "p:d:h" opt; do
    case "$opt" in
        h)
            printUsage
            exit 0
            ;;
        p)
            pn=$OPTARG
            ;;
        d)
            WD=$OPTARG
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

##
## Check project number
##
if [[ $pn -lt 1 ]] || [[ $pn -gt 6 ]]; then
    echo "project number must be in range [1,6]"
    printUsage
    exit 0
fi

##
## check working dir
##
if [[ $WD == "" ]]; then
    echo "Must specify a working dir"
    printUsage
    exit 0
fi

##
## Now everything is within range, run the autograder
##
if [[ $pn -lt 3 ]]; then
    ./scripts/lexer_autograder.sh p$pn $WD
elif [[ $pn -lt 6 ]]; then
    ./scripts/parser_autograder.sh p$pn $WD
else
    ./scripts/codegen_autograder.sh $WD
fi


