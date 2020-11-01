#! /usr/bin/env bash

##
## Compare file $1 and $2.
## If they are the same, do nothing.
## If not, print message in $3 and set pass=0
##
## $1: target filename
## $2: output filename
## $3: error message
exactMatch()
{
    DIFF=$(diff $1 $2)
    if [ "$DIFF" != "" ]
    then
        echo $3
        ##
        ## Add 4 spaces to indent the output of diff
        ##
        diff $1 $2 | $SED 's/^/    /'
        pass=0
    fi
}

##
## Compare two values
## If they are the same, do nothing.
## If not, print message in $3 and set pass=0
##
## $1: val1
## $2: val2
## $3: error message
exactMatchVal()
{
    if [[ "$1" != "$2" ]]; then
        echo $3
        pass=0
    fi
}

##
## Compare the CONST entries in $target and $output
## CONST entries must be exactly matched except column 1
##
compareCONST()
{
    $AWK  '$3 == "CONST" {print $2,$3,$4,$5,$6,$7}' $target > const_target.tmp
    $AWK  '$3 == "CONST" {print $2,$3,$4,$5,$6,$7}' $output > const_output.tmp
    ## After sorting, different orders of CONST can also match
    sort const_target.tmp > const_target_sorted.tmp
    sort const_output.tmp > const_output_sorted.tmp
    exactMatch const_target_sorted.tmp const_output_sorted.tmp "Incorrect CONST"
}

##
## Compare one single TYPE entry in $target and $output
## TYPE entries must be exactly matched except column 1 and 5
##
## $1: name (such as color)
## $2: number of lines after the TYPE line that denote the underlying type
##
compareTYPE()
{
    ## Get TYPE line
    $AWK -v name="^$1$" '$2 ~ name{print $2,$3,$4,$6,$7,$8,$9,$10,$11}' $target > $1_target.tmp
    $AWK -v name="^$1$" '$2 ~ name{print $2,$3,$4,$6,$7,$8,$9,$10,$11}' $output > $1_output.tmp
    ## Check if type exists
    if [ ! -s "$1_output.tmp" ]
    then
        echo "Incorrect TYPE $1 (missing)"
        pass=0
    else
        ## Get underlying type of the TYPE
        ## Check this https://stackoverflow.com/a/17914105/4080767
        $AWK -v name="^$1$" -v line="$2" 'c&&c--;$2 ~ name{c=line}' $target > type_target.tmp
        $AWK -v name="^$1$" -v line="$2" 'c&&c--;$2 ~ name{c=line}' $output > type_output.tmp
        cat type_target.tmp >> $1_target.tmp
        cat type_output.tmp >> $1_output.tmp
        exactMatch $1_target.tmp $1_output.tmp "Incorrect TYPE $1"
    fi
}

##
## Check $output to see if there are any TYPE that is not defined in $target
##
checkExtraTypes()
{
    $AWK '$3 == "TYPE" {print $0}' $output > type_lines.tmp
    while read -r typeline
    do
        tname=$(echo $typeline | $AWK '{print $2}')
        if [ -z ${types[$tname]}  ]
        then
            echo "Incorrect TYPE $tname (should not be here)"
            pass=0
        fi
    done < type_lines.tmp
}

##
## Process the $target to get each TYPE name the number of lines
## used to denote the underlying type
## The result is saved is array types[name]=lineNo
##
processTYPE()
{
    declare -A types
    ## Obtain the TYPE block
    ## This block starts with the first TYPE line and end with a VAR line.
    ## It might include some CONST lines
    $SED -n '/TYPE/,/VAR/p;/VAR/q' $target > type_block.tmp
    count=0
    while read -r line
    do
        ## Found TYPE line
        c3=$(echo $line | $AWK '{print $3}')
        if [ "$c3" == "TYPE" ]
        then
            if [[ $count -ne 0 ]]; then
                types[$name]=$count
            fi
            name=$(echo $line | $AWK '{print $2}')
            count=0
        elif [ "$c3" == "CONST" ] || [ "$c3" == "VAR" ]
        then
            if [[ $count -ne 0 ]];then
                types[$name]=$count
                count=0
            fi
        else
            ((count++))
        fi
    done < type_block.tmp
    ## Loop through the associative array
    for name in "${!types[@]}"
    do
        compareTYPE $name ${types[$name]}
    done
    checkExtraTypes
}


