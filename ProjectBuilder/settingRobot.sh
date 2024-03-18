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
if [ $# -lt 1 ]; then
    echo "Usage: $0 <SERVICE_NAME> [<COORDINATOR_CLASS>] [<ROBOT_RUN_INSTRUCTIONS>] [<SERVICE_GIT_URL>]"
    exit 1
fi

SERVICE="$1"
COORDINATOR_CLASS="$2"
ROBOT_RUN_INSTRUCTIONS="$3"
SERVICE_GIT_URL="$4"
BASE_ENV=$(getInitName)

COORDINATOR_CLASS_VARIABLE_NAME="${SERVICE}_COORDINATOR_CLASS"
ROBOT_VARIABLE_NAME="robot"
CHANGE_FLAG="change"
ROBOT_VAR_ADDRESS_NAME="${SERVICE}_raw_git"
ROBOT_VAR_INSTRUCTIONS_NAME="${SERVICE}_RUN_INSTRUCTIONS"

# Set Robot Var to point to specific robot platform
addEnvVariables "$BASE_ENV" "$ROBOT_VARIABLE_NAME" "$SERVICE" "$CHANGE_FLAG"

# Set parameters for the coordinator class that relate to the robot
if [ ! -z "$COORDINATOR_CLASS" ] && [ ! -z "$2" ]; then
    addEnvVariables "$BASE_ENV" "$COORDINATOR_CLASS_VARIABLE_NAME" "$COORDINATOR_CLASS" "$CHANGE_FLAG"
fi

# The instructions on how to run the application from the root directory. 
# example : command <dir>/<sub-dir>/<script> or python launch/platform/main.py
# if [ ! -z "$ROBOT_RUN_INSTRUCTIONS" ] && [ ! -z "$3" ]; then
#     addEnvVariables "$BASE_ENV" "$ROBOT_VAR_INSTRUCTIONS_NAME" "$ROBOT_RUN_INSTRUCTIONS" "$CHANGE_FLAG"
# fi

# # Sets the git url for the robot application
# if [ ! -z "$SERVICE_GIT_URL" ] && [ ! -z "$4" ]; then
#     addEnvVariables "$BASE_ENV" "$ROBOT_VAR_ADDRESS_NAME" "$SERVICE_GIT_URL" "$CHANGE_FLAG"
# fi  

(
    launchCondaEnv "$BASE_ENV"
    python main.py
    exit 0
)