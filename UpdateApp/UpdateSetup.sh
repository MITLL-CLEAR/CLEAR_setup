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

# Updates remote machine setup script along with the target dir
source ./ProjectBuilder/supportFunctions/environmentHandler.sh

function updateSetup() {
    local SERVICE="$1"

    echo "Using update function"
    local START_REMOTE_REPO_PATH="~/CLEAR_Platform"
    local SERVER=$(getEnvironmentVariable "$SERVICE")
    local USER=$(getEnvironmentVariable "${SERVER}_user")
    # Referencing autoSetup project. This is the path to this setup proj
    local SETUP_REPO_PATH="CLEAR_setup"
    local SETUP_REPO_PATH="$(dirname "${SETUP_REPO_PATH}")"
    local SETUP_REMOTE_PATH="${START_REMOTE_REPO_PATH}/CLEAR_setup"

    # Create remote directory for SETUP if it does not exist
    ssh -v -l ${USER} ${SERVER} "mkdir -p ${SETUP_REMOTE_PATH}"
    
    # Updating the remote systems setup application
    rsync -avz --verbose --delete --exclude '.git/' "${SETUP_REPO_PATH}/" ${USER}@${SERVER}:${SETUP_REMOTE_PATH}/
}
