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



@test "Command: Configure Command generates valid step" {
  # given
  process_config_with tests/inputs/command-configure.yml

  # then
  assert_contains_text 'jfrog rt c --user=${ARTIFACTORY_USER} --url=${ARTIFACTORY_URL} --apikey=${ARTIFACTORY_API_KEY} --interactive=false'
}

@test "Command: Install Command generates valid step" {
  # given
  process_config_with tests/inputs/command-install.yml

  # then
  assert_contains_text 'curl -fL https://getcli.jfrog.io | sh'
}

@test "Job: Upload job includes build-integration" {
  # given
  process_config_with tests/inputs/job-with-spec.yml

  # then
  assert_contains_text 'jfrog rt bp ${CIRCLE_PROJECT_REPONAME} ${CIRCLE_BUILD_NUM}'
}

@test "Job: Upload job's build-integration can be turned off" {
  # given
  process_config_with tests/inputs/job-no-builds.yml

  # then
  assert_text_not_found 'jfrog rt bp ${CIRCLE_PROJECT_REPONAME} ${CIRCLE_BUILD_NUM}'
}


@test "Job: Provided steps are included in config" {
  # given
  process_config_with tests/inputs/job-with-steps.yml

  # then
  assert_jq_match '.jobs | length' 1 #only 1 job
  assert_jq_match '.jobs["Test Upload"].steps[1].run.command' 'mvn install -B'
}


@test "Job: Workspace is attached when path provided" {
  # given
  process_config_with tests/inputs/job-with-workspace.yml

  # then
  assert_contains_text 'attach_workspace:'
  assert_contains_text 'at: target'
}

@test "Job: docker job without steps includes docker build" {
  # given
  process_config_with tests/inputs/job-docker-simple.yml

  # then
  assert_contains_text 'docker build . -t ${DOCKERTAG}'
}

@test "Job: docker job without steps includes docker build(JQ)" {
  # given
  process_config_with tests/inputs/job-docker-simple.yml

  # then
  assert_jq_match '.jobs | length' 1 #only 1 job
  assert_jq_match '.jobs["Docker Publish"].steps | length' 10 #which contains 10 steps
  assert_jq_match '.jobs["Docker Publish"].steps[0]' 'checkout'  #first of which is checkout
  assert_jq_match '.jobs["Docker Publish"].steps[4].run.command' 'docker build . -t ${DOCKERTAG}'  # 5th is our default step
}




# 
#  Full config file tests - use sparingly as maintenance of tests is considerably more than command level checks
#


@test "Job: job with spec generates valid config" {
  # given
  process_config_with tests/inputs/job-with-spec.yml

  # then
  assert_matches_file tests/outputs/job-with-spec.yml
}

@test "Job: job without spec generates valid config" {
  # given
  process_config_with tests/inputs/job-without-spec.yml

  # then
  assert_matches_file tests/outputs/job-without-spec.yml
}



@test "Job: job with steps matches expected configuration" {
  # given
  process_config_with tests/inputs/job-with-steps.yml

  # then
  assert_matches_file tests/outputs/job-with-steps.yml
}


@test "Job: docker job with steps matches expected configuration" {
  # given
  process_config_with tests/inputs/job-docker.yml

  # then
  assert_matches_file tests/outputs/job-docker-steps.yml
}

@test "Job: docker job without steps matches expected configuration" {
  # given
  process_config_with tests/inputs/job-docker-simple.yml

  # then
  assert_matches_file tests/outputs/job-docker.yml
}
