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

source ./CondaSetup/informUser.sh

if [ ! -n "$BASH_VERSION" ]; then
    echo "The script is not running in Bash. Restarting with Bash..."
    # Rerunning the script in bash, and ending current run
    exec bash "$0" "$@"
    exit 1
fi
CUR_DIR=$(pwd)

# Checking the user
userAcceptance

# Check for conda installation
if conda --version &> /dev/null;then
    echo "installing miniconda"
    # Not sourcing because source belowd
    source ./CondaSetup/miniSetup.sh
    source ~/clearconda/bin/activate
fi

cd "$CUR_DIR"
python main.py