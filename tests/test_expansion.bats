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



@test "Command: Configure Command generates valid step" {
  # given
  print_config tests/inputs/command-configure.yml > $CONFIG_FILE

  # when
  # run command creates a status and output variable
  run circleci config process $CONFIG_FILE

  # then
  assert_contains_text 'jfrog rt c rt-server-1 --url=${ARTIFACTORY_URL} --apikey=${ARTIFACTORY_API_KEY} --interactive=false'
}

@test "Command: Install Command generates valid step" {
  # given
  print_config tests/inputs/command-install.yml > $CONFIG_FILE

  # when
  # run command creates a status and output variable
  run circleci config process $CONFIG_FILE

  # then
  assert_contains_text 'curl -fL https://getcli.jfrog.io | sh'
}


@test "Job: Provided steps are included in config" {
  # given
  print_config tests/inputs/job-with-steps.yml > $CONFIG_FILE

  # when
  # run command creates a status and output variable
  run circleci config process $CONFIG_FILE

  # then
  assert_contains_text '- run: mvn install -B'
}


@test "Job: Workspace is attached when path provided" {
  # given
  print_config tests/inputs/job-with-workspace.yml > $CONFIG_FILE

  # when
  # run command creates a status and output variable
  run circleci config process $CONFIG_FILE

  # then
  assert_contains_text 'attach_workspace:'
  assert_contains_text 'at: target'
}


# 
#  Full config file tests - use sparingly as maintenance of tests is considerably more than command level checks
#


@test "Job: job with spec generates valid config" {
  # given
  print_config tests/inputs/job-with-spec.yml > $CONFIG_FILE

  # when
  # run command creates a status and output variable
  run circleci config process $CONFIG_FILE

  # then
  assert_matches_file tests/outputs/job-with-spec.yml
}

@test "Job: job without spec generates valid config" {
  # given
  print_config tests/inputs/job-without-spec.yml > $CONFIG_FILE

  # when
  # run command creates a status and output variable
  run circleci config process $CONFIG_FILE

  # then
  assert_matches_file tests/outputs/job-without-spec.yml
}



@test "Job: job with steps matches expected configuration" {
  # given
  print_config tests/inputs/job-with-steps.yml > $CONFIG_FILE

  # when
  # run command creates a status and output variable
  run circleci config process $CONFIG_FILE

  # then
  assert_matches_file tests/outputs/job-with-steps.yml
}
