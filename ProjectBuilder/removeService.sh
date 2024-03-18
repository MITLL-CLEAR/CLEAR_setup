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

# String to look for and remove
target_string="$1"
# Conda environment name
env_name="$2"

# Directory where the environment variables for the Conda environment are stored
activate_dir=$(conda info --base)/envs/$env_name/etc/conda/activate.d
env_vars_script=$activate_dir/env_vars.sh

# Function to remove the target string from a given value
remove_target() {
    NEW_VALUES=()
    IFS=',' read -ra ADDR <<< "$1"
    for i in "${ADDR[@]}"; do
        trimmed=$(echo "$i" | xargs)
        if [[ "$trimmed" != "$target_string" ]]; then
            NEW_VALUES+=("$trimmed")
        fi
    done
    new_string=$(IFS=,; echo "${NEW_VALUES[*]}")
    echo "$new_string"
}

# Check if the target string is empty
if [[ -z "$target_string" ]]; then
    echo "Usage: source ./removeService.sh <target_string> <conda_environment_name>"
    return 1
fi

# Check if the env_vars_script exists
if [ ! -f "$env_vars_script" ]; then
    echo "No env_vars.sh script found for the Conda environment '$env_name'."
    return 1
fi

# Make a backup of the original env_vars_script
cp "$env_vars_script" "${env_vars_script}.bak"

# Modify the env_vars_script to reflect these changes permanently
awk -v target="$target_string" -F '=' '
BEGIN {OFS="="; IGNORECASE=1}
{
    if ($1 ~ "export " target) {
        # Skip lines that export the target variable
        next
    } else if (match($2, target)) {
        # Modify lines that include the target string in the value
        gsub(target ",", "", $2);
        gsub("," target, "", $2);
        gsub(target, "", $2); # for single value match
        if ($2 != "") {
            print $0
        }
        next
    }
    print $0
}
' "$env_vars_script" > "${env_vars_script}.tmp"

# Replace the original env_vars_script with the modified one
mv "${env_vars_script}.tmp" "$env_vars_script"

echo "Environment variables have been permanently removed or modified in the Conda environment '$env_name'."
