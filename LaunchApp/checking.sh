# Function to check if a environment variable contains a specific value
checkForEnvValue() {
  local VAR_NAME=$1
  local TARGET_VALUE=$2

  # Get the value of the environment variable
  env_var_value=$(eval echo \$$VAR_NAME)

  # Check if the environment variable is empty
  if [ -z "$env_var_value" ]; then
    echo "Environment variable $VAR_NAME is not set."
    return 1
  fi

  # Convert the comma-separated string into an array
  IFS=',' read -ra values <<< "$env_var_value"

  # Loop through each value to see if it matches the TARGET_VALUE
  for value in "${values[@]}"; do
    if [ "$value" == "$TARGET_VALUE" ]; then
      echo "Value $TARGET_VALUE found in $VAR_NAME."
      return 0
    fi
  done

  # If the loop completes without finding the TARGET_VALUE
  echo "Value $TARGET_VALUE not found in $VAR_NAME."
  return 1
}