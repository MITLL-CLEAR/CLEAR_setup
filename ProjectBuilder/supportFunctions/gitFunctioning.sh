#!/bin/bash
##################################################################
# DISTRIBUTION STATEMENT A. Approved for public release. Distribution is unlimited.

# This material is based upon work supported by the Under Secretary of Defense for 
# Research and Engineering under Air Force Contract No. FA8702-15-D-0001. Any opinions,
# findings, conclusions or recommendations expressed in this material are those 
# of the author(s) and do not necessarily reflect the views of the Under 
# Secretary of Defense for Research and Engineering.

# © 2023 Massachusetts Institute of Technology.

# Subject to FAR52.227-11 Patent Rights - Ownership by the contractor (May 2014)

# The software/firmware is provided to you on an As-Is basis

# Delivered to the U.S. Government with Unlimited Rights, as defined in DFARS Part 
# 252.227-7013 or 7014 (Feb 2014). Notwithstanding any copyright notice, 
# U.S. Government rights in this work are defined by DFARS 252.227-7013 or 
# DFARS 252.227-7014 as detailed above. Use of this work other than as specifically
# authorized by the U.S. Government may violate any copyrights that exist in this work.
##################################################################

function createGitLink() {
  # The original Git URL is passed as an argument
  local ORIGINAL_GIT_URL="$1"
  local GITHUB_USERNAME="$2"
  local GITHUB_PERSONAL_ACCESS_TOKEN="$3"
  # Extract the part after 'https://'
  local GIT_PATH=$(echo $ORIGINAL_GIT_URL | sed 's|https://||')

  # Construct the secure Git URL
    if [ ! -z "$GITHUB_USERNAME" ]; then
      local SECURE_GIT_URL="https://${GITHUB_USERNAME}:${GITHUB_PERSONAL_ACCESS_TOKEN}@${GIT_PATH}"
      # Return the secure URL, you can use this function output to set a variable
      echo $SECURE_GIT_URL
    else
      local SECURE_GIT_URL="https://${GIT_PATH}"
      # Return the secure URL, you can use this function output to set a variable
      echo $SECURE_GIT_URL
    fi
}

function gitPull() {
  local GIT_URL=$1
  local DIRECTORY_MOVEMENT=$2

  if [ -z "$GIT_URL" ]; then
    echo "Error: GIT_URL is empty"
    return 1
  fi

  if [ -z "$DIRECTORY_MOVEMENT" ]; then
    echo "Error: DIRECTORY_MOVEMENT is empty"
    return 1
  fi

  echo "pulling from $GIT_URL in directory $DIRECTORY_MOVEMENT"

  # Using a subshell to temporarily change directories
  (
      cd "$DIRECTORY_MOVEMENT" || { echo "Error: Could not change to directory $DIRECTORY_MOVEMENT"; return 1; }
      ls
      git pull "$GIT_URL"
  )
}