##
## Try to find TYPE entry in $target of the same typ value as specified as $1
## $1: typ value
##
findType()
{
    $AWK -v typ="^$1$" '$3 == "TYPE" && $5 ~ typ {print $2}' $target
}

##
## Compare single VAR entry in $target and $output
##
## $1: VAR name
## $2: number of lines for type
##
## This function checks
## 1. name (c2)
## 2. basicdt (c4)
## 3. typ (c6)
## 4. size (c10)
compareSingleVAR()
{
    ## Check size and underlying type
    sz=$($AWK -v name="^$1$" '$2 ~ name{print $10}' $target)
    mysz=$($AWK -v name="^$1$" '$2 ~ name{print $10}' $output)
    if [ -z $mysz ]
    then
        echo "Incorrect VAR $1 (missing)"
        pass=0
    else
        exactMatchVal $sz $mysz "Incorrect VAR $1 (size < $sz | > $mysz)"
        if [[ ${varlines[$1]} -ne 0 ]]; then
            ## Get underlying type of the VAR
            ## Check this https://stackoverflow.com/a/17914105/4080767
            $AWK -v name="^$1$" -v line="$2" 'c&&c--;$2 ~ name{c=line}' $target > var_target.tmp
            $AWK -v name="^$1$" -v line="$2" 'c&&c--;$2 ~ name{c=line}' $output > var_output.tmp
            exactMatch var_target.tmp var_output.tmp "Incorrect VAR $1 (type full)"
        fi
        ## Check basicdt
        if [[ ${varalign[$1]} -eq 4 ]] || [[ ${varalign[$1]} -eq 8 ]]; then
            dt=$($AWK -v name="^$1$" '$2 ~ name{print $4}' $target)
            mydt=$($AWK -v name="^$1$" '$2 ~ name{print $4}' $output)
            exactMatchVal $dt $mydt "Incorrect VAR $1 (basicdt < $dt | > $mydt)"
        fi
        ## Check typ
        ##
        mytyp=$($AWK -v name="^$1$" '$2 ~ name{print $6}' $output)
        if [[ ${var2type[$1]} ]];then
            ## When the var's type is defined in the TYPE block, check if their typ match
            typ=$($AWK -v name="^${var2type[$1]}$" '$2 ~ name{print $5}' $output)
            exactMatchVal $mytyp $typ "Incorrect VAR $1 (typ, which should match typ of ${var2type[$1]})"
        elif [[ "$mytyp" == "integer" ]] || [[ "$mytyp" == "real" ]]; then
            ## When the var's typ is a basic dt, check if it matches the typ in the $target
            typ=$($AWK -v name="^$1$" '$2 ~ name{print $6}' $target)
            exactMatchVal $mytyp $typ "Incorrect VAR $1 (typ)"
            ## For other cases, such as the type of the var is constructed in the VAR block,
            ## do nothing
        fi
    fi
}

##
## Check the offset of each VAR according to each VAR's size and alignment
##

checkVAROffset()
{
    ## Extract VAR block, which only contains VAR lines
    $AWK '$3 == "VAR" {print $0}' $output > var_lines.tmp
    offset=0
    nextaddr=0
    while read -r varline
    do
        size=$(echo $varline | $AWK '{print $10}')
        varname=$(echo $varline | $AWK '{print $2}')
        if [[ ${varalign[$varname]} ]]; then
            align=${varalign[$varname]}
            ((offset = nextaddr + align - 1))
            ((offset = offset / align * align))
            ((nextaddr = offset + size))
            #echo "$align $offset"
            myoffset=$(echo $varline | $AWK '{print $12}')
            exactMatchVal $myoffset $offset "Incorrect VAR $varname (offset < $offset | > $myoffset)"
        else
            ## variable should be in the VAR block
            echo "Incorrect VAR $varname (should not be here)"
            pass=0
        fi
    done < var_lines.tmp
}

