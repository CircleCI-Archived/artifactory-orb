#!/bin/bash

#
# This is duct tape.
#

set -e

TMP_DIR=`mktemp -d orbs.XXXX`

fails=0
tests=0


for file in tests/cases/*.yml; do
	set -e
	tests=$((tests+1))
	echo "Running Test: ${file%.yml}"
	cat .circleci/orbs/artifactory.yml > ${TMP_DIR}/temp-input.yml
	cat $file | sed -ne '/#given/,/#end given/p' | sed '1d;$d'>> ${TMP_DIR}/temp-input.yml
	cat $file | sed -ne '/#then/,/#end then/p' | sed '1d;$d'> ${TMP_DIR}/expected.yml
	circleci config process ${TMP_DIR}/temp-input.yml | sed '/# Original config.yml file:/q'| sed '$d' > ${TMP_DIR}/temp-output.yml
	set +e
	diff -B ${TMP_DIR}/temp-output.yml ${TMP_DIR}/expected.yml 
	if [ $? -eq 0 ];then
		echo -e "\tPass"
	else
		echo -e "\tFail"
		fails=$((fails+1))
	fi
done
echo "Ran $tests tests with $fails failures"
exit $fails