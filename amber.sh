#!/usr/bin/env bash
#
# Basic local firewall implementation via iptables to try to protect the host machine
# by allowing only the specific bidirectional traffic configured by the user.
#
# by Psycho (@UDPsycho)
#   https://www.twitter.com/UDPsycho
#

# Exit if any command fails
set -e

source resources/constants
source resources/functions


# Check if the script is running as root
if [[ "$(id -u)" -ne 0 ]]; then
    echo -e "\n${RED}[-]${RESET} Error: ${ITALIC}$0${RESET} must be ${RED}run as root${RESET}.\n" 1>&2
    exit 1
fi

# Check if iptables exists and execute permission is granted
if ! [[ -x "$(command -v iptables)" ]]; then
    echo -e "\n${RED}[-]${RESET} Error: ${ITALIC}iptables${RESET} must be ${RED}installed${RESET}.\n" 1>&2
    exit 1
fi


# Parse arguments
if [[ "$#" -eq 0 ]]; then

    only_localhost=true

elif [[ "$#" -eq 1 ]]; then

    case "$1" in
        "-h" | "--help")
            echo -e "${NAME} ${VERSION}\n"
            echo -e "Usage: $0 [OPTIONS]\n"
            echo "OPTIONS:"
            echo "    -h, --help          display this help and exit"
            echo "    -v, --version       display version and exit"
            echo "    -b, --banner        display banner and exit"
            echo "    -t, --tcp           use tcp configuration file"
            echo "    -u, --udp           use udp configuration file"
            echo "    -i, --icmp          use icmp configuration file"
            echo "    -a, --all           use all available configuration files"
            echo "    -c, --clear         restore iptables defaults (re-enable LAN/WAN connection)"
            echo "    -n, --no-warning    run the script without arguments but hiding the initial warning"
            echo "    -N, --no-color      don't use any color for bash output when applying the firewall rules"
            exit 0
        ;;
        "-v" | "--version")
            echo -e "${NAME} ${VERSION}"
            exit 0
        ;;
        "-b" | "--banner")
            display_banner
            exit 0
        ;;
        "-t" | "--tcp")
            tcp=true
        ;;
        "-u" | "--udp")
            udp=true
        ;;
        "-i" | "--icmp")
            icmp=true
        ;;
        "-a" | "--all")
            all_files=true
        ;;
        "-c" | "--clear")
            restore_defaults
            echo -e "${YELLOW}[i]${RESET} All rules have been restored to defaults."
            exit 0
        ;;
        "-n" | "--no-warning")
            only_localhost=false
        ;;
        "-N" | "--no-color")
            no_color=true
            only_localhost=true
        ;;
        *)
            echo -e "${RED}[-]${RESET} Error: Invalid argument ${ITALIC}$1${RESET}"
            exit 1
        ;;
    esac

else

    error_message="${RED}[-]${RESET} Error: Provided arguments can't be used combined or aren't valid."

    while test -n "$1"; do

        case "$1" in
            "-h" | "--help")       echo -e $error_message; exit 1; ;;
            "-v" | "--version")    echo -e $error_message; exit 1; ;;
            "-b" | "--banner")     echo -e $error_message; exit 1; ;;
            "-c" | "--clear")      echo -e $error_message; exit 1; ;;
            "-n" | "--no-warning") echo -e $error_message; exit 1; ;;
            "-a" | "--all")        all_files=true; shift ;;

            "-t" | "--tcp")
                tcp=true
                shift
            ;;
            "-u" | "--udp")
                udp=true
                shift
            ;;
            "-i" | "--icmp")
                icmp=true
                shift
            ;;
            "-N" | "--no-color")
                no_color=true
                shift
            ;;
            *)
                echo -e "${RED}[-]${RESET} Error: Invalid argument ${ITALIC}$1${RESET}"
                exit 1
            ;;
        esac

    done

fi


if [[ "$no_color" = true ]]; then
    disable_color
fi

display_banner

# Display current configuration options
if [[ "$only_localhost" = true ]]; then

    echo -e "${YELLOW}[i]${RESET} No configuration file has been set, default options will be used\n\
    (only localhost traffic, ${L_RED}no LAN/WAN connection!${RESET}).\n"

    seconds=10
    echo -e "    You have $seconds seconds to cancel this operation by pressing CTRL+C.\n"
    sleep $seconds

else

    if [[ "$all_files" = true ]]; then
        tcp=true; udp=true; icmp=true;
    fi

    aux_message="file added to current configuration options."
    seconds=1

    if [[ "$tcp" = true ]]; then
        echo -e "${GREEN}[+]${RESET} TCP $aux_message"
    fi

    if [[ "$udp" = true ]]; then
        echo -e "${GREEN}[+]${RESET} UDP $aux_message"
    fi

    if [[ "$icmp" = true ]]; then
        echo -e "${GREEN}[+]${RESET} ICMP $aux_message"
    fi

    sleep $seconds

fi


# "Catch" any error signal
trap restore_rules ERR


# Apply firewall rules
echo -e "\n${YELLOW}[i]${RESET} Applying firewall rules...\n"

    message="    ${GREEN}[+]${RESET} ${FAINT}Deleting${RESET} previous rules and counters."
    display_config_message "$message"
    delete_rules

    message="    ${GREEN}[+]${RESET} ${FAINT}Setting${RESET} default policies (${RED}$POLICY${RESET})."
    display_config_message "$message"
    set_default_policies

    message="    ${GREEN}[+]${RESET} ${FAINT}Allowing${RESET} any traffic from localhost to localhost (${L_CYAN}$LOCALHOST${RESET})."
    display_config_message "$message"
    allow_localhost

    message="    ${GREEN}[+]${RESET} ${FAINT}Allowing${RESET} any traffic from the local IP to local IP (${L_CYAN}$LOCAL_IP${RESET})."
    display_config_message "$message"
    allow_local_IP

    aux_message="configuration file"

    if [[ "$tcp" = true ]]; then
        message="    ${YELLOW}[i]${RESET} ${INVERT}Reading TCP ${aux_message}${RESET}"
        display_config_message "$message"
        apply_TCP_config
    fi

    if [[ "$udp" = true ]]; then
        message="    ${YELLOW}[i]${RESET} ${INVERT}Reading UDP ${aux_message}${RESET}"
        display_config_message "$message"
        apply_UDP_config
    fi

    if [[ "$icmp" = true ]]; then
        message="    ${YELLOW}[i]${RESET} ${INVERT}Reading ICMP ${aux_message}${RESET}"
        display_config_message "$message"
        apply_ICMP_config
    fi

    echo -e "\n    ${YELLOW}[i]${RESET} ${L_RED}Remember that all remaining traffic (not explicitly allowed) has been blocked!${RESET}"

echo -e "\n${YELLOW}[i]${RESET} Rules successfully applied.\n"

echo -e "\nThank you for using ${NAME}!\n"
