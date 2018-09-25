#!/bin/bash

#
# This is duct tape.
#

set -e




function main {
	assemble_inline

}

function assemble_inline {
	NAMESPACE=$1
	ORB=$2
	OUTPUT=$3
	YML_DIR=`mktemp -d -t yml.XXXX`
	ALL_FILES=()
	for filename in src/commands/*.yml; do
		command=$(basename ${filename})
		echo $command
		command="${command%.*}"
		echo "converting $command into nested format"
		echo '{"commands":{"'$command'":'$(yq r -j $filename)'}}' | yq r - > $YML_DIR/${command}.yml
		ALL_FILES+=($YML_DIR/${command}.yml)
	done
	echo "Merging ${ALL_FILES[*]}"
	yq m ${ALL_FILES[*]}
}


function remove_files_in {
	rm $1/temp-*
}


function run_tests {
	TMP_DIR=`mktemp -d -t orbs.XXXX`

	fails=0
	tests=0

	 for file in tests/cases/*.yml; do
		set -e
		tests=$((tests+1))
		echo "Running Test: ${file%.yml}"
		cat src/\@orb.yml > ${TMP_DIR}/temp-input.yml
		cat $file | sed -ne '/#given/,/#end given/p' | sed '1d;$d'>> ${TMP_DIR}/temp-input.yml
		cat $file | sed -ne '/#then/,/#end then/p' | sed '1d;$d'> ${TMP_DIR}/expected.yml
		circleci config process ${TMP_DIR}/temp-input.yml  2>${TMP_DIR}/temp-error.txt | sed '/# Original config.yml file:/q'| sed '$d' > ${TMP_DIR}/temp-output.yml 
		set +e
		if [ -s ${TMP_DIR}/temp-error.txt ];then
			# processing generated error, check for match
			ACTUAL=${TMP_DIR}/temp-error.txt
		else
			# no error, check generated config
			ACTUAL=${TMP_DIR}/temp-output.yml
		fi

		diff -B $ACTUAL ${TMP_DIR}/expected.yml 
		if [ $? -eq 0 ];then
			echo -e "\tPass"
		else
			echo -e "\tFail"
			fails=$((fails+1))
		fi

		remove_files_in ${TMP_DIR}
	done
	echo "Ran $tests tests with $fails failures"
	if [ $fails -gt 0 ];then
		exit 1
	fi
}


main
