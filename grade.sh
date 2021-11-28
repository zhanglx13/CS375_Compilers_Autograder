#! /usr/bin/env bash

set -e

printUsage()
{
    echo "Usage: ./grade.sh -p n -d dir [-t u]"
    echo "  n:   project number starting from 1 to 6"
    echo "  dir: working dir"
    echo "  u:   unit test number"
}

OPTIND=1

pn=0
WD=""
singleTest=0
while getopts "p:d:ht:" opt; do
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
        t)
            tn=$OPTARG
            singleTest=1
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
    if [[ $singleTest -eq 1 ]]; then
        if [[ $tn -lt 0 ]] || [[ $tn -gt 30 ]]; then
            echo "Unit test number out of range [0,30]"
            exit 0
        fi
        ./scripts/codegen_autograder.sh $WD 0 $tn
    else
        ./scripts/codegen_autograder.sh $WD
    fi
fi


