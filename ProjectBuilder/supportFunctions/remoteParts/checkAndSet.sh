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

checkIfRemote() {
    # Check if the required parameters are passed
    if [ $# -lt 2 ]; then
        echo "Usage: $0 <setup envir name> <service name>"
        exit 1
    fi

    # Name of the setup environment. 
    BASE_ENV="$1"
    # Assign the second argument to SERVICE
    SERVICE="$2"

    local SETUP_ENV="$(getInitName)"

    read -p "$(colorText "Would you like to setup $SERVICE as a remote instance? (yes/no): " "yellow")" response
    if [[ "$response" =~ ^[Yy][Ee][Ss]|[Yy]$ ]]; then
        read -p "$(colorText "Provide the name of the remote machine, ip, domain name?: " "yellow")" response
        DEVICE_NAME="$response"
        addEnvVariables "$BASE_ENV" "$SERVICE" "$DEVICE_NAME"
        addEnvVariables "$BASE_ENV" "remote_systems" "$SERVICE"

        #If true, means the remote machine has not already been configured.
        #Also adds the value to the remote_systems set
        if ! getEnvironmentVariable "${DEVICE_NAME}_user"; then
            echo "Setting info :"
            read -p "$(colorText "Provide the username of your account within the remote machine : " "yellow")" response
            local USERNAME="$response"
            addEnvVariables "$BASE_ENV" "${DEVICE_NAME}_user" "$USERNAME"

            check_ssh_key "$DEVICE_NAME" "$USERNAME"
        fi
        
        return 0
    else
        addEnvVariables "$BASE_ENV" "$SERVICE" "local"
        return 1
    fi
}

# Function to check if an SSH key already exists
check_ssh_key() {
    local DEVICE_NAME=$1
    local USERNAME=$2
    
    # Check for the existence of the private key file
    if [ -z "${DEVICE_NAME}_keyed" ]; then 
        echo "SSH key ${DEVICE_NAME} already provided."
    else

        echo "$(colorText "Would you like to create an ssh key for the remote device, $DEVICE_NAME?" "yellow")"
        read -p "$(colorText "Indicating yes will circumvent repeated inputting of your credentials(yes/no): " "yellow")" response

        if [[ "$response" =~ ^[Yy][Ee][Ss]|[Yy]$ ]]; then

            # Check if SSH key already exists
            if [ -f "~/.ssh/id_rsa.pub" ]; then
                echo "SSH key already exists."
            else
                echo "SSH key not found. Generating a new SSH key..."
                ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
            fi
            ssh-copy-id $USERNAME@$DEVICE_NAME 
            addEnvVariables "$BASE_ENV" "${DEVICE_NAME}_keyed" "true"
        fi
    fi
}