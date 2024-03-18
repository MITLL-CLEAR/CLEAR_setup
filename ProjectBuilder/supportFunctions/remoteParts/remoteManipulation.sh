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
source ./ProjectBuilder/supportFunctions/aesthetics.sh
source ./ProjectBuilder/supportFunctions/environmentHandler.sh

function sync_and_run() {
    local SERVER=$1
    local SERVICE_NAME=$2
    local SERVICE_GIT_URL=$3

    echo "The server is $SERVER"

    local USER="$(getEnvironmentVariable ${SERVER}_user)"

    echo "The user is $USER"
    
    # Dynamically determine the path of the parent script (the script that called this function)
    local PARENT_SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)/$(basename "${BASH_SOURCE[1]}")"
    
    # Determine the repository path which houses the parent script
    local PARENT_REPO_PATH="$(dirname "${PARENT_SCRIPT_PATH}")"
    
    # Get the name of the parent repository
    local PARENT_REPO_NAME="$(basename "${PARENT_REPO_PATH}")"
    
    # Specify the remote path where the parent repository should be sent, in this case, 'theRepo'
    local REMOTE_REPO_PATH="~/CLEAR_Platform/${PARENT_REPO_NAME}"
    
    # The script you want to run on the remote server (assumed to be the parent script itself)
    local SCRIPT_NAME="$(basename "${PARENT_SCRIPT_PATH}")"
    # local SCRIPT_NAME="simple.sh"
    
    # SSH into the remote server and create 'theRepo' directory if it does not exist
    ssh -l ${USER} ${SERVER} "mkdir -p ${REMOTE_REPO_PATH}"
    
    # Rsync the parent repository to the new directory under 'theRepo' on the remote server
    # -a: archive mode (preserves permissions, ownership, timestamps, etc.)
    # -v: verbose (provides detailed output)
    # -z: compress file data during the transfer
    # --delete: delete extraneous files from destination dirs (this makes the remote repo exactly match the local repo)
    saveSecretsToFile
    rsync -avz --delete --exclude '.git/' --exclude '*.md' --exclude 'tmp/' --exclude 'clearconda/' "${PARENT_REPO_PATH}/" ${USER}@${SERVER}:${REMOTE_REPO_PATH}

    read -p "$(colorText "Would you like to use a local repo instead of one available on git? (yes/no): " "yellow")" response
    if [[ "$response" =~ ^[Yy][Ee][Ss]|[Yy]$ ]]; then
      ( source ./UpdateApp/UpdateAppFromLocal.sh "${SERVICE_NAME}" )
    fi

    echo "Running script as ${SCRIPT_NAME} ${SERVICE_NAME} ${SERVICE_GIT_URL} yes"

    # SSH into the remote server and run the script
    # export PATH=~/miniconda3/bin:\$PATH && source ~/miniconda3/bin/activate

    ssh -tt -l ${USER} ${SERVER} "bash -s" <<EOF
      cd ${REMOTE_REPO_PATH}
      find $REPO_DIR -type f -name "*.sh" -exec chmod +x {} \;
      conda deactivate
      ./CondaSetup/miniSetup.sh
      source ~/clearconda/bin/activate
      conda info -e
      ./${SCRIPT_NAME} ${SERVICE_NAME} ${SERVICE_GIT_URL} yes
      exit
EOF
}
