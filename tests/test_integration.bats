#!/usr/bin/env bats

# load custom assertions and functions
load bats_helper


# setup is run beofre each test
function setup {
  INPUT_PROJECT_CONFIG=${BATS_TMPDIR}/input_config-${BATS_TEST_NUMBER} #`mktemp -t packed_config`

  # To make config avaulable for docker, it must in in project dir, which ismounted as volume
  PACKED_PROJECT_CONFIG=IT-config-${BATS_TEST_NUMBER} #`mktemp -t packed_config`
  echo "#using temp file $PACKED_PROJECT_CONFIG"

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
  append_project_configuration tests/inputs/command-install.yml > $INPUT_PROJECT_CONFIG
  circleci config process $INPUT_PROJECT_CONFIG > ${PACKED_PROJECT_CONFIG}

  # when
  # IMPORTANT ** circleci only mounts local directory, so our generated config file must live here.
  run circleci build -c ${PACKED_PROJECT_CONFIG}
  rm ${PACKED_PROJECT_CONFIG}

  # then
  assert_contains_text 'Checking for existence of CLI'
  assert_contains_text 'Not found, installing latest'
}

