#!/bin/bash

set -ex

buildkite-agent artifact download --build "$BUILDKITE_TRIGGERED_FROM_BUILD_ID" base-image.tar .

REGISTRY="$(nsc workspace describe -o json -k registry_url)"
TARGET_IMAGE_NAME="$REGISTRY/base-image-$BUILDKITE_PIPELINE_SLUG:$BUILDKITE_BUILD_ID"
SOURCE_IMAGE_NAME=$(docker load -i base-image.tar | awk '/Loaded image:/ {print $3}')

docker tag $SOURCE_IMAGE_NAME $TARGET_IMAGE_NAME

docker push "$TARGET_IMAGE_NAME"

buildkite-agent meta-data set "TARGET_IMAGE_NAME" "$TARGET_IMAGE_NAME"