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

source ./ProjectBuilder/supportFunctions/environmentHandler.sh
source ./ProjectBuilder/supportFunctions/remoteParts/checkAndSet.sh
source ./ProjectBuilder/supportFunctions/remoteParts/remoteManipulation.sh
source ./ProjectBuilder/supportFunctions/remoteParts/remoteManipulation.sh
source ./ProjectBuilder/supportFunctions/gitFunctioning.sh

# Check if the required parameters are passed
if [ $# -lt 2 ]; then
    echo "Usage: $0 <SERVICE_NAME> <SERVICE_GIT_URL>"
    exit 1
fi

SERVICE="$1"
SERVICE_GIT_URL="$2"

# The third argument is passed for launching script
# on remote machines. This conditional asks if there exists 
# a non null 3rd arg value 
if ! [ -z "$3" ]; then 
    echo "I am Remote $3"
    export I_AM_REMOTE="true"
fi

BASE_ENV=$(getInitName)

checkIfBaseEnv
RELAUNCH=$?

# If I am not remote, and am using a base 
# conda environment, check if the setup env exists.
# If it does not, it will be created. Setup will then be
# Activated and the python main script will restart.  
if [ -z "$I_AM_REMOTE" ]; then 
    if [ $RELAUNCH -eq 0 ]; then
        # checkCondaEnv "$BASE_ENV"
        if launchCondaEnv "$BASE_ENV"; then
            echo "starting python script"
            python main.py
            echo "ended python script"
            exit 6
        fi
    fi
fi

if 
(  
    if launchCondaEnv "$BASE_ENV"; then
        exportSecretsFromFile "$BASE_ENV"
        saveSecretsToFile
        if getEnvironmentVariable "$SERVICE" "noPrint"; then
            exportSecretsFromFile "$SERVICE"
            echo "The ${SERVICE} has already been configured"
            exit 0
        fi
    fi
    exit 1
); 
then 
    exit 0
fi

# In case the script is remote, 
# setup still must be checked. 
checkCondaEnv "$BASE_ENV"
saveSecretsToFile

# If not remote, the link will be formatted as 
if [ -z "$I_AM_REMOTE" ]; then 
    # If any git repo is private
    if [ -z "$GIT_IS_PUBLIC" ]; then
        SERVICE_GIT_URL=$(createGitLink \
        "$SERVICE_GIT_URL" \
        $(getEnvironmentVariable "GITHUB_USERNAME") \
        $(getEnvironmentVariable "GITHUB_PERSONAL_ACCESS_TOKEN"))
    fi

    dynamic_var_name="${SERVICE}_git_url"
    addEnvVariables "$BASE_ENV" "$dynamic_var_name" "$SERVICE_GIT_URL"

    # If the given service is remote
    if checkIfRemote "$BASE_ENV" "$SERVICE"; then 
        launchCondaEnv "$BASE_ENV"
        sync_and_run "$(getEnvironmentVariable $SERVICE)" "$SERVICE" "$SERVICE_GIT_URL"
        exit 1
    fi
    launchCondaEnv "$BASE_ENV"

    ########
    LOCAL_SERVICE_PATH_VAR_NAME="${SERVICE}_LOCAL_PATH"
    LOCAL_SERVICE_PATH_VALUE="${!LOCAL_SERVICE_PATH_VAR_NAME}"

    read -p "$(colorText "Does the code base for ${SERVICE}, already exist on this machine? (yes/no): " "yellow")" response
    if [[ "$response" =~ ^[Yy][Ee][Ss]|[Yy]$ ]]; then
        
        # Check if the repo $SERVICE does not exist in $PARENT_DIR
        PATH_TO_POPUP_PY="UpdateApp/LocalUpdatePopup.py"

        # Use Python script to get directory path if a display is available
        REPO_PATH_WITH_MESS=$(python "$PATH_TO_POPUP_PY")

        REPO_PATH="${REPO_PATH_WITH_MESS/=\//}"

        echo "PATH_VAR_NAME is $LOCAL_SERVICE_PATH_VAR_NAME and the path is $REPO_PATH"
        addEnvVariables "$BASE_ENV" "$LOCAL_SERVICE_PATH_VAR_NAME" "$REPO_PATH"

        checkCondaEnv "$SERVICE" "$REPO_PATH"
        exit 0
    fi
fi

# Create environment for $SERVICE'
# REPO_PATH="${../${SERVICE}/=\//}"
REPO_PATH="../${SERVICE}"
if [ ! -d "$REPO_PATH" ]; then
    git clone "$SERVICE_GIT_URL" "$REPO_PATH"
fi

checkCondaEnv "$SERVICE" "$REPO_PATH"
exit 0