##
## Process the $target to get information for VAR entries
##
processVAR()
{
    ## var2type stores the user-defined type name for the variable
    declare -A var2type
    ## varalign stores the alignment requirement for each variable
    declare -A varalign
    ## varlines stores the number of lines following the var line that
    ## denotes the type of the variable
    declare -A varlines
    count=0
    ## Obtain all VAR entries
    $AWK '/VAR/,0' $target > VAR_block.tmp
    vname=""
    while read -r line
    do
        c3=$(echo $line | $AWK '{print $3}')
        if [ "$c3" == "VAR" ]
        then
            ## For the VAR line
            if [ "$vname" != "" ]
            then
                ## We do not set vname and its count for the first VAR line
                varlines[$vname]=$count
                count=0
            fi
            ## Get var name and its typ
            vname=$(echo $line | $AWK '{print $2}')
            vtype=$(echo $line | $AWK '{print $6}')

            #echo "Found $vname ==> $vtype"
            ##
            ## The alignment of each var can be used to determine whether the
            ## *basicdt* field of the entry needs to be exactly matched with
            ## the sample.
            ## Alignment of 4 or 8 ==> basicdt should match
            ##
            ## The var2type of each variable stores the TYPE name if the var's type
            ## is user-defined, which can be found in the type block
            ## ==> the typ field should match the typ field of the TYPE.
            ## If var2type is not defined, which means the type is not user-defined
            ## ==> typ field does not matter.
            ##
            if [ "$vtype" == "integer" ] || [ "$vtype" == "real" ]
            then
                ## If the variable has a basic datatype (real or integer),
                ## set its alignment to its size
                size=$(echo $line | $AWK '{print $10}')
                varalign[$vname]=$size
                #echo "VAR with basic type: $vname ${var2type[$vname]} ${varalign[$vname]}"
            else
                ## If the variable has a pointer type or user defined type,
                ## If it is a pointer type, set its alignment to 8.
                ## If it is a RECORD or ARRAY, set its alignment to 16.

                ## Try to find the typ in the TYPE block and assign to the var's var2type
                typename=$(findType $vtype)
                var2type[$vname]=$typename
                ## get the line after the var line
                typeline=$($AWK -v name="^$vname$" 'f{print;f=0} $2 ~ name{f=1}' VAR_block.tmp)
                ## >> check a string with regex
                if [[ $typeline =~ ^\(RECORD ]]; then
                    varalign[$vname]=16
                    #echo "  RECORD  ==> $typeline ==> $typename"
                elif [[ $typeline =~ ^\(ARRAY ]]; then
                    #echo "  ARRAY   ==> $typeline ==> $typename"
                    varalign[$vname]=16
                elif [[ $typeline =~ ^\(\^ ]]; then
                    #echo "  POINTER ==> $typeline ==> $typename"
                    varalign[$vname]=8
                elif [[ $typeline =~ ^\ *[0-9]+\ *\.\.\ *[0-9]+ ]]; then
                    #echo "Subrange ==> $typeline"
                    varalign[$vname]=4
                else
                    echo "  !! Unrecoganized type !!"
                fi
            fi
        else
            ## If the line is not a VAR line, simply increment the counter
            ((count++))
        fi
    done < VAR_block.tmp
    ## Do not forget to set the last VAR
    varlines[$vname]=$count

    ## Check for correctness
    for var in "${!varlines[@]}"
    do
        # echo "Have $var ==> ${varlines[$var]} lines"
        # echo "     ==> align: ${varalign[$var]}"
        # if [[ ${var2type[$var]} ]];then
        #     echo "     ==> TYPE: ${var2type[$var]}"
        # else
        #     echo "     ==> BASIC TYPE"
        # fi
        # echo ""
        compareSingleVAR $var ${varlines[$var]}
    done
    checkVAROffset
}
