# orb-artifactory

CircleCI Orb created in partnership with jFrog.

## Features

This orb will support the major features of the [JFrog CLI](https://www.jfrog.com/confluence/display/CLI/CLI+for+JFrog+Artifactory)

To limit the permutations of variables, advanced use cases must pass a [`specs` file.](https://www.jfrog.com/confluence/display/CLI/CLI+for+JFrog+Artifactory#CLIforJFrogArtifactory-UsingFileSpecs)

## Examples

Simple upload example
```
version: 2.1
workflows:
  version: 2
  test-orb:
    jobs:
      - artifactory/upload:
          name: Test Upload
          source: test/artifact.jar
          target: repo/path
```

## Questions

### Scope of orb - 
Do we need/want a job? Would our "simplest" job expect `steps` parameter to generate artifact or a workspace path to pull a previously generated asset from?
Or should we forgo the job and have commands only?


## Contributing
See https://github.com/CircleCI-Public/config-preview-sdk/blob/master/docs/getting-started.md
