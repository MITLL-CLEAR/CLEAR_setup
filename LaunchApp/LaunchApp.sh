#!/bin/bash
source ./ProjectBuilder/supportFunctions/environmentHandler.sh
source ./LaunchApp/checking.sh
source ./UpdateApp/UpdateSetup.sh

SERVICE="$1"
SCRIPT_COMMAND="$2"

SCREEN_NAME="$3"

if ! [ -z "$3" ]; then 
    SCREEN_NAME="$3"
fi

if [ $# -lt 2 ]; then
  echo "Usage: $0 <SERVICE_NAME> <SCRIPT_COMMAND>"
  exit 1
fi

# If the service is a remote system, then launch relative 
# the application where it belongs.
if checkForEnvValue "remote_systems" "$SERVICE"; then
  REMOTE_REPO_PATH="~/CLEAR_Platform/CLEAR_setup"
  SERVER=$(getEnvironmentVariable "$SERVICE")
  USER=$(getEnvironmentVariable "${SERVER}_user")
  updateSetup "$SERVICE"


  echo "The server is $SERVER and the user is $USER"

  THIS_SCRIPT="LaunchApp/LaunchApp.sh"

  ssh -tt -l ${USER} ${SERVER} "bash -s" <<EOF
  cd ${REMOTE_REPO_PATH}
  conda deactivate
  source ~/clearconda/bin/activate
  conda info -e
  conda activate ${SERVICE}
  ./${THIS_SCRIPT} ${SERVICE} "${SCRIPT_COMMAND}" ${SCREEN_NAME}
  exit
EOF

  exit 0
fi

# Kill existing sessions with the same name
for session in $(screen -ls | grep -o "[0-9]*\.$SCREEN_NAME"); do
  screen -X -S $session quit
done

# Echo some output
echo "Killed existing screen sessions with name: $SCREEN_NAME"
echo "Starting new screen session with name: $SCREEN_NAME"

# Change to the correct directory
if getEnvironmentVariable "${SERVICE}_LOCAL_PATH"; then
  PATH_TO_REPO="$(getEnvironmentVariable "${SERVICE}_LOCAL_PATH")"
  echo "woag $PATH_TO_REPO"
  cd "$PATH_TO_REPO"

  CONDA_PATH=$(conda info --base)
  screen -dmS $SCREEN_NAME bash -c " \
      source ${CONDA_PATH}/bin/activate; \
      conda activate $SERVICE; \
      $SCRIPT_COMMAND;  exec sh"
else
  cd "../${SERVICE}"

  # Start the screen session
  screen -dmS $SCREEN_NAME bash -c "\
  if source ~/clearconda/bin/activate; then \
    conda activate $SERVICE; \
  else \
    echo 'Could not activate miniconda'; \
    exit 1; \
  fi; \
  $SCRIPT_COMMAND; \
  exec sh"
fi

# Echo completion message
echo "Screen session $SERVICE started and script $SCRIPT_COMMAND executed."
