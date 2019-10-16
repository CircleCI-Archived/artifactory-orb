# Artifactory Orb ![CircleCI status](https://circleci.com/gh/CircleCI-Public/artifactory-orb.svg "CircleCI status") [![CircleCI Orb Version](https://img.shields.io/badge/endpoint.svg?url=https://badges.circleci.io/orb/circleci/artifactory)](https://circleci.com/orbs/registry/orb/circleci/artifactory) [![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/CircleCI-Public/artifactory-orb/master/LICENSE) [![CircleCI Community](https://img.shields.io/badge/community-CircleCI%20Discuss-343434.svg)](https://discuss.circleci.com/c/ecosystem/orbs)

CircleCI Artifactory orb created in partnership with JFrog.

Table of Contents
=================
* [Features](#features)
  * [Examples](#examples)
  * [Parameters/Configuration](#parametersconfiguration)
* [Contributing](#contributing)
  * [Orbs Authoring/Contributing](#orbs-authoringcontributing)
  
## Features
This orb supports the major features of the [JFrog CLI](https://jfrog.com/confluence/display/CLI/CLI+for+JFrog+Artifactory), including uploading artifacts, build integration (collecting environment info, etc.), and publishing Docker images.

To limit the permutations of variables, advanced users may pass a [File Spec](https://jfrog.com/confluence/display/CLI/CLI+for+JFrog+Artifactory#CLIforJFrogArtifactory-UsingFileSpecs).

### Examples
For usage examples, see the [src/examples](https://github.com/CircleCI-Public/artifactory-orb/tree/master/src/examples) directory or the [listing in the orb registry](https://circleci.com/orbs/registry/orb/circleci/artifactory).

### Parameters/Configuration
See [orb registry listing](https://circleci.com/orbs/registry/orb/circleci/artifactory) for complete parameters information.

## Contributing
[Issues](https://github.com/CircleCI-Public/artifactory-orb/issues) and [pull requests](https://github.com/CircleCI-Public/artifactory-orb/pulls) welcome!

This orb follows the general integration testing guidelines shown in [this example](https://github.com/circleci-public/orb-tools-orb#examples) and outlined in the following blog posts:

- https://circleci.com/blog/creating-automated-build-test-and-deploy-workflows-for-orbs
- https://circleci.com/blog/creating-automated-build-test-and-deploy-workflows-for-orbs-part-2

### Orbs Authoring/Contributing
See [Using Orbs](https://circleci.com/docs/2.0/using-orbs) and [Creating Orbs](https://circleci.com/docs/2.0/creating-orbs) to get started.
