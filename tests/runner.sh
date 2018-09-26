#!/bin/bash

#
# This is duct tape.
#

set -e

USAGE='\n
USAGE:\n
runner.sh config create-inline orbname filename - merge all orbs in src/ to file\n
runner.sh config import-dev namespace orbname filename - declare dev orb from CIRCLE_BRANCH\n
runner.sh test_against filename - use filename as "orbs" section against all test workflows\n


'



function assemble_inline {
	ORB=$1
	OUTPUT=$2
	echo "version: 2.1" > $OUTPUT
	echo "orbs:" >> $OUTPUT
	echo "  $ORB :" >> $OUTPUT
	circleci config pack src | sed -e 's/^/    /'>> $OUTPUT
}



function assemble_external {
	NAMESPACE=$1
	ORB=$2
	OUTPUT=$3
	LABEL=${4-$CIRCLE_BRANCH}
	echo "version: 2.1" > $OUTPUT
	echo "orbs:" >> $OUTPUT
	echo "  $ORB: $NAMESPACE/$ORB@dev:${LABEL}" >> $OUTPUT 
}


function run_tests {
	INLINE=$1
	MY_TMP_DIR=`mktemp -d -t orbs.XXXX`

	fails=0
	tests=0

	 for file in tests/cases/*.yml; do
		set -e
		tests=$((tests+1))
		echo "Running Test: ${file%.yml}"
		cat ${INLINE} > ${MY_TMP_DIR}/temp-input.yml
		cat $file | sed -ne '/#given/,/#end given/p' | sed '1d;$d'>> ${MY_TMP_DIR}/temp-input.yml
		cat $file | sed -ne '/#then/,/#end then/p' | sed '1d;$d'> ${MY_TMP_DIR}/expected.yml
		circleci config process ${MY_TMP_DIR}/temp-input.yml  2>${MY_TMP_DIR}/temp-error.txt | sed '/# Original config.yml file:/q'| sed '$d' > ${MY_TMP_DIR}/temp-output.yml 
		set +e
		if [ -s ${MY_TMP_DIR}/temp-error.txt ];then
			# processing generated error, check for match
			ACTUAL=${MY_TMP_DIR}/temp-error.txt
		else
			# no error, check generated config
			ACTUAL=${MY_TMP_DIR}/temp-output.yml
		fi

		diff -B $ACTUAL ${MY_TMP_DIR}/expected.yml 
		if [ $? -eq 0 ];then
			echo -e "\tPass"
		else
			echo -e "\tFail"
			fails=$((fails+1))
		fi

		rm -R ${MY_TMP_DIR}/*
	done
	echo "Ran $tests tests with $fails failures"
	if [ $fails -gt 0 ];then
		exit 1
	fi
}

case "$1" in
	config)
		shift
		case "$1" in
			"create-inline")
				assemble_inline $2 $3
			;;
			"import-dev")				
				assemble_external $2 $3 $4
			;;
		esac
	;;
	test_against)
		run_tests $2
	;;
	*)
		echo -e $USAGE
		exit 2
	;;
esac