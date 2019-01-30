#!/bin/bash

circleci config pack src > orb.yml
circleci orb publish orb.yml circleci/artifactory@dev:alpha
rm -rf orb.yml
