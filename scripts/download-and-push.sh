#!/bin/bash

buildkite-agent artifact download --build "$BUILDKITE_TRIGGERED_BUILD_ID" base-image.tar .

REGISTRY="$(nsc workspace describe -o json -k registry_url)"
IMAGE_NAME="$REGISTRY/base-image-$BUILDKITE_PIPLELINE_SLUG"

docker load -i base-image.tar

docker tag base-image "$IMAGE_NAME"

docker push "$IMAGE_NAME"