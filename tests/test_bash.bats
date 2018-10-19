#!/usr/bin/env bats

# load custom assertions and functions
load bats_helper


# setup is run beofre each test
function setup {
  INPUT_PROJECT_CONFIG=${BATS_TMPDIR}/input_config-${BATS_TEST_NUMBER} #`mktemp -t packed_config`
  PROCESSED_PROJECT_CONFIG=${BATS_TMPDIR}/packed_config-${BATS_TEST_NUMBER} #`mktemp -t packed_config`
	echo "#using temp file ${BATS_TMPDIR}/"

  # the name used in example config files.
  INLINE_ORB_NAME="artifactory"
}



@test "Command: Configure complains if required env vars are missing(JQ)" {
  # given
  append_project_configuration tests/inputs/command-configure.yml > $INPUT_PROJECT_CONFIG

  # when
  # run command creates a status and output variable
  circleci config process $INPUT_PROJECT_CONFIG > ${PROCESSED_PROJECT_CONFIG}

  # then
  [ `yq read -j ${PROCESSED_PROJECT_CONFIG} | jq '.jobs | length'` -eq 1 ] #only 1 job
  [ `yq read -j ${PROCESSED_PROJECT_CONFIG} | jq '.jobs["build"].steps | length'` -eq 4 ] #which contains 4 steps
  [[ `yq read -j ${PROCESSED_PROJECT_CONFIG} | jq -r '.jobs["build"].steps[0]'` == "checkout" ]] #first of which is checkout
  yq read -j ${PROCESSED_PROJECT_CONFIG} | jq -r '.jobs["build"].steps[3].run.command' > ${BATS_TMPDIR}/script-${BATS_TEST_NUMBER}.bash
  run bash ${BATS_TMPDIR}/script-${BATS_TEST_NUMBER}.bash
  assert_contains_text 'Artifactory URL and API Key must be set as Environment variables before running this command.'
  assert_contains_text 'ARTIFACTORY_URL'
}

@test "Command: configure command passes when env vars are set (JQ) " {
  # given
  append_project_configuration tests/inputs/command-configure.yml > $INPUT_PROJECT_CONFIG
  circleci config process $INPUT_PROJECT_CONFIG > ${PROCESSED_PROJECT_CONFIG}

  # when
  [ `yq read -j ${PROCESSED_PROJECT_CONFIG} | jq '.jobs | length'` -eq 1 ] #only 1 job
  [ `yq read -j ${PROCESSED_PROJECT_CONFIG} | jq '.jobs["build"].steps | length'` -eq 4 ] #which contains 4 steps
  [[ `yq read -j ${PROCESSED_PROJECT_CONFIG} | jq -r '.jobs["build"].steps[0]'` == "checkout" ]] #first of which is checkout
  yq read -j ${PROCESSED_PROJECT_CONFIG} | jq -r '.jobs["build"].steps[3].run.command' > ${BATS_TMPDIR}/script-${BATS_TEST_NUMBER}.bash
  export ARTIFACTORY_URL=http://example.com
  export ARTIFACTORY_API_KEY=123
  export ARTIFACTORY_USER=USER
  # jfrog is not installed in isolated testing.
  function jfrog { echo "Running config alias executed"; }
  export -f jfrog
  run bash ${BATS_TMPDIR}/script-${BATS_TEST_NUMBER}.bash
  

  # then
  assert_contains_text 'configuring jfrog CLI with target USER@http://example.com'
  assert_contains_text 'Running config alias executed'
}

@test "Command: configure command does not leak password or key (JQ) " {
  # given
  append_project_configuration tests/inputs/command-configure.yml > $INPUT_PROJECT_CONFIG
  circleci config process $INPUT_PROJECT_CONFIG > ${PROCESSED_PROJECT_CONFIG}

  # when
  [ `yq read -j ${PROCESSED_PROJECT_CONFIG} | jq '.jobs | length'` -eq 1 ] #only 1 job
  [ `yq read -j ${PROCESSED_PROJECT_CONFIG} | jq '.jobs["build"].steps | length'` -eq 4 ] #which contains 4 steps
  [[ `yq read -j ${PROCESSED_PROJECT_CONFIG} | jq -r '.jobs["build"].steps[0]'` == "checkout" ]] #first of which is checkout
  yq read -j ${PROCESSED_PROJECT_CONFIG} | jq -r '.jobs["build"].steps[3].run.command' > ${BATS_TMPDIR}/script-${BATS_TEST_NUMBER}.bash
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



