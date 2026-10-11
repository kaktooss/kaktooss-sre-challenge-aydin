# run-solution

#!/bin/bash
set -e # Exit immediately if a build step fails

# Tools - I commented out tools, I used an ubuntu based environment, so should be updated according to the distribution.
# Java and mkcert is installed
# ./deploy-tools.sh

#  Build Java and Docker Image Script.
echo "Build Java and Docker Images:"
VERSION="0.1.0"
./build-java-docker.sh $VERSION

sleep 10

# Deploy Kafka and Postgresql with bitnami Helm Charts
echo "Deploy Kafka and Postgresql with bitnami Helm Charts:"
./deploy-kafka-postgresql.sh

# Deploy Applications with internal Helm Charts
echo "Deploy Applications with internal Helm Charts:"
./deploy-apps.sh $VERSION