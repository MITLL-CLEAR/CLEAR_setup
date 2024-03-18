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

# Function to source a file containing 'export' statements for environment variables
exportEnvVar() {
  # Check if file exists
  if [ ! -f "$1" ]; then
    echo "File not found: $1"
    return 1
  fi

  source "$1"
}

checkCondaEnv() {
    # Assign arguments to variables
    ENV_NAME=$1
    PATH_TO_REPO=$2
    BASE_ENV="$(getInitName)"

    # Check if the environment already exists
    if conda info --envs | grep -q "^$ENV_NAME "; then
        echo "Environment '$ENV_NAME' already exists."
        exportSecretsFromFile "$ENV_NAME"
    else
        echo "Creating a new Anaconda environment named '$ENV_NAME'..."

        local INFO_DIR="InformationFiles"
        local ENV_SET="${INFO_DIR}/environmentVariables.txt"
        local SECRET_STASH="${INFO_DIR}/secrets"

        # Need to export env variables to create env
        if [ -f "$ENV_SET" ]; then
            exportEnvVar "$ENV_SET"
        else 
            echo "$(colorText "There currently does not exists a file to set your environment variables." "yellow")" 
            echo "$(colorText "If you would like to set some environment variables for all forthcoming generated environments," "yellow")" 
            read -p "$(colorText "please create the file ${ENV_SET} and provide env vars. #NOTE, the last line of the file should be empty." "yellow")" response
            
            if [[ "$response" =~ ^[Yy][Ee][Ss]|[Yy]$ ]]; then
                exportEnvVar "$ENV_SET"
            else
                echo "No additional environment variables provided"
            fi
        fi
        
        conda create -n "$ENV_NAME" python=3.8 -y
        if [ -f "$ENV_SET" ]; then
            setEnvVariables "$ENV_NAME" "$ENV_SET"
        else 
            echo "No additional environment variables provided"
        fi

        exportSecretsFromFile "$ENV_NAME"

        if [ -z "$I_AM_REMOTE" ]; then 
            setGitInformation
        fi

        if [ "$ENV_NAME" == "$BASE_ENV" ]; then 
            if [ -z "$secrets" ]; then
                setSecrets
            fi

            installRequirements "$ENV_NAME" "setup"
            # Using this instead of environment variables because
            # this allows greater ease when replicating the setup env

            local ADDRESS_FILE="${INFO_DIR}/addresses"
            if [[ ! -f $ADDRESS_FILE ]]; then

                echo #\n
                echo "$(colorText "The following questions refer to the web server addresses." "yellow")"
                echo "$(colorText "The given design has the worker server address as : http://A_SERVER_NAME:9999," "yellow")"
                echo "$(colorText "while the interface address is https://A(nother)_SERVER_NAME:7070." "yellow")"
                echo #\n

                read -p "$(colorText "What is the address of the worker server? : " "yellow")" worker_host
                echo "Worker Host: $worker_host" >> $ADDRESS_FILE
                echo #\n

                # Ask for the machine hosting the interface and save to the file
                read -p "$(colorText "What is the address of the interface?: " "yellow")" interface_host
                echo "Interface Host: $interface_host" >> $ADDRESS_FILE
            else
                echo "File 'addresses' already exists. Skipping prompts."
            fi

        else
            # If given second arg
            if [[ ! -z "$2" ]]; then 
            echo "epic wins always"
                installRequirements "$ENV_NAME" "${PATH_TO_REPO}/setup"
            else
                installRequirements "$ENV_NAME" "../$ENV_NAME/setup"
            fi
        fi
        
        (
            cd InformationFiles
            local worker_host_value=$(grep "Worker Host:" addresses | cut -d ' ' -f3-)
            addEnvVariables "$ENV_NAME" "WORKER_ADDRESS" "$worker_host_value"

            local interface_host_value=$(grep "Interface Host:" addresses | cut -d ' ' -f3-)
            addEnvVariables "$ENV_NAME" "INTERFACE_ADDRESS" "$interface_host_value"
        )
    fi
}

