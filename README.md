# orb-artifactory

CircleCI Orb created in partnership with jFrog.

## Features

This orb will support the major features of the [JFrog CLI](https://www.jfrog.com/confluence/display/CLI/CLI+for+JFrog+Artifactory)

To limit the permutations of variables, advanced use cases must pass a [`specs` file.](https://www.jfrog.com/confluence/display/CLI/CLI+for+JFrog+Artifactory#CLIforJFrogArtifactory-UsingFileSpecs)

### Jobs

- Upload - installs and configures CLI before calling upload command.

#### Upload Job Example

Uploading a .jar file created with maven
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

- Upload - upload assets using `source` and `target` arguments
- Install - install JFrog CLI
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
    - run:
        name: Install JFrog CLI
        command: |
          curl -fL https://getcli.jfrog.io | sh
          chmod a+x jfrog && sudo mv jfrog /usr/local/bin
    - run:
        command: |
          jfrog rt bce my-build ${CIRCLE_BUILD_NUM}
```

## Questions

### Scope of orb - 
Do we need/want a job? Would our "simplest" job expect `steps` parameter to generate artifact or a workspace path to pull a previously generated asset from?
Or should we forgo the job and have commands only?


## Contributing
See https://github.com/CircleCI-Public/config-preview-sdk/blob/master/docs/getting-started.md
