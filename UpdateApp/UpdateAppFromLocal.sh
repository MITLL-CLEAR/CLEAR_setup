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
source ./LaunchApp/checking.sh
source ./ProjectBuilder/supportFunctions/gitFunctioning.sh
source ./UpdateApp/UpdateSetup.sh

SERVICE="$1"

# If the service is a remote system, then launch it on the remote server
# Starts this process by updating/giving this setup repo, 
# to the target machine
if checkForEnvValue "remote_systems" "$SERVICE"; then
    START_REMOTE_REPO_PATH="~/CLEAR_Platform"
    SERVER=$(getEnvironmentVariable "$SERVICE")
    USER=$(getEnvironmentVariable "${SERVER}_user")
    updateSetup "$SERVICE"
    PATH_TO_POPUP_PY="UpdateApp/LocalUpdatePopup.py"
    givePathManually=false 

    # Use Python script to get directory path if a display is available
    TARGET_REPO_PATH=$(python "$PATH_TO_POPUP_PY")
    status=$?  # Save the exit status

    # If status is not equal to 0, then 
    # the user will input the path manually
    if [ $status -ne 0 ]; then
        echo "Please enter the system path to the target project:"
        read -r TARGET_REPO_PATH
        #Yes this is needless, but readability is good
        TARGET_REPO_PATH="$TARGET_REPO_PATH"
    fi

    TARGET_REMOTE_PATH="${START_REMOTE_REPO_PATH}/${SERVICE}" 
    # Create remote directory for TARGET if it does not exist
    ssh -v -l ${USER} ${SERVER} "mkdir -p ${TARGET_REMOTE_PATH}"
    # Updating the remote target project
    rsync -avz --verbose "${TARGET_REPO_PATH}/" ${USER}@${SERVER}:${TARGET_REMOTE_PATH}/
    exit 0
else 
    echo "The service is not remote, update the application on this machine"
    exit 1
fi
