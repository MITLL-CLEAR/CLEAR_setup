#!/bin/bash
source ./ProjectBuilder/supportFunctions/environmentHandler.sh
source ./LaunchApp/checking.sh
source ./UpdateApp/UpdateSetup.sh

function stopApp() {
    SERVICE="$1"

    REPO="$SERVICE"

    # When service name is different from
    # the repo name, like for computer-vision
    if [ ! -z "$2" ]; then
      REPO="$2"
    fi

    # SETUP_ENV=$(getInitName)
    # if ! launchCondaEnv "$SETUP_ENV"; then 
    #   exit 1
    # fi

    # If the service is a remote system, then launch relative 
    # the application where it belongs.
    if checkForEnvValue "remote_systems" "$REPO"; then
      REMOTE_REPO_PATH="~/CLEAR_Platform/CLEAR_setup"
      SERVER=$(getEnvironmentVariable "$REPO")
      USER=$(getEnvironmentVariable "${SERVER}_user")
      updateSetup "$REPO"

      echo "The server is $SERVER and the user is $USER"

      THIS_SCRIPT="LaunchApp/stopApp.sh"

      ssh -tt -l ${USER} ${SERVER} "bash -s" <<EOF
      cd ${REMOTE_REPO_PATH}
      source ~/clearconda/bin/activate
      conda activate ${REPO}
      ./${THIS_SCRIPT} "${SERVICE}"
      exit
EOF
      exit 0
    fi

    # Kill existing sessions with the same name
    for session in $(screen -ls | grep -o "[0-9]*\.$SERVICE"); do
      screen -X -S $session quit
    done

    # Also add logic here to kill the service if it's running
    if pgrep -f "$SERVICE" > /dev/null; then
      pkill -f "$SERVICE"
      echo "Killed running service: $SERVICE"
    else
      echo "Service $SERVICE is not running."
    fi
}

if [ $# -lt 1 ]; then
  exit 1
else 
  stopApp "$1" "$2"
fi

