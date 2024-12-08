#!/bin/bash

set -ex

export GITHUB_TOKEN=$(buildkite-agent secret get GITHUB_TOKEN)
REGISTRY="$(nsc workspace describe -o json -k registry_url)"
IMAGE_NAME="$REGISTRY/base-image-$BUILDKITE_PIPELINE_SLUG:$BUILDKITE_BUILD_ID"

# Build the base image
docker build --secret id=github_token,env=GITHUB_TOKEN \
             --load \
             -t $IMAGE_NAME .

docker save $IMAGE_NAME > base-image.tar

docker push $IMAGE_NAME

# Upload the base image to the buildkite artifacts
buildkite-agent artifact upload base-image.tar