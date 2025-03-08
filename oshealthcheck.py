import os
import platform

# print(f"Processor: {platform.processor()}")
# print(f"Machine type: {platform.machine()}")
# print(f"Host network name: {platform.node()}")
# print(f"Host platform: {platform.platform()}")
# print(f"Host system: {platform.system()}")


def getOS():
    match platform.system().lower():
        case "linux":
            return "linux"
        case "darwin":
            return "darwin"
        case "mingw":
            return "windows"
        case "cygwin":
            return "windows"
        case _:
            return "unknown"


# Exit the script
def gracefulExit():
    print("Exiting... Goodbye!")
    exit()


# Printout script usage
def printUsage():
    print("\n")
    print("THIS SCRIPT OFFERS THE FOLLOWING OPTIONS:")
    print("\tSystem Information")
    print("\t\tShow information about current system")
    print("\tResources Utilization")
    print("\t\tShow current resources utilization (CPU,RAM,Disk,...)")
    print("\tSystem Services")
    print("\t\tShow current running services and processes")
    print("\tNetwork Status")
    print("\t\tShow network DNS configuration and networking services")
    print("\tGenerate report")
    print("\t\tGenerate a report folder include above information")
    print("\tClean up report")
    print("\t\tCleanup the report folder")
    print("\tCheck Usage")
    print("\t\tShow script usage")


# Clear the console screen.
def clearScreen():
    os.system("cls" if os.name == "nt" else "clear")


# Displays the menu options.
def displayMenu(options):
    print("Select a function: ")
    for i, option in enumerate(options):
        print(f"{i + 1}. {option}")


# Gets valid user input for the menu choice.
def getOption(num_options):
    while True:
        try:
            choice = int(input("Enter your choice: "))
            if 1 <= choice <= num_options:
                return choice
            else:
                print("Invalid choice. Please try again.")
        except ValueError:
            print("Invalid input. Please enter a number.")


# Processes the user's choice.
def processOption(choice, options, functions):
    # selected_option = options[choice - 1]
    # print(f"You selected: {selected_option}")

    # Call the corresponding function
    if choice <= len(functions):  # Ensure a function exists for the choice.
        functions[choice - 1]()  # Execute the function
    else:
        print("No function associated with this option.")
    input("Press Enter to continue...")


# Show information about current system
def systemCheck():
    match getOS():
        case "darwin":
            os.system("system_profiler SPHardwareDataType SPSoftwareDataType")
        case "linux":
            os.system("hostnamectl")
        case _:
            print("Unknown system architecture")


# Show current resources utilization (CPU,RAM,Disk,...)
def resourcesCheck():
    match getOS():
        case "darwin":
            os.system("system_profiler SPMemoryDataType")
            os.system("diskutil list")
        case "linux":
            os.system("free")
            os.system("df -hPT")
        case _:
            print("Unknown system architecture")


# Show current running services and processes
def servicesCheck():
    match getOS():
        case "darwin":
            os.system("launchctl list | grep -v '-'")
            os.system("ps aux")
        case "linux":
            os.system("systemctl --type=service --state=running")
            os.system("ps aux")
        case _:
            print("Unknown system architecture")


#  Show network DNS configuration and networking services
def networkCheck():
    match getOS():
        case "darwin":
            os.system("cat /etc/hosts")
            os.system("netstat -f inet -p tcp")
            os.system("cat /etc/resolv.conf")
        case "linux":
            os.system("cat /etc/hosts")
            os.system("netstat -t && netstat -ntlp -4")
            os.system("cat /etc/resolv.conf")
        case _:
            print("Unknown system architecture")


# Main loop for user's choices logic
menu_options = [
    "System Information",
    "Resources Utilization",
    "System Services",
    "Network Status",
    "Check Usage",
    "Exit",
]
menu_functions = [
    systemCheck,
    resourcesCheck,
    servicesCheck,
    networkCheck,
    printUsage,
    gracefulExit,
]

while True:
    displayMenu(menu_options)
    user_choice = getOption(len(menu_options))
    processOption(user_choice, menu_options, menu_functions)
