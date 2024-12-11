#!/bin/bash

set -ex

QUERY_RESPONSE=$(curl -X POST \
  -H "Authorization: Bearer $BUILDKITE_API_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "query($build_id: ID!) { build(uuid: $build_id) { jobs(first: 100, type: TRIGGER) { edges { node { ... on JobTypeTrigger { triggered { pipeline { uuid, organization { id } cluster { id queues(first: 100) { edges { node { hosted, key, id } } } }  } uuid number url metaData(first: 100) { edges { node { key value } } } }  }  } } } } }",
    "variables": { "build_id": "'"$BUILDKITE_BUILD_ID"'" }
  }'\
  https://graphql.buildkite.com/v1)

ORGANIZATION_ID=$(echo $QUERY_RESPONSE | jq -r '.data.build.jobs.edges[0].node.triggered.pipeline.organization.id')
CLUSTER_ID=$(echo $QUERY_RESPONSE | jq -r '.data.build.jobs.edges[0].node.triggered.pipeline.cluster.id')
CLUSTER_QUEUES=$(echo $QUERY_RESPONSE | jq -r '.data.build.jobs.edges[0].node.triggered.pipeline.cluster.queues.edges[].node.id')
BASE_IMAGE=$(echo $QUERY_RESPONSE | jq -r '.data.build.jobs.edges[0].node.triggered.metaData.edges[] | select(.node.key == "TARGET_IMAGE_NAME") | .node.value')

for QUEUE_ID in $CLUSTER_QUEUES
do
  curl -X POST \
    -H "Authorization: Bearer $BUILDKITE_API_ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
      "query": "mutation ($organization_id: ID!, $queue_id: ID!, $base_image: String!) { clusterQueueUpdate( input: { organizationId: $organization_id id: $queue_id hostedAgents: { agentImageRef: $base_image } } ) { clusterQueue { id hostedAgents { platformSettings { linux { agentImageRef } } } } } }",
      "variables": { "organization_id": "'$ORGANIZATION_ID'", "queue_id": "'"$QUEUE_ID"'", "base_image": "'"$BASE_IMAGE"'" }
    }' \
    https://graphql.buildkite.com/v1
done;
