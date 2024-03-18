import subprocess, os, time
from pythonSupport.ServerHandler import ServerHandler

class Launcher () :
    def __init__ (self) :
        self.services = {
            "CLEAR_worker_server" : {"priority" : 1, "active" : False,
                               "environment" : "CLEAR_worker_server", 
                               "instruction" : "node server.js"},

            "CLEAR_interface_server" : {"priority" : 1, "active" : False,
                               "environment" : "CLEAR_interface_server", 
                               "instruction" : "node serverSecure.js"},

            "CLEAR_object_detection" : {"priority" : 2, "active" : False,
                               "environment" : "CLEAR_computer_vision",
                                 "instruction" : "python main.py"},

            "CLEAR_depth_perception" : {"priority" : 2, "active" : False,
                               "environment" : "CLEAR_computer_vision", 
                               "instruction" : "python main.py --type dep"},

            "CLEAR_llm_chat" : {"priority" : 2, "active" : False,
                               "environment" : "CLEAR_llm_chat", 
                               "instruction" : "python main.py"},

            "CLEAR_coordinator" : {"priority" : 3, "active" : False,
                               "environment" : "CLEAR_coordinator", 
                               "instruction" : "python main.py"},

            "CLEAR_robot" : {"priority" : 3, "active" : False,
                               "environment" : "", 
                               "instruction" : ""}
        }

        self.workerServer = ServerHandler(os.environ.get('WORKER_ADDRESS'),
                                          "CLEAR_worker_server", self)
        
        self.interfaceServer = ServerHandler(os.environ.get('INTERFACE_ADDRESS'),
                                             "CLEAR_interface_server", self)

    # Sets drone class used by running coordinator
    def setcoordinatorClassName(self, value):
        self.services["CLEAR_coordinator"]['instruction'] = "python main.py" + \
              f" --platform {value}"

    def queryTheServers(self):
        self.workerServer.requestReadiness()
        self.interfaceServer.requestReadiness()
        time.sleep(2)
        self.workerServer.checkConnection()
        self.interfaceServer.checkConnection()
        self.getReadiness()

    def canLaunch(self, service):
        service_priority = self.services.get(service, {}).get('priority', float('inf'))
        blocking_services = []
        
        for srv, info in self.services.items():
            if info['priority'] < service_priority and not info['active']:
                blocking_services.append(srv)

        return blocking_services

    def launchApp(self, service):
        # if service == self.robotName :
        #     service = "robot"
        
        blocking_services = self.canLaunch(service)

        if blocking_services:
            print(f"Cannot launch {service} as the following higher priority services are not active: {', '.join(blocking_services)}")
            return

        environment, command, service = self.getCommand(service)

        if command is None:
            print(f"No command found for service {service}.")
            return

        subprocess.run(['bash', './LaunchApp/LaunchApp.sh', environment, command, service ])

    def launchAllServices(self):
        # Sort services by their priority
        sorted_services = sorted(self.services.items(), key=lambda x: x[1]['priority'])

        for service, info in sorted_services:
            if self.canLaunch(service):
                self.launchApp(service)
                # Update the readiness status after launching (you may also want to actually check the status)
                print(f"{service} has been launched.")
            else:
                print(f"Cannot launch {service} as higher priority services are not active.")
            
    def stopApp(self, service):
        print ("Stopping the app called ", service)

        if service in ("CLEAR_object_detection", "CLEAR_depth_perception"):
            repo = "CLEAR_computer_vision"
            subprocess.run(['bash', './LaunchApp/stopApp.sh', 
                service, repo])
        else : 
            subprocess.run(['bash', './LaunchApp/stopApp.sh', 
                service])

    def getCommand(self, target):
        if target in self.services:
            service = self.services[target]
            instruction = service.get('instruction', None)
            envir = service.get('environment', None)

            print ("Command being returned {}, {}".format(envir, instruction))
            return envir, instruction, target
        
        print(f"Invalid service {service} does not exist.")
        return None    
    
    def getReadiness(self):
        self.queryTheServers()
        for service, info in self.services.items():
            if info["active"]:
                yield "{} is ready".format(service)
            else:
                yield "{} is not ready".format(service)