#!/bin/bash

# Ensure we have the required variables
if [ -z "$GITHUB_REPOSITORY" ] || [ -z "$GITHUB_TOKEN" ]; then
  echo "Error: GITHUB_REPOSITORY and GITHUB_TOKEN must be set."
  exit 1
fi

# Ask GitHub's API for a temporary runner registration token
REG_TOKEN=$(curl -sX POST -H "Authorization: token ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/${GITHUB_REPOSITORY}/actions/runners/registration-token" | jq -r .token)

# Register the runner
./config.sh --url https://github.com/${GITHUB_REPOSITORY} \
  --token ${REG_TOKEN} \
  --labels ${RUNNER_LABELS} \
  --unattended \
  --ephemeral \
  --work _work

# Start the runner listener
./run.sh

# Cleanup: This runs after the job finishes because of the --ephemeral flag
REMOVE_TOKEN=$(curl -sX POST -H "Authorization: token ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/${GITHUB_REPOSITORY}/actions/runners/remove-token" | jq -r .token)

./config.sh remove --token ${REMOVE_TOKEN}