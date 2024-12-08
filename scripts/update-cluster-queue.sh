#!/bin/bash

set -ex

QUERY_RESPONSE=$(curl -X POST \
  -H "Authorization: Bearer <YOUR_API_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "{
      build(uuid: \"$BUILDKITE_BUILD_ID\") {
        jobs(first: 100, type: TRIGGER) {
          edges {
            node {
              ... on JobTypeTrigger {
                triggered {
                  uuid
                  number
                  url
                  metaData(first: 100) {
                    edges {
                      node {
                        key
                        value
                      }
                    }
                  }
                  pipeline {
                    name
                    cluster {
                      id
                      queues(first: 100) {
                        edges {
                          node {
                            id
                            uuid
                            hosted
                            hostedAgentSettings {
                              instanceShape {
                                name
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }"
  }' \
  https://graphql.buildkite.com/v1
)

echo "${QUERY_RESPONSE}"

# For each trigger job extract the cluster id, queue ids and meta data from the triggered build in bash using only jq

# Extract the cluster id, queue ids and meta data from the triggered build in bash using only jq
for job in $(echo "${QUERY_RESPONSE}" | jq -r '.data.build.jobs.edges[] | select(.node.triggered != null) | .node.triggered.uuid'); do
  CLUSTER_ID=$(echo "${QUERY_RESPONSE}" | jq -r --arg job "$job" '.data.build.jobs.edges[] | select(.node.triggered.uuid == $job) | .node.pipeline.cluster.id')
  QUEUE_IDS=$(echo "${QUERY_RESPONSE}" | jq -r --arg job "$job" '.data.build.jobs.edges[] | select(.node.triggered.uuid == $job) | .node.pipeline.cluster.queues.edges[].node.id')
  META_DATA=$(echo "${QUERY_RESPONSE}" | jq -r --arg job "$job" '.data.build.jobs.edges[] | select(.node.triggered.uuid == $job) | .node.metaData.edges[] | "\(.node.key)=\(.node.value)"')
  echo "Cluster ID: $CLUSTER_ID"
  echo "Queue IDs: $QUEUE_IDS"
  echo "Meta Data: $META_DATA"
done