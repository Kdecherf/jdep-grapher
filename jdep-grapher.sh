#!/bin/bash

GRAPH="graph.png"
DIR="mysrcfolder"
EXCLUDE="" # Puts an expression for grep to exclude some nodes

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
		if [[ $ALL -eq 1 ]]; then
			pkg=`echo $pkg | sed s/"*"/"allpkg"/`
		fi
		echo "$pkg [label=\"$name\"];"
		echo "$CPKG -> $pkg;"
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
