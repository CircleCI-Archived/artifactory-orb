#!/usr/bin/env bats

# load custom assertions and functions
load bats_helper


# setup is run beofre each test
function setup {
  INPUT_PROJECT_CONFIG=${BATS_TMPDIR}/input_config-${BATS_TEST_NUMBER}
  PROCESSED_PROJECT_CONFIG=${BATS_TMPDIR}/packed_config-${BATS_TEST_NUMBER} 
  JSON_PROJECT_CONFIG=${BATS_TMPDIR}/json_config-${BATS_TEST_NUMBER} 
  echo "#using temp file ${BATS_TMPDIR}/"

  # the name used in example config files.
  INLINE_ORB_NAME="artifactory"
}



#
#  For COMMANDS we can actually run local builds as they all use `build` as the job name.
#
#  These take a long time though since they download and run containers.
#



@test "Command: install logic skips if aleady installed" {
  # given
  process_config_with tests/inputs/command-install.yml

  # when
  # IMPORTANT ** circleci only mounts local directory, so our generated config file must live here.
  cp ${PROCESSED_PROJECT_CONFIG} local.yml
  run circleci build -c local.yml
  rm local.yml

  # then
  assert_contains_text 'Checking for existence of CLI'
  assert_contains_text 'Not found, installing latest'
}

