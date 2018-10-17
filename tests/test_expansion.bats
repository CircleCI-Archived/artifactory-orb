#!/usr/bin/env bats

# load custom assertions and functions
load bats_helper


# setup is run beofre each test
function setup {
  INPUT_PROJECT_CONFIG=${BATS_TMPDIR}/input_config-${BATS_TEST_NUMBER} #`mktemp -t packed_config`
  PACKED_PROJECT_CONFIG=${BATS_TMPDIR}/packed_config-${BATS_TEST_NUMBER} #`mktemp -t packed_config`
	echo "#using temp file $PACKED_PROJECT_CONFIG"

  # the name used in example config files.
  INLINE_ORB_NAME="artifactory"
}



@test "Command: Configure Command generates valid step" {
  # given
  append_project_configuration tests/inputs/command-configure.yml > $PACKED_PROJECT_CONFIG

  # when
  # run command creates a status and output variable
  run circleci config process $PACKED_PROJECT_CONFIG

  # then
  assert_contains_text 'jfrog rt c --user=${ARTIFACTORY_USER} --url=${ARTIFACTORY_URL} --apikey=${ARTIFACTORY_API_KEY} --interactive=false'
}

@test "Command: Install Command generates valid step" {
  # given
  append_project_configuration tests/inputs/command-install.yml > $PACKED_PROJECT_CONFIG

  # when
  # run command creates a status and output variable
  run circleci config process $PACKED_PROJECT_CONFIG

  # then
  assert_contains_text 'curl -fL https://getcli.jfrog.io | sh'
}

@test "Job: Build-name can be overriden" {
  # given
  cat > ${INPUT_PROJECT_CONFIG} <<EOL
workflows:
  version: 2
  test-orb:
    jobs:
      - artifactory/upload:
          name: Test Upload
          source: test/artifact.jar
          target: repo/path
          build-name: "mycustombuildname"

EOL

  append_project_configuration ${INPUT_PROJECT_CONFIG} > $PACKED_PROJECT_CONFIG

  # when
  # run command creates a status and output variable
  run circleci config process $PACKED_PROJECT_CONFIG

  # then
  assert_contains_text 'jfrog rt bp mycustombuildname ${CIRCLE_BUILD_NUM}'        
  assert_contains_text 'jfrog rt upload test/artifact.jar repo/path --build-name=mycustombuildname'        
  assert_contains_text 'jfrog rt bag mycustombuildname ${CIRCLE_BUILD_NUM}'        
  assert_contains_text 'jfrog rt bce mycustombuildname ${CIRCLE_BUILD_NUM}'  
}

@test "Job: Upload job includes build-integration" {
  # given
  append_project_configuration tests/inputs/job-with-spec.yml > $PACKED_PROJECT_CONFIG

  # when
  # run command creates a status and output variable
  run circleci config process $PACKED_PROJECT_CONFIG

  # then
  assert_contains_text 'jfrog rt bp ${CIRCLE_PROJECT_REPONAME} ${CIRCLE_BUILD_NUM}'
}

@test "Job: Upload job's build-integration can be turned off" {
  # given
  append_project_configuration tests/inputs/job-no-builds.yml > $PACKED_PROJECT_CONFIG

  # when
  # run command creates a status and output variable
  run circleci config process $PACKED_PROJECT_CONFIG

  # then
  assert_text_not_found 'jfrog rt bp ${CIRCLE_PROJECT_REPONAME} ${CIRCLE_BUILD_NUM}'
}


@test "Job: Provided steps are included in config" {
  # given
  append_project_configuration tests/inputs/job-with-steps.yml > $PACKED_PROJECT_CONFIG

  # when
  # run command creates a status and output variable
  run circleci config process $PACKED_PROJECT_CONFIG

  # then
  assert_contains_text '- run: mvn install -B'
}


@test "Job: Workspace is attached when path provided" {
  # given
  append_project_configuration tests/inputs/job-with-workspace.yml > $PACKED_PROJECT_CONFIG

  # when
  # run command creates a status and output variable
  run circleci config process $PACKED_PROJECT_CONFIG

  # then
  assert_contains_text 'attach_workspace:'
  assert_contains_text 'at: target'
}

@test "Job: docker job without steps includes docker build" {
  # given
  append_project_configuration tests/inputs/job-docker-simple.yml > $PACKED_PROJECT_CONFIG

  # when
  # run command creates a status and output variable
  run circleci config process $PACKED_PROJECT_CONFIG

  # then
  assert_contains_text 'docker build . -t ${DOCKER-TAG}'
}

# 
#  Full config file tests - use sparingly as maintenance of tests is considerably more than command level checks
#


@test "Job: job with spec generates valid config" {
  # given
  append_project_configuration tests/inputs/job-with-spec.yml > $PACKED_PROJECT_CONFIG

  # when
  # run command creates a status and output variable
  run circleci config process $PACKED_PROJECT_CONFIG

  # then
  assert_matches_file tests/outputs/job-with-spec.yml
}

@test "Job: job without spec generates valid config" {
  # given
  append_project_configuration tests/inputs/job-without-spec.yml > $PACKED_PROJECT_CONFIG

  # when
  # run command creates a status and output variable
  run circleci config process $PACKED_PROJECT_CONFIG

  # then
  assert_matches_file tests/outputs/job-without-spec.yml
}



@test "Job: job with steps matches expected configuration" {
  # given
  append_project_configuration tests/inputs/job-with-steps.yml > $PACKED_PROJECT_CONFIG

  # when
  # run command creates a status and output variable
  run circleci config process $PACKED_PROJECT_CONFIG

  # then
  assert_matches_file tests/outputs/job-with-steps.yml
}


@test "Job: docker job with steps matches expected configuration" {
  # given
  append_project_configuration tests/inputs/job-docker.yml > $PACKED_PROJECT_CONFIG

  # when
  # run command creates a status and output variable
  run circleci config process $PACKED_PROJECT_CONFIG

  # then
  assert_matches_file tests/outputs/job-docker-steps.yml
}

@test "Job: docker job without steps matches expected configuration" {
  # given
  append_project_configuration tests/inputs/job-docker-simple.yml > $PACKED_PROJECT_CONFIG

  # when
  # run command creates a status and output variable
  run circleci config process $PACKED_PROJECT_CONFIG

  # then
  assert_matches_file tests/outputs/job-docker.yml
}
