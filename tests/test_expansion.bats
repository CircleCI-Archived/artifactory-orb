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



@test "Command: Configure Command generates valid step" {
  # given
  append_project_configuration tests/inputs/command-configure.yml > $INPUT_PROJECT_CONFIG

  # when
  # run command creates a status and output variable
  run circleci config process $INPUT_PROJECT_CONFIG

  # then
  assert_contains_text 'jfrog rt c --user=${ARTIFACTORY_USER} --url=${ARTIFACTORY_URL} --apikey=${ARTIFACTORY_API_KEY} --interactive=false'
}

@test "Command: Install Command generates valid step" {
  # given
  append_project_configuration tests/inputs/command-install.yml > $INPUT_PROJECT_CONFIG

  # when
  # run command creates a status and output variable
  run circleci config process $INPUT_PROJECT_CONFIG

  # then
  assert_contains_text 'curl -fL https://getcli.jfrog.io | sh'
}

#@test "Job: Build-name can be overriden" {
#  # given
#  cat > ${INPUT_PROJECT_CONFIG} <<EOL
#workflows:
#  version: 2
#  test-orb:
#    jobs:
#      - artifactory/upload:
#          name: Test Upload
#          source: test/artifact.jar
#          target: repo/path
#          build-name: "mycustombuildname"
#
#EOL
#
#  append_project_configuration ${INPUT_PROJECT_CONFIG} > $INPUT_PROJECT_CONFIG
#
#  # when
#  # run command creates a status and output variable
#  run circleci config process $INPUT_PROJECT_CONFIG
#
#  # then
#  assert_contains_text 'jfrog rt bp mycustombuildname ${CIRCLE_BUILD_NUM}'        
#  assert_contains_text 'jfrog rt upload test/artifact.jar repo/path --build-name=mycustombuildname'        
#  assert_contains_text 'jfrog rt bag mycustombuildname ${CIRCLE_BUILD_NUM}'        
#  assert_contains_text 'jfrog rt bce mycustombuildname ${CIRCLE_BUILD_NUM}'  
#}

@test "Job: Upload job includes build-integration" {
  # given
  append_project_configuration tests/inputs/job-with-spec.yml > $INPUT_PROJECT_CONFIG

  # when
  # run command creates a status and output variable
  run circleci config process $INPUT_PROJECT_CONFIG

  # then
  assert_contains_text 'jfrog rt bp ${CIRCLE_PROJECT_REPONAME} ${CIRCLE_BUILD_NUM}'
}

@test "Job: Upload job's build-integration can be turned off" {
  # given
  append_project_configuration tests/inputs/job-no-builds.yml > $INPUT_PROJECT_CONFIG

  # when
  # run command creates a status and output variable
  run circleci config process $INPUT_PROJECT_CONFIG

  # then
  assert_text_not_found 'jfrog rt bp ${CIRCLE_PROJECT_REPONAME} ${CIRCLE_BUILD_NUM}'
}


@test "Job: Provided steps are included in config" {
  # given
  append_project_configuration tests/inputs/job-with-steps.yml > $INPUT_PROJECT_CONFIG

  # when
  # run command creates a status and output variable
  run circleci config process $INPUT_PROJECT_CONFIG

  # then
  assert_contains_text '- run: mvn install -B'
}


@test "Job: Workspace is attached when path provided" {
  # given
  append_project_configuration tests/inputs/job-with-workspace.yml > $INPUT_PROJECT_CONFIG

  # when
  # run command creates a status and output variable
  run circleci config process $INPUT_PROJECT_CONFIG

  # then
  assert_contains_text 'attach_workspace:'
  assert_contains_text 'at: target'
}

@test "Job: docker job without steps includes docker build" {
  # given
  append_project_configuration tests/inputs/job-docker-simple.yml > $INPUT_PROJECT_CONFIG

  # when
  # run command creates a status and output variable
  run circleci config process $INPUT_PROJECT_CONFIG

  # then
  assert_contains_text 'docker build . -t ${DOCKERTAG}'
}

@test "Job: docker job without steps includes docker build(JQ)" {
  # given
  append_project_configuration tests/inputs/job-docker-simple.yml > $INPUT_PROJECT_CONFIG

  # when
  # run command creates a status and output variable
  circleci config process $INPUT_PROJECT_CONFIG > ${PROCESSED_PROJECT_CONFIG}

  # then
  [ `yq read -j ${PROCESSED_PROJECT_CONFIG} | jq '.jobs | length'` -eq 1 ] #only 1 job
  [ `yq read -j ${PROCESSED_PROJECT_CONFIG} | jq '.jobs["Docker Publish"].steps | length'` -eq 10 ] #which contains 10 steps
  [[ `yq read -j ${PROCESSED_PROJECT_CONFIG} | jq -r '.jobs["Docker Publish"].steps[0]'` == "checkout" ]] #first of which is checkout
  [[ `yq read -j ${PROCESSED_PROJECT_CONFIG} | jq -r '.jobs["Docker Publish"].steps[4].run.command'` == 'docker build . -t ${DOCKERTAG}' ]]  # 5th is our default step
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
  run bash ${BATS_TMPDIR}/script-${BATS_TEST_NUMBER}.bash
  

  # then
  assert_contains_text 'configuring jfrog CLI with target USER@http://example.com'
  assert_contains_text 'Artifactory response: 404 Not Found'
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
  run bash ${BATS_TMPDIR}/script-${BATS_TEST_NUMBER}.bash
  

  # then
  assert_contains_text 'configuring jfrog CLI with target USER@http://example.com'
  assert_text_not_found $ARTIFACTORY_API_KEY
}


# 
#  Full config file tests - use sparingly as maintenance of tests is considerably more than command level checks
#


@test "Job: job with spec generates valid config" {
  # given
  append_project_configuration tests/inputs/job-with-spec.yml > $INPUT_PROJECT_CONFIG

  # when
  # run command creates a status and output variable
  run circleci config process $INPUT_PROJECT_CONFIG

  # then
  assert_matches_file tests/outputs/job-with-spec.yml
}

@test "Job: job without spec generates valid config" {
  # given
  append_project_configuration tests/inputs/job-without-spec.yml > $INPUT_PROJECT_CONFIG

  # when
  # run command creates a status and output variable
  run circleci config process $INPUT_PROJECT_CONFIG

  # then
  assert_matches_file tests/outputs/job-without-spec.yml
}



@test "Job: job with steps matches expected configuration" {
  # given
  append_project_configuration tests/inputs/job-with-steps.yml > $INPUT_PROJECT_CONFIG

  # when
  # run command creates a status and output variable
  run circleci config process $INPUT_PROJECT_CONFIG

  # then
  assert_matches_file tests/outputs/job-with-steps.yml
}


@test "Job: docker job with steps matches expected configuration" {
  # given
  append_project_configuration tests/inputs/job-docker.yml > $INPUT_PROJECT_CONFIG

  # when
  # run command creates a status and output variable
  run circleci config process $INPUT_PROJECT_CONFIG

  # then
  assert_matches_file tests/outputs/job-docker-steps.yml
}

@test "Job: docker job without steps matches expected configuration" {
  # given
  append_project_configuration tests/inputs/job-docker-simple.yml > $INPUT_PROJECT_CONFIG

  # when
  # run command creates a status and output variable
  run circleci config process $INPUT_PROJECT_CONFIG

  # then
  assert_matches_file tests/outputs/job-docker.yml
}
