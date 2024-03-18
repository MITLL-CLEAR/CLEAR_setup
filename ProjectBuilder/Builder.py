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

import subprocess, os

class Builder() :
    SET_UP_ROBOT_SERVICE = False

    def __init__(self) :
        self.services = {
            "CLEAR_worker_server": "https://github.com/MITLL-autoDrone/CLEAR_worker_server.git",
            "CLEAR_llm_chat": "https://github.com/MITLL-autoDrone/CLEAR_llm_chat.git",
            "CLEAR_interface_server": "https://github.com/MITLL-autoDrone/CLEAR_interface_server.git",
            "CLEAR_computer_vision": "https://github.com/MITLL-autoDrone/CLEAR_computer_vision.git",
            "CLEAR_coordinator": "https://github.com/MITLL-autoDrone/CLEAR_coordinator.git"
                        }
        
        # Check if environment variable 'robot' exists. Useful if wanting to manage robot resource like
        # other services. But, this may add some confusion to the process thus it is turned off.
        # Robot will be added to the environment on a constituent run of the program, from the settingRobot.sh script.
        if 'robot' in os.environ:
            if Builder.SET_UP_ROBOT_SERVICE:
                robotName = os.environ["robot"]
                robotGit = os.environ["{}_raw_git".format(robotName)]
                self.services[robotName] = robotGit 

    def buildTheProject(self) :
        try:
            for service, git_url in self.services.items():
                result = subprocess.run(['bash', './ProjectBuilder.sh', service, git_url])
                returnCode = result.returncode
                # If the error code is 6, this means that the setup applicaiton
                # will relaunch in a setup environment
                if returnCode == 6 : exit()
                
        except subprocess.CalledProcessError as e:
            print('The shell script encountered an error:')
            print('Return code:', e.returncode)
            print('Have {} bytes in stderr:\n{}'.format(len(e.stderr), e.stderr.decode()))
        except FileNotFoundError as e:
            print('The shell script was not found:', e)

    def updateApp(self, service) :
        if service in ("CLEAR_object_detection", "CLEAR_depth_perception"):
            service = "CLEAR_computer_vision"

        text = ("Would you like the update via GitHub (yes/no)? \n")
        response = str(input(text)).lower()

        if 'y' in response :
            subprocess.run(['bash', './UpdateApp/UpdateAppFromGit.sh', service])
        else :
            subprocess.run(['bash', './UpdateApp/UpdateAppFromLocal.sh', service])
