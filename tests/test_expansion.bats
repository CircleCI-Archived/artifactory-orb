#!/usr/bin/env bats

# load custom assertions and functions
load bats_helper


# setup is run beofre each test
function setup {
 
  # These paths are used by the tests and helper methods. They are unique to each test.
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
  assert_jq_match '.jobs | length' 1 #only 1 job
  assert_jq_match '.jobs["build"].steps | length' 4 #which contains 4 steps
  assert_jq_match '.jobs["build"].steps[0]' 'checkout'  #first of which is checkout
  assert_jq_contains '.jobs["build"].steps[3].run.command' 'jfrog rt c --user=${ARTIFACTORY_USER} --url=${ARTIFACTORY_URL} --apikey=${ARTIFACTORY_API_KEY} --interactive=false'  

}

@test "Command: Install Command generates valid step" {
  # given
  process_config_with tests/inputs/command-install.yml

  # then
  
  assert_jq_match '.jobs | length' 1 #only 1 job
  assert_jq_match '.jobs["build"].steps | length' 3 
  assert_jq_match '.jobs["build"].steps[0]' 'checkout'  
  assert_jq_contains '.jobs["build"].steps[2].run.command' 'curl -fL https://getcli.jfrog.io | sh'
}

@test "Job: Upload job includes build-integration" {
  # given
  process_config_with tests/inputs/job-with-spec.yml

  # then
  assert_jq_match '.jobs | length' 1 #only 1 job
  assert_jq_match '.jobs["Test Upload"].steps | length' 7
  assert_jq_match '.jobs["Test Upload"].steps[0]' 'checkout'  
  assert_jq_contains '.jobs["Test Upload"].steps[6].run.command' 'jfrog rt bp ${CIRCLE_PROJECT_REPONAME} ${CIRCLE_BUILD_NUM}'
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
  assert_jq_match '.jobs | length' 1 #only 1 job
  assert_jq_match '.jobs["Test Upload"].steps | length' 8
  assert_jq_match '.jobs["Test Upload"].steps[0]' 'checkout'  
  assert_jq_contains '.jobs["Test Upload"].steps[1].attach_workspace.at' 'target'
}

@test "Job: docker job without steps includes docker build" {
  # given
  process_config_with tests/inputs/job-docker-simple.yml

  # then
  # then
  assert_jq_match '.jobs | length' 1 #only 1 job
  assert_jq_match '.jobs["Docker Publish"].steps | length' 9
  assert_jq_match '.jobs["Docker Publish"].steps[0]' 'checkout'  
  assert_jq_contains '.jobs["Docker Publish"].steps[4].run.command' 'docker build . -t ${DOCKERTAG}'
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
