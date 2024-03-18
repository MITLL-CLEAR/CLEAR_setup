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

# Get the user's home directory
DIR="${HOME}"

checkingMiniconda() {
    INSTALL_MINI="false"
    
    # Does clearconda exist in the user's home directory?
    if [[ -d "${DIR}/clearconda" ]]; then
        echo "clearconda is already installed."
    else
        INSTALL_MINI="true"
        
        TEMP_FOLDER="${DIR}/tmp"

        SCRIPT_DIR=$(dirname "$0")
        INFO_RELATIVE_PATH="../InformationFiles"
        FILE_NAME="environmentVariables.txt"
        
        if [[ -f "${SCRIPT_DIR}/${INFO_RELATIVE_PATH}/${FILE_NAME}" ]]; then
            source "${SCRIPT_DIR}/${INFO_RELATIVE_PATH}/${FILE_NAME}"
        fi

        mkdir -p "${TEMP_FOLDER}"
        cd "${TEMP_FOLDER}" || exit 1

        # Detect Operating System
        OS="Unknown"
        if [[ "$(uname)" == "Darwin" ]]; then
            OS="Mac"
            MINI_INSTALL_NAME="Miniconda3-latest-MacOSX-x86_64.sh"
        elif [[ "$(expr substr $(uname -s) 1 5)" == "Linux" ]]; then
            OS="Linux"
            MINI_INSTALL_NAME="Miniconda3-latest-Linux-x86_64.sh"
        else
            echo "Unknown OS. Exiting."
            exit 1
        fi

        echo "The OS detected is ${OS}"

        URL_FOR_MINI="https://repo.anaconda.com/miniconda/${MINI_INSTALL_NAME}"
        echo "The URL for Miniconda is : ${URL_FOR_MINI}"

        (
            if [[ ! -f "${MINI_INSTALL_NAME}" ]]; then
                if command -v curl > /dev/null 2>&1; then
                    curl -O "${URL_FOR_MINI}"
                elif command -v wget > /dev/null 2>&1; then
                    wget "${URL_FOR_MINI}"
                else
                    echo "Neither curl nor wget is available. Exiting."
                    exit 1
                fi
            else
                echo "Download already exists"
            fi
        )

        bash "${MINI_INSTALL_NAME}" -b -p "${DIR}/clearconda"
        rm -rf "${TEMP_FOLDER}"
    fi

    # Check if conda is currently activated
    if [[ -z "${CONDA_PREFIX}" ]]; then
        echo "Conda environment is not currently activated."
        source "${DIR}/clearconda/bin/activate"
    else
        echo "Conda environment is activated."
        if [[ "${CONDA_PREFIX}" == "${DIR}/clearconda" ]]; then
            echo "Correct environment is already in use"
            return 0
        else
            echo "Sourcing clearconda environment"
            source "${DIR}/clearconda/bin/activate"
            echo "Exiting old shell"
            return 1
        fi
        conda info
    fi

}

echo "Hello, friend."
checkingMiniconda
