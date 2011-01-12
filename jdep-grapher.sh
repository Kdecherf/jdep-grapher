#!/bin/bash

GRAPH=$1
DIR=$2
EXCLUDE=$3 # Puts an expression for grep to exclude some nodes

if [[ -z $GRAPH || -z $DIR ]]; then
	echo "Usage: ./jdep-grapher.sh imagefilename.png foldertoparse [excludes]"
	exit 0
fi

# List files
echo "Listing files to parse..."
FILES=`mktemp`
find $DIR -type f -name "*.java" > $FILES

# Grep
echo "Registering imports and packages..."
GREP=`mktemp`
grep -E "^package|^import" $(< $FILES) | awk -F':' '{print $2}' > $GREP

# Compute links
echo "Computing dependencies..."

COMPUTE=`mktemp`

CPKG=""

while read type name
do
	name=`echo $name | tr -d ";"`
	pkg=`echo $name | tr -d "."`
	if [[ "$type" == "package" ]]; then
		echo "$pkg [label=\"$name\", style = filled, shape = box];"
		CPKG=$pkg
	else
		ALL=`echo $pkg | grep "\*" | wc -l`
		SUP=""
		LNK=""
		if [[ $ALL -eq 1 ]]; then
			pkg=`echo $pkg | sed s/"*"/"allpkg"/`
			SUP=", color=red, style = filled"
                        LNK=" [color=red]"
		fi
		echo "$pkg [label=\"$name\"$SUP];"
		echo "$CPKG -> $pkg $LNK;"
	fi
done < $GREP | sort -u > $COMPUTE

rm $FILES $GREP

TMPDOT=`mktemp`

	if [[ ! -z $EXCLUDE  ]]; then
		echo "Excluding some links..."
		grep -vE "$EXCLUDE" $COMPUTE > $TMPDOT
	else
		rm $TMPDOT
		TMPDOT=$COMPUTE
	fi

TMPDOT2=`mktemp`
echo "Cleaning alone nodes..."
while read rpkg rop rchild
do
	CT=`grep -E "$rpkg( |;)" $TMPDOT | wc -l`
	if [[ $CT -gt 1 ]]; then
		echo $rpkg $rop $rchild >> $TMPDOT2
	fi
done < $TMPDOT

DOT=`mktemp`

echo "Generating .dot file..."
echo "digraph G {" > $DOT
cat $TMPDOT2 >> $DOT
echo "}" >> $DOT

echo "Generating graph..."
fdp -Tpng < $DOT > $GRAPH

# Cleaning tmp files
rm $COMPUTE $TMPDOT $TMPDOT2 $DOT
