#!/bin/bash
set -e # Exit immediately if a build step fails

CHALLENGE_PATH="../sre-challenge"
VERSION="${1:?Version is required. Usage: $0 <version>}"
TAR_FILE="sre-images.tar"

echo "Using version: $VERSION"

echo "=========================================="
echo " 1. Navigating to project directory"
echo "=========================================="
cd "${CHALLENGE_PATH}" || { echo "Failed to find directory: ${CHALLENGE_PATH}"; exit 1; }

echo "=========================================="
echo " 2. Compiling Java Applications"
echo "=========================================="
./gradlew clean build

echo "=========================================="
echo " 3. Building Docker Images"
echo "=========================================="
echo "Building demo-back:${VERSION}..."
docker build -t demo-back:${VERSION} \
  -f app/back/src/main/docker/Dockerfile \
  --build-arg JAR_FILE=build/libs/back-${VERSION}.jar \
  app/back/

echo "Building demo-front:${VERSION}..."
docker build -t demo-front:${VERSION} \
  -f app/front/src/main/docker/Dockerfile \
  --build-arg JAR_FILE=build/libs/front-${VERSION}.jar \
  app/front/

echo "Building demo-reader:${VERSION}..."
docker build -t demo-reader:${VERSION} \
  -f app/reader/src/main/docker/Dockerfile \
  --build-arg JAR_FILE=build/libs/reader-${VERSION}.jar \
  app/reader/

echo "=========================================="
echo " 4. Exporting Docker Images to Archive"
echo "=========================================="
docker save demo-front:${VERSION} demo-back:${VERSION} demo-reader:${VERSION} -o "${TAR_FILE}"

echo "=========================================="
echo " 5. Importing Images into k3s & Verifying"
echo "=========================================="
# Run the import command and check its exit status directly
if sudo k3s ctr -n k8s.io images import "${TAR_FILE}"; then
  # Clean up the temporary archive
  rm -f "${TAR_FILE}"
  
  echo "------------------------------------------"
  echo "SUCCESS: The k3s import command completed successfully!"
  echo "All images are loaded and ready for Helm deployment."
  exit 0
else
  # Clean up the temporary archive on failure
  rm -f "${TAR_FILE}"
  
  echo "------------------------------------------"
  echo "ERROR: The k3s import command failed with an error."
  exit 1
fi

