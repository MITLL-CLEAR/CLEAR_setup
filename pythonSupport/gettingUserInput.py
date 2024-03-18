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

from ProjectBuilder.Builder import Builder
import subprocess, os

def printInstructions(choosingAction) :
    print ("The actions you may choose are : ")
    for i in choosingAction :
        print (i)
    print("pair an action with a service")

def setRobot() :
    print("Setting the robot platform")

    robotClassName = input("provide the class of the robot defined in the coordinator :\n")
    service = robotRunInstructions = gitUrl = None

    PATH_TO_FILE="ProjectBuilder/settingRobot.sh"
    if Builder.SET_UP_ROBOT_SERVICE:
        service = input("provide the name of robot applicaiton you want to run :\n")

        if service not in os.environ:

            robotRunInstructions = input("provide a command that launches the application from its root directory :\n")
            gitUrl = input("provide the git URL for {} :\n".format(service))
                
            # This restarts the setup application
            subprocess.run(['./{}'.format(PATH_TO_FILE), service, robotClassName, 
                        robotRunInstructions, gitUrl])
    else:
        service = "robot"
        if service not in os.environ:
            service = "robot"
            subprocess.run(['./{}'.format(PATH_TO_FILE), service, robotClassName])
        
    # This restarts the setup application
    subprocess.run(['./{}'.format(PATH_TO_FILE), service])

    exit(0)

def queryUser(launch, choosingAction, shouldPrint = False):
    if shouldPrint : printInstructions(choosingAction)

    actionsToChoose = ' '.join(f' {i} ' for i in choosingAction)

    YELLOW = '\033[93m'
    ENDC = '\033[0m'  # ANSI code to reset formatting

    print(f"{YELLOW}Choose an action ({actionsToChoose}) to perform on one of the following services.\n" + \
           f"For further instructions enter '?'{ENDC}")

    num_to_service = {}
    service_names = set()
    i = 1
    for message in launch.getReadiness():
        print(f"{i} : {message}")
        # Extract the service name from the message
        service_name = message.split(" ")[0] 

        # Map the index to the service name 
        num_to_service[i] = service_name 

        service_names.add(service_name)

        i += 1

    userInput = input().strip().split(" ")

    if userInput[0] == '?' :
        return queryUser(launch, choosingAction, shouldPrint=True)
    
    elif userInput[0] == "-1" :
        return False    
    
    elif len(userInput) != 2:
        print("Invalid input format.")
        return True

    action, identifier = userInput[0], userInput[1]

    # The user had indicated they want to perform 
    # an action for all services
    if identifier.lower() == "all" :
        try :
            for service in service_names :
                choosingAction[action](service)
        except Exception as e :
            print (e)
    elif action in choosingAction:
        if identifier.isdigit() and int(identifier) in num_to_service:
            choosingAction[action](num_to_service[int(identifier)])  # Call the action with the appropriate service
        elif identifier in service_names:
            choosingAction[action](identifier)  # Call the action with the provided service name
        else:
            print("Invalid number or service name.")
    else:
        print("Invalid action.")

    return True
