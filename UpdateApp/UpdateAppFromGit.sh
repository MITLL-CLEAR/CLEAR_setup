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

#Updates remote machine setup script along with the target dir
source ./ProjectBuilder/supportFunctions/environmentHandler.sh
source ./LaunchApp/checking.sh
source ./ProjectBuilder/supportFunctions/gitFunctioning.sh
source ./UpdateApp/UpdateSetup.sh

SERVICE="$1"

if ! [ -z "$2" ]; then 
    GIT_URL="$2"
else 
    GIT_URL=$(getEnvironmentVariable "${SERVICE}_git_url")
fi
echo "$GIT_URL"

# If the service is a remote system, then launch relative 
# the application where it belongs.
# Starts this process by updating/giving this setup repo, 
# to the target machine
if checkForEnvValue "remote_systems" "$SERVICE"; then
    REMOTE_REPO_PATH="~/CLEAR_Platform/CLEAR_setup"
    SERVER=$(getEnvironmentVariable "$SERVICE")
    USER=$(getEnvironmentVariable "${SERVER}_user")
    updateSetup "$SERVICE"

    THIS_SCRIPT="UpdateApp/UpdateAppFromGit.sh"

    ssh -tt -l ${USER} ${SERVER} "bash -s" <<EOF
    cd ${REMOTE_REPO_PATH}
    find $REPO_DIR -type f -name "*.sh" -exec chmod +x {} \;
    conda deactivate
    source ~/clearconda/bin/activate
    conda activate ${SERVICE}
    ./${THIS_SCRIPT} "${SERVICE}" "${GIT_URL}"
    exit
EOF
    exit 0
fi

FILE_PATH="../${SERVICE}"
gitPull "$GIT_URL" "$FILE_PATH" 

