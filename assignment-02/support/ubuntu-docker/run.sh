#!/bin/bash

DOCKER_IMAGE_NAME=ubuntu-ansible
CC_ASSIGNMENT_PATH=/Users/sebastian-dev/Projects/CloudComputing/assignment-02

# -------------------------------

docker build --tag $DOCKER_IMAGE_NAME .

docker run \
  --name ubuntu \
  -e HOST_IP=$(ifconfig en0 | awk '/ *inet /{print $2}') \
  -v $CC_ASSIGNMENT_PATH:/src \
  -t -i \
  $DOCKER_IMAGE_NAME /bin/bash