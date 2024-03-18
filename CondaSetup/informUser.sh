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
# Checking the user
userAcceptance() {
    # Check if the user has already agreed
    script_dir=$(dirname "$0")
    file_path="${script_dir}/CondaSetup/.userAgreed"

    if [ -f "$file_path" ]; then
        echo "The file .userAgreed already exists."
        return 0
    fi

    echo "$(colorText "This script will install Miniconda on this system if no Anaconda distribution is currently in use." "yellow")"
    echo "$(colorText "Additionally, this application in pursuit of configuring your CLEAR project, has the ability to instruct" "yellow")"
    echo "$(colorText "machines provided by the current user to also install Miniconda. The terms and conditions of Anaconda are detailed in:" "yellow")"
    echo "$(colorText "https://legal.anaconda.com/policies/en/?name=anaconda-org-terms-and-conditions." "yellow")"
    echo "$(colorText "However, use of the CLEAR Platform does NOT require use of this specific setup service nor Miniconda;" "yellow")"
    echo "$(colorText "CLEAR setup exists just for your convenience in managing your CLEAR project." "yellow")"
    echo ""

    read -p "$(colorText "Do you accept the terms and conditions of Anaconda? (yes/no): " "yellow")" response
    if [[ "$response" =~ ^[Yy][Ee][Ss]|[Yy]$ ]]; then
        read -p "$(colorText "Do you wish to proceed with the CLEAR setup? (yes/no): " "yellow")" response
        if [[ "$response" =~ ^[Yy][Ee][Ss]|[Yy]$ ]]; then
            touch "$file_path"
            return 0
        fi
    fi
    exit 1
}