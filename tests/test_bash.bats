#!/usr/bin/env bats

# load custom assertions and functions
load bats_helper


###########
#
#  These tests print the steps to local files to execute with bash. It is important to only use on steps that 
#   will not modify the developers local computer (i.e. trying to install tools)
#   For testing any scripts that modify the OS, use test_integrations.bats and `circleci build` to isolate in ocntainers
#
##########




# setup is run beofre each test
function setup {
  INPUT_PROJECT_CONFIG=${BATS_TMPDIR}/input_config-${BATS_TEST_NUMBER}
  PROCESSED_PROJECT_CONFIG=${BATS_TMPDIR}/packed_config-${BATS_TEST_NUMBER} 
  JSON_PROJECT_CONFIG=${BATS_TMPDIR}/json_config-${BATS_TEST_NUMBER} 
	echo "#using temp file ${BATS_TMPDIR}/"

  # the name used in example config files.
  INLINE_ORB_NAME="artifactory"
}



@test "Command: Configure complains if required env vars are missing(JQ)" {
  # given
  process_config_with tests/inputs/command-configure.yml 

  # then
  assert_jq_match '.jobs | length' '1' #only 1 job
  assert_jq_match '.jobs["build"].steps | length' 4 #which contains 4 steps
  assert_jq_match '.jobs["build"].steps[0]' "checkout" #first of which is checkout
  jq -r '.jobs["build"].steps[3].run.command' ${JSON_PROJECT_CONFIG} > ${BATS_TMPDIR}/script-${BATS_TEST_NUMBER}.bash
  
  # "run" captures output into $output that is used by assertion methods
  run bash ${BATS_TMPDIR}/script-${BATS_TEST_NUMBER}.bash
  

  assert_contains_text 'Artifactory URL and API Key must be set as Environment variables before running this command.'
  assert_contains_text 'ARTIFACTORY_URL'
}

@test "Command: configure command passes when env vars are set (JQ) " {
  # given
  process_config_with tests/inputs/command-configure.yml
  # when
  assert_jq_match '.jobs | length' 1 #only 1 job
  assert_jq_match '.jobs["build"].steps | length' 4 #which contains 4 steps
  assert_jq_match '.jobs["build"].steps[0]' "checkout" #first of which is checkout
  jq -r '.jobs["build"].steps[3].run.command' ${JSON_PROJECT_CONFIG} > ${BATS_TMPDIR}/script-${BATS_TEST_NUMBER}.bash
  
  export ARTIFACTORY_URL=http://example.com
  export ARTIFACTORY_API_KEY=123
  export ARTIFACTORY_USER=USER
  
  # jfrog is not installed in isolated testing, so we mock it
  function jfrog { echo "Running config alias executed"; }
  export -f jfrog
  run bash ${BATS_TMPDIR}/script-${BATS_TEST_NUMBER}.bash
  
  # then
  assert_contains_text 'configuring jfrog CLI with target USER@http://example.com'
  assert_contains_text 'Running config alias executed'
}

@test "Command: configure command does not leak password or key (JQ) " {
  # given
   process_config_with tests/inputs/command-configure.yml

  # when
  assert_jq_match '.jobs | length' 1 #only 1 job
  assert_jq_match '.jobs["build"].steps | length' 4 #which contains 4 steps
  assert_jq_match '.jobs["build"].steps[0]' "checkout"  #first of which is checkout
  jq -r '.jobs["build"].steps[3].run.command' ${JSON_PROJECT_CONFIG} > ${BATS_TMPDIR}/script-${BATS_TEST_NUMBER}.bash
  export ARTIFACTORY_URL=http://example.com
  export ARTIFACTORY_API_KEY=SHOLDNOTBEPRINTED
  export ARTIFACTORY_USER=USER
  function jfrog { echo "Running config alias executed"; }
  export -f jfrog
  run bash ${BATS_TMPDIR}/script-${BATS_TEST_NUMBER}.bash
  

  # then
  assert_contains_text 'configuring jfrog CLI with target USER@http://example.com'
  assert_text_not_found $ARTIFACTORY_API_KEY
}



