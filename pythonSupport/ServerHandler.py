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

import requests, time
from urllib3.exceptions import InsecureRequestWarning
import warnings
warnings.simplefilter('ignore', InsecureRequestWarning)

class ServerHandler():
    def __init__(self, url, name, checker):
        self.session = requests.Session()
        self.session.verify = False
        self.ADDRESS = url
        self.name = name
        print(url)
        self.checker = checker
        self.setSpecifics()
    
    def setSpecifics(self):
        def foo(bar): pass
        
        # worker server does not have the method 
        # used by checkForRob..
        if "worker" in self.name:
            self.checkForRobotClassName = foo
    
    def requestReadiness(self):
        try:
            self.session.post(f"{self.ADDRESS}/readyreset", verify=False)
            time.sleep(2)

            self.session.post(f"{self.ADDRESS}/readyrequest", verify=False)
            self.checker.services[self.name]['active'] = True
        except Exception as e:
            print(f"ERROR at request: {e}")
            self.checker.services[self.name]['active'] = False
            print(f"The {self.name} server is not operational")

    def checkConnection(self):
        try:
            url = f"{self.ADDRESS}/readyInfo"
            response = self.session.get(url, verify=False)
            self.checkForReady(response.content)
            self.checker.services[self.name]['active'] = True
        except Exception as e:
            print(f"ERROR at connection: {e}")
            self.checker.services[self.name]['active'] = False
            print(f"The {self.name} server is not operational")

    def checkForReady(self, message):
        message = str(message)
        
        for key, _ in self.checker.services.items():
            if key in message:
                target = f"{key} is "
                index = message.find(target) + len(target)
                
                if "robot" in key:
                    self.checkForRobotClassName()

                ERROR_SIGNAL = "NOT"
                if message[index:index + len(ERROR_SIGNAL)] != ERROR_SIGNAL:
                    self.checker.services[key]['active'] = True
                else:
                    self.checker.services[key]['active'] = False

    def checkForRobotClassName(self):
        url = f"{self.ADDRESS}/coordinatorClassName"
        response = self.session.get(url, verify=False)
        content = dict(response.json()).get("message")
        if response.status_code == 200:
            self.checker.setcoordinatorClassName(content)

