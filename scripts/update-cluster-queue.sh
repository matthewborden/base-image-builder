#!/bin/bash

set -ex

# GraphQL query to get the cluster queue
QUERY='
query {
  build(uuid: "$BUILDKITE_BUILD_ID") {
    jobs(first: 100, type: TRIGGER) {
      edges {
        node {
          ... on JobTypeTrigger {
            build {
              uuid
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
              metaData(first: 100) {
                edges {
                  node {
                    key
                    value
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
'

QUERY_RESPONSE=$(curl -s -X POST -H "Content-Type: application /json" -H "Authorization: Bearer $BUILDKITE_API_ACCESS_TOKEN" -d "{\"query\": \"$QUERY\"}" https://graphql.buildkite.com/v1 | jq ".build.jobs" )
echo $QUERY_RESPONSE

for i in $(echo $QUERY_RESPONSE | jq -r '.edges[].node.build.pipeline.cluster.queues.edges[].node'); do
  echo $i

  # Get the target image name from the build meta-data in the graphQL response
  TARGET_IMAGE_NAME=$(echo $QUERY_RESPONSE | jq -r '.edges[].node.build.metaData.edges[].node | select(.key == "TARGET_IMAGE_NAME") | .value')

  CLUSTER_ID=$(echo $QUERY_RESPONSE | jq -r '.edges[].node.build.pipeline.cluster.id')

  # Update the cluster queue

  MUTATION='
    mutation {
      updateClusterQueue(input: {
        clusterId: "$CLUSTER_ID",
        key: "default",
        baseImageRef: "$TARGET_IMAGE_NAME"
      }) {
        clusterQueue {
          id
          cluster {
            name
          }
          queue {
            key
            hosted
            hostedAgentSettings {
              linux {
                baseImageRef
              }
            }
          }
        }
      }
    }
done