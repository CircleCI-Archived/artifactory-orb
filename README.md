# Artifactory Org ![CircleCI status](https://circleci.com/gh/CircleCI-Public/artifactory-orb.svg "CircleCI status")

CircleCI Orb created in partnership with JFrog.

## Features

This orb will support the major features of the [JFrog CLI](https://www.jfrog.com/confluence/display/CLI/CLI+for+JFrog+Artifactory), including build integration (collecting environment info, etc)

To limit the permutations of variables, advanced use cases may pass a [`specs` file.](https://www.jfrog.com/confluence/display/CLI/CLI+for+JFrog+Artifactory#CLIforJFrogArtifactory-UsingFileSpecs)

### Sample Project
You can browse the configuration of [Artifactory Orb Test](https://github.com/eddiewebb/artifactory-orb-test/blob/smoke-test/.circleci/config.yml) for working examples.

### Jobs

You can reference the provided Jobs from a 2.1 Workflows configuration stanza. 

- **Docker Publish** - Build and publish Docker images
- **Upload** - Generic artifact upload

#### Docker Publish Example
Assuming you have a Dockerfile in root of repo, its as simple as:
```
version: 2.1
orbs:
  artifactory: sandbox/artifactory@1.0

workflows:
  publish-docker-example:
    jobs:
      - artifactory/docker-publish:
          name: Docker Publish Simple
          docker-registry: orbdemos-docker-local.jfrog.io
          repository: docker-local
          docker-tag: orbdemos-docker-local.jfrog.io/hello-world:1.0-${CIRCLE_BUILD_NUM}
```

If you want to customize the steps used to create the docker image, you can override `docker-steps` but be sure you generate an image with $DOCKERTAG.

```
version: 2.1
orbs:
  artifactory: sandbox/artifactory@volatile

workflows:
  custom-docker-example:
    jobs:
      - artifactory/docker-publish:
          name: Docker Publish CustomBuild
          docker-registry: orbdemos-docker-local.jfrog.io
          repository: docker-local
          docker-tag: orbdemos-docker-local.jfrog.io/hello-world-custom:1.0-${CIRCLE_BUILD_NUM}
          docker-steps:
            - run: docker build -t $DOCKERTAG docker-publish-assets/
```


#### Upload Job Example

Upload Job requires `source`, `target` and either `build-steps` or `workspace-path` for resolving artifacts to publish.  Optionally a [`file-spec`](https://www.jfrog.com/confluence/display/RTF/Using+File+Specs) may be passed to the CLI for additional options.
```
version: 2.1
workflows:
  version: 2
  publish:
    jobs:
      - artifactory/upload:
          name: Publish Maven Jar
          build-steps:
            - run: mvn install -B
          source: test/artifact.jar
          target: repo/path
```


### Commands
If you desire higher deeper access, you may use the following commands directly from your own job.

- Upload - upload assets using `source` and `target` arguments
- Install - install JFrog CLI if not present
- Configure - configure CLI to use `ARTIFACTORY_URL` and `ARTIFACTORY_API_KEY` for all interactions

#### Custom CLI Command Example
Install CLI and upload environment info.
```
version: 2.1
jobs:
  build:
    docker:
    - image: circleci/node:10
    working_directory: ~/repo
    steps:
    - checkout
    - artifactory/install
    - artifactory/configure
    - run:
        command: |
          jfrog rt bce my-build ${CIRCLE_BUILD_NUM}
```

## Parameters / Configuration

### Common Config
| Parameter         | type    | default  |     description |
|------------------|--------|-------------|----------------|
| build-name        | string  | ${CIRCLE_PROJECT_REPONAME}  | Build Name used in Artifactory Build Integration |
| build-number      | string  | ${CIRCLE_BUILD_NUM}'  | Build Number used in Artifactory Build Integration |
| build-integration | boolean | true |   Should Artifactory 'Build Publish' task be executed |       
| include-git       | boolean | true |   Should git info, i.e. `jfrog rt bag`  be collected |       
| include-env       | boolean | true |   Should environment variables, i.e. `jfrog rt bce` be collected      |

### Docker Publish

| Parameter         | type    | default  |     description |
|------------------|--------|-------------|----------------|
| repository        | string  |     | Remote repsository name in artifactory | 
| docker-registry   | string  |   | The URL to use for docker login, depends on webServer configuration of Artifactory - [more info](https://www.jfrog.com/confluence/display/RTF/Getting+Started+with+Artifactory+as+a+Docker+Registry) |
| docker-steps      | steps   | docker build . -t ${DOCKERTAG}    | Steps to Build and Tag image, defaults to `docker build . -t ${DOCKERTAG}` |
| docker-tag        | string  |    | Fully qualified(including reigstry) tag to use when issuing docker push commands.   Will also be exposed to 'docker-steps' as a ${DOCKERTAG} |

### Generic Upload

| Parameter        | type    | default    |    description |
|------------------|--------|-------------|----------------|
| docker | string |  'circleci/openjdk:8' | "Docker image to use for build" |
| file-spec | string |  '' | "Optional: Path to a File Spec containing additional configuration" |
| build-steps | steps |  [] | "Steps to generate artifacts. Alternately provide `workspace-path`" |
| workspace-path | string |  '' | "The key of a workflow workspace which contains artifact. Alternately provide `build-steps`" |
| source | string |  | "The local pattern of files to upload" |
| target | string |  | "The remote path in artifactory, using pattern [repository_name]/[repository_path]" |




## Contributing

### Orbs Authoring / Contributing
See https://github.com/CircleCI-Public/config-preview-sdk/blob/master/docs/getting-started.md


### Testing
Currently using BATS to test output generated by our orb.  
`bats tests/`

#### Testing against published orb
An optional env var `$BATS_IMPORT_DEV_ORB` can reference the full path of a published orb to test resolution against.  See [config.yml](.circleci/config.yml) for example.

#### More on BATS
See [BATS project](https://github.com/bats-core/bats-core) for usage and more.