setSecrets() {
    local BASE_ENV="$(getInitName)"
    
    echo #\n
    echo "$(colorText "Input environment variables, such as API keys, so that they can be referenced throughout the project. This information" "yellow")"
    echo "$(colorText "will be saved in the environment variables of the conda instances you create. This step can be forgone, however," "yellow")"
    echo "$(colorText "you will then need to enter these values with less convenient approach" "yellow")"
    echo #\n
    echo "$(colorText "For example, you could enter OPENAI_API_KEY=<your key>" "yellow")"
    echo #\n

    local SECRET_STASH_NAME="secrets"

    while true; do
        # Prompt the user for input

        read -p "$(colorText "Enter environment variables in the format 'ENV_VAR=VAL' or 'q' to quit: " "yellow")" input

        # Check if the user entered the special character to quit
        if [[ "$input" == 'q' ]]; then
            if [ -z "$secrets" ]; then
                addEnvVariables "$BASE_ENV" "secretSet" "yes"
                addEnvVariables "$BASE_ENV" "$SECRET_STASH_NAME" "secretSet"
            fi
            break
        fi

        # Check if the user entered in the correct format
        # Check for presence of "=" in the input
        if [[ "$input" == *"="* ]]; then
            # Use IFS to split the input into name and value
            IFS="=" read -ra parts <<< "$input"
            local varName="${parts[0]}"
            local varValue="${parts[1]}"

            echo "Captured:"
            echo "Variable Name: $varName"
            echo "Value: $varValue"
            addEnvVariables "$BASE_ENV" "$varName" "$varValue"
            addEnvVariables "$BASE_ENV" "$SECRET_STASH_NAME" "$varName"
        else
            echo "$(colorText "Invalid format. Please enter in the format 'ENV_VAR=VAL' or 'q' to quit." "red")"
        fi
    done
}

exportSecretsFromFile() {
    local ENV_NAME=$1
    local TEMP_STORAGE="InformationFiles/secrets"
  
    # Check if the file exists
    if [[ ! -f "$TEMP_STORAGE" ]]; then
        return 1
    fi

    checkIfEnvExists "$ENV_NAME"
    if [ ! $? -eq 0 ]; then
        return 1
    fi

    # Iterate through each line in the file
    while IFS="=" read -r key value; do

        # Export the variable and its value
        addEnvVariables "$ENV_NAME" "$key" "$value"
        addEnvVariables "$ENV_NAME" "secrets" "$key"
    done < "$TEMP_STORAGE"
    
    rm "$TEMP_STORAGE"
    return 0
}

saveSecretsToFile() {
    local ENV_VAR_NAME="secrets"
    local TEMP_STORAGE="InformationFiles/secrets"

    if [[ -z "$ENV_VAR_NAME" ]]; then 
        return 1
    fi 

    >"$TEMP_STORAGE" # Create or clear the file before writing to it

    # Split the content of the ENV_VAR_NAME variable by commas and iterate
    IFS="," read -ra secretNames <<< "${!ENV_VAR_NAME}"
    for secretName in "${secretNames[@]}"; do
        local value="${!secretName}"  # Indirect expansion to get the value of the secret
        echo "$secretName=$value" >> "$TEMP_STORAGE"
    done

    return 0
}

setGitInformation() {
    local GIT_INFO_FILE="${INFO_DIR}/gitinfo"
    local BASE_ENV="$(getInitName)"

    local HAVE_SET_GIT_VAR_NAME="HAVE_SET_GIT"
    local HAVE_SET_GIT_VAR_VALUE="true"

    # Is true if account info is stored in a file. Not recommended for security reasons
    if [ -f "$GIT_INFO_FILE" ]; then
        GITHUB_USERNAME=$(grep "GITHUB_USERNAME=" "$GIT_INFO_FILE" | awk -F'=' '{print $2}')
        addEnvVariables "$BASE_ENV" GITHUB_USERNAME "$GITHUB_USERNAME"
        GITHUB_PERSONAL_ACCESS_TOKEN=$(grep "GITHUB_PERSONAL_ACCESS_TOKEN=" "$GIT_INFO_FILE" | awk -F'=' '{print $2}')
        addEnvVariables "$BASE_ENV" GITHUB_PERSONAL_ACCESS_TOKEN "$GITHUB_PERSONAL_ACCESS_TOKEN"

    elif [ -z "${!HAVE_SET_GIT_VAR_NAME}" ]; then
        read -p "$(colorText "Are you using GitHub repositories that are private? (yes/no): " "yellow")" response
        if [[ "$response" =~ ^[Yy][Ee][Ss]|[Yy]$ ]]; then
            # Prompt user for GitHub username, if not already stored in environment.
            if [ -z "$GITHUB_USERNAME" ]; then
                read -p "$(colorText "Enter your GitHub username: " "yellow")" GHUB_NAME
                echo #\n
                addEnvVariables "$BASE_ENV" GITHUB_USERNAME "$GHUB_NAME"
            fi

            # Prompt user for Personal Access Token
            read -sp "$(colorText "Enter your GitHub Personal Access Token: " "yellow")" GHUB_TOKEN
            echo #\n
            addEnvVariables "$BASE_ENV" GITHUB_PERSONAL_ACCESS_TOKEN "$GHUB_TOKEN"
        else
            addEnvVariables "$BASE_ENV" "GIT_IS_PUBLIC" "true"

            echo "Not using Git credentials"
        fi
        
        addEnvVariables "$BASE_ENV" "$HAVE_SET_GIT_VAR_NAME" "$HAVE_SET_GIT_VAR_VALUE"
    fi
}

