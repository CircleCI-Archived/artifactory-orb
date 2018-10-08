#!/usr/bin/env bats

# load custom assertions and functions
load bats_helper


# setup is run beofre each test
function setup {
	CONFIG_FILE=${BATS_TMPDIR}/packed_config-${BATS_TEST_NUMBER} #`mktemp -t packed_config`
	echo "using temp file $CONFIG_FILE"

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
  print_config tests/inputs/command-install.yml > $CONFIG_FILE

  # when
  # IMPORTANT ** circleci only mounts local directory, so our generated config file must live here.
  circleci config process $CONFIG_FILE > local.yml
  requires_local_build local.yml # copies our local file to remote docker.
  run circleci build -c local.yml
  rm local.yml

  # then
  assert_contains_text 'Checking for existence of CLI'
  assert_contains_text 'Not found, installing latest'
}





@test "Command: configure command prints nice warnings if envars missing " {
  # given
  print_config tests/inputs/command-configure.yml > $CONFIG_FILE

  # when
  # IMPORTANT ** circleci only mounts local directory, so our generated config file must live here.
  circleci config process $CONFIG_FILE > temp-config.yml
  run circleci build -c temp-config.yml

  # then
  assert_contains_text 'Artifactory URL and API Key must be set as Environment variables before running this command.'
  assert_contains_text 'ARTIFACTORY_URL'
}



@test "Command: configure command passes when env vars are set " {
  # given
  print_config tests/inputs/command-configure.yml > $CONFIG_FILE

  # when
  # IMPORTANT ** circleci only mounts local directory, so our generated config file must live here.
  circleci config process $CONFIG_FILE > temp-config.yml

  # and
  run circleci build -c temp-config.yml --env ARTIFACTORY_URL="http://example.com" --env ARTIFACTORY_API_KEY="123" 

  # then
  assert_contains_text 'Success!'
}