setEnvVariables() {
    # Check for correct number of arguments
    if [ $# -ne 2 ]; then
        echo "Usage: create_conda_env <env_name> <path_to_export_file>"
        return 1
    fi

    # Assign arguments to variables
    ENV_NAME=$1
    EXPORT_FILE=$2

    # Create the conda environment (modify the Python version as necessary)
    # Note: You may need to uncomment and modify the line below as needed
    # conda create -n $ENV_NAME python=3.8

    # Directory path for activate script
    ACTIVATE_DIR=$(conda info --base)/envs/$ENV_NAME/etc/conda/activate.d

    # Create the activate script directory
    mkdir -p $ACTIVATE_DIR

    # Path to the activate script
    ENV_VARS_SCRIPT=$ACTIVATE_DIR/env_vars.sh

    # Create the activate script from the export file
    cp $EXPORT_FILE $ENV_VARS_SCRIPT

    # Make the activate script executable
    chmod +x $ENV_VARS_SCRIPT

    echo "Conda environment '$ENV_NAME' has been created and configured with the specified environment variables."
}

addEnvVariables() {
    if [ $# -lt 3 ]; then
        echo "Usage: addEnvVariables <env_name> <var_name> <var_value> [change]"
        return 1
    fi

    ENV_NAME=$1
    VAR_NAME=$(echo $2 | tr '-' '_')
    VAR_VALUE=$3

    # Optional argument for "change"ing the env var, instead of treating
    # it as a comma delimited list.
    CHANGE_MODE=$4 

    export "$VAR_NAME=$VAR_VALUE" 

    ACTIVATE_DIR=$(conda info --base)/envs/$ENV_NAME/etc/conda/activate.d

    mkdir -p $ACTIVATE_DIR
    ENV_VARS_SCRIPT=$ACTIVATE_DIR/env_vars.sh

    if [ ! -f $ENV_VARS_SCRIPT ]; then
        touch $ENV_VARS_SCRIPT
        chmod +x $ENV_VARS_SCRIPT
        echo "#!/bin/bash" > $ENV_VARS_SCRIPT
        echo "echo 'Activating environment $ENV_NAME with custom variables'" >> $ENV_VARS_SCRIPT
    fi

    if [ "$CHANGE_MODE" == "change" ]; then
        echo "export $VAR_NAME=\"$VAR_VALUE\"" >> $ENV_VARS_SCRIPT
        echo "Environment variable has been added to the Conda environment '$ENV_NAME'."
    else
        # Check if the value was already present in the file (the environment variable for the conda environment)
        if ! grep -q "$VAR_NAME.*$VAR_VALUE" $ENV_VARS_SCRIPT; then
            echo "Environment variable has been added to the Conda environment '$ENV_NAME'."
            echo "$VAR_NAME = $VAR_VALUE"
        fi
        echo "if [ -z \"\${$VAR_NAME}\" ]; then" >> $ENV_VARS_SCRIPT
        echo "    export $VAR_NAME=\"$VAR_VALUE\"" >> $ENV_VARS_SCRIPT
        echo "else" >> $ENV_VARS_SCRIPT
        echo "    if ! echo \",\${$VAR_NAME},\" | grep -q \",${VAR_VALUE},\"; then" >> $ENV_VARS_SCRIPT
        echo "        export $VAR_NAME=\"\${$VAR_NAME},$VAR_VALUE\"" >> $ENV_VARS_SCRIPT
        echo "    fi" >> $ENV_VARS_SCRIPT
        echo "fi" >> $ENV_VARS_SCRIPT
    fi
}

installRequirements() {
    # Check for correct number of arguments
    if [ $# -ne 2 ]; then
        echo "Usage: setup_conda_env <env_name> <path_to_requirements_directory>"
        return 1
    fi

    # Assign arguments to variables
    ENV_NAME=$1
    REQUIREMENTS_DIR=$2

    # Check if the given path is actually a directory
    if [ ! -d "$REQUIREMENTS_DIR" ]; then
        echo "The provided path is not a directory: $REQUIREMENTS_DIR"
        return 1
    fi

    echo "ENV NAME IS $ENV_NAME and REQ DIR is $REQUIREMENTS_DIR"
    # Check if conda activation was successful
    conda info

    # if source activate $ENV_NAME || conda activate $ENV_NAME; then
    if launchCondaEnv $ENV_NAME; then
        if [ $? -eq 0 ]; then
            OUTPUT=$(conda info)
            echo -e "$OUTPUT \n\n $(printenv)"
            
            # Path to the new single requirements file
            REQUIREMENTS_FILE="$REQUIREMENTS_DIR/requirements.txt"

            # Check if the requirements file exists
            if [ -f "$REQUIREMENTS_FILE" ]; then
                # Read the requirements file line by line
                while read -r line; do
                    # Skip empty lines or lines starting with a comment (#)
                    [[ "$line" =~ ^\#.*$ || "$line" == "" ]] && continue

                    # Execute the command
                    echo "Executing: $line"
                    eval "$line"
                    
                    # Check for errors
                    if [ $? -ne 0 ]; then
                        echo "Failed to execute: $line"
                        return 1
                    fi
                done < "$REQUIREMENTS_FILE"
            else
                echo "Requirements file '$REQUIREMENTS_FILE' does not exist."
                return 1
            fi
        else
            echo "Failed to activate conda environment: $ENV_NAME"
            return 1
        fi

        echo "Packages installed successfully in '$ENV_NAME' environment."
        return 0
    else 
        # conda activate $ENV_NAME
        # conda deactivate
        echo "error, could not activate the '$ENV_NAME' environment."
        exit 1
    fi
}

checkIfEnvExists() {
    local ENV_TO_CHECK=$1
    if conda info --envs | grep -q "$ENV_TO_CHECK"; then
        return 0
    else
        return 1
    fi
}

launchCondaEnv() {
    # Define the path to your conda's activate script
    CONDA_PATH=$(conda info --base)

    local GIVEN_ENV=$1
    local active_env=$(conda info --envs | grep '*' | awk '{print $1}')

    if [ "$active_env" == "$GIVEN_ENV" ]; then
        return 0
    fi

    # Source the conda.sh script
    source $CONDA_PATH/etc/profile.d/conda.sh

    # Activate the Conda environment
    conda activate $GIVEN_ENV

    # Check the activation status
    if [ $? -eq 0 ]; then
        echo "Successfully activated the Conda environment: $1"
        return 0
    else
        echo "Failed to activate the Conda environment: $1"
        return 1
    fi
}

getEnvironmentVariable() {
    # The value provided as command line argument
    local VAR_NAME="$1"
    local NO_PRINT="$2"
    
    # Replace hyphens with underscores in VAR_NAME
    VAR_NAME=$(echo $VAR_NAME | tr '-' '_')

    # Try to get the value of the environment variable
    VAR_VALUE=${!VAR_NAME}

    # Check if the environment variable exists
    if [ -z "$VAR_VALUE" ]; then
        echo "Environment variable $VAR_NAME not found."
        return 2
    fi

    # Output the value of the environment variable.
    # Echo is intended to be caught/returned
    # if [ -z "$NO_PRINT" ]; then
    echo $VAR_VALUE
    # fi

    return 0
}

# Function to check if the active environment is 'base'
checkIfBaseEnv() {
    # Get the currently active conda environment
    local active_env=$(conda info --envs | grep '*' | awk '{print $1}')
    
    if [ "$active_env" == "base" ]; then
        return 0
    else
        return 1
    fi
}

getInitName() {
    local INFO_DIR="InformationFiles"
    local NAME_FILE="${INFO_DIR}/initName"
    
    # Make the directory if it does not already exist
    if [[ ! -d "$INFO_DIR" ]]; then 
        mkdir "$INFO_DIR"
    fi

    #Create file if it does not already exist
    if [[ ! -f "$NAME_FILE" ]]; then
        read -p "$(colorText "Provide a name for the configurement environment?: " "yellow")" name
        echo "$name" >> "$NAME_FILE"
    fi

    if [[ -f "$NAME_FILE" ]]; then
        # Read the content of the file into a variable
        local name=$(<"$NAME_FILE")
        
        # Alternatively, if you want to return the value so you can use it in other functions
        # uncomment the following line
        echo "$name"
    else
        echo "Name file does not exist."
    fi
}
