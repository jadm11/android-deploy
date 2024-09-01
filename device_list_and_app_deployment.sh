#!/usr/bin/env bash

################################################################################
# Script Name: device_list_and_app_deployment.sh
# Description: Automates the deployment of one or more APKs to connected Android devices.
#              Provides options for filtering devices, logging, and verbose output.
#              Allows listing devices, and continuous deployment on failure.
#
# Author:      Jacob Adm 
# Date:        2024-09-01
# Version:     2.1
# License:     MIT License 
# 
# Usage:       ./<script_name>.sh [-h] [-v] [-c] [-l logfile] [-f filter] [-d] [APK_FILE...]
#
# Options:
#   -h          Display this help message
#   -v          Enable verbose mode
#   -c          Continue on failure (don't exit if installation fails on a device)
#   -l logfile  Specify a custom log file (default: deployment.log)
#   -f filter   Filter devices based on Android version (e.g., '9', '10+')
#   -d          List all attached devices and exit
#   APK_FILE... Path(s) to one or more APK files to install.
#
# Notes:       This script requires ADB (Android Debug Bridge) to be installed 
#              and accessible in the system's PATH.
#
# Disclaimer:  This script is provided "as is" without any warranty of any kind,
#              either express or implied. Use at your own risk.
################################################################################

set -euo pipefail  # Enforce strict error handling
IFS=$'\n\t'

# Global variables
CONFIG_FILE=""
VERBOSE=false
CONTINUE_ON_FAILURE=false
LOG_FILE="deployment.log"
FILTER=""
LIST_DEVICES=false

# Function to display usage information
usage() {
    echo "Usage: $0 [-h] [-v] [-c] [-l logfile] [-f filter] [-d] [APK_FILE...]"
    echo "  -h: Display this help message"
    echo "  -v: Enable verbose mode"
    echo "  -c: Continue on failure (don't exit if installation fails on a device)"
    echo "  -l logfile: Specify a custom log file (default: deployment.log)"
    echo "  -f filter: Filter devices based on Android version (e.g., '9', '10+')"
    echo "  -d: List all attached devices and exit"
    echo "  APK_FILE...: Path(s) to one or more APK files to install."
    echo ""
    echo "Environment variables:"
    echo "  CONFIG_FILE: Path to a configuration file with default settings"
}

# Function to load configuration from a file
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
    fi
}

# Function to set up logging
setup_logging() {
    LOG_FILE=${1:-deployment.log}
    exec > >(tee -a "$LOG_FILE") 2>&1  # Log stdout and stderr to a log file
}

# Function to log messages with a timestamp and level
log() {
    local level="${1:-info}"
    local message="${2:-}"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    case "$level" in
        debug) color="34" ;;  # Blue
        info) color="32" ;;   # Green
        warning) color="33" ;; # Yellow
        error) color="31" ;;   # Red
        *) color="37" ;;       # White
    esac
    printf "\033[1;${color}m[$timestamp] $level: $message\033[0m\n"
}

# Function to verify environment setup
check_environment() {
    if ! command -v adb &> /dev/null; then
        log error "adb command not found. Please install ADB and ensure it's in your PATH."
        exit 1
    fi
}

# Function to list all attached devices
list_devices() {
    log info "Listing attached devices..."
    local devices=$(adb devices -l | awk 'NR > 1 && $1 != "" {print $1}')
    if [ -z "$devices" ]; then
        log error "No devices connected."
        exit 1
    fi
    echo "$devices"
}

# Function to perform a device health check
check_device_health() {
    local device="$1"
    log debug "Checking health of device: $device"
    local battery_level=$(adb -s "$device" shell dumpsys battery | grep level | awk '{print $2}')
    local storage=$(adb -s "$device" shell df /data | tail -1 | awk '{print $4}')
    if [[ "$battery_level" -lt 20 ]]; then
        log warning "Device $device has low battery ($battery_level%). Skipping..."
        return 1
    elif [[ "$storage" -lt 1048576 ]]; then  # Check if free space is less than 1GB
        log warning "Device $device has low storage ($storage KB free). Skipping..."
        return 1
    fi
    return 0
}

# Function to filter devices based on Android version
filter_devices() {
    local device_list=("$@")
    local filtered_devices=()
    for device in "${device_list[@]}"; do
        local version=$(adb -s "$device" shell getprop ro.build.version.release)
        if [[ "$version" =~ ^$FILTER ]]; then
            filtered_devices+=("$device")
        fi
    done
    echo "${filtered_devices[@]}"
}

# Function to deploy APKs to devices in parallel
deploy_apks() {
    local devices=("$@")
    log info "Deploying APK(s) to ${#devices[@]} devices..."
    for device in "${devices[@]}"; do
        for apk in "${APK_FILES[@]}"; do
            if [[ ! -f "$apk" ]]; then
                log error "APK file not found: $apk"
                exit 1
            fi
            {
                log debug "Installing $apk on device: $device"
                if ! adb -s "$device" install -r "$apk"; then
                    log error "Failed to deploy $apk to device: $device"
                    $CONTINUE_ON_FAILURE || exit 1
                else
                    log info "Successfully installed $apk on device: $device"
                    verify_installation "$device" "$apk"
                fi
            } &
        done
    done
    wait  # Wait for all background processes to finish
    log info "Deployment completed on all devices."
}

# Function to verify installation on the device
verify_installation() {
    local device="$1"
    local apk="$2"
    local package_name=$(aapt dump badging "$apk" | awk -v FS="'" '/package: name=/{print $2}')
    if adb -s "$device" shell pm list packages | grep "$package_name" > /dev/null; then
        log info "Verified: $package_name is installed on $device"
    else
        log error "Verification failed: $package_name is not installed on $device"
        $CONTINUE_ON_FAILURE || exit 1
    fi
}

# Parse command-line options
while getopts "hvcl:f:d" opt; do
    case $opt in
        h) usage; exit 0 ;;                       # -h: Display help and exit
        v) VERBOSE=true ;;                        # -v: Enable verbose mode
        c) CONTINUE_ON_FAILURE=true ;;            # -c: Continue on failure
        l) LOG_FILE="$OPTARG" ;;                  # -l: Set custom log file
        f) FILTER="$OPTARG" ;;                    # -f: Set Android version filter
        d) LIST_DEVICES=true ;;                   # -d: List devices and exit
        \?) log error "Invalid option: -$OPTARG"; usage; exit 1 ;;
    esac
done
shift $((OPTIND-1))

# Set up logging
setup_logging "$LOG_FILE"

# Load configuration if CONFIG_FILE is set
load_config

# Check environment setup
check_environment

# If -d option is provided, list devices and exit
if $LIST_DEVICES; then
    list_devices
    exit 0
fi

# Specify the APK files (or check if they were provided)
APK_FILES=("$@")
if [ ${#APK_FILES[@]} -eq 0 ]; then
    log error "No APK files provided. Please specify at least one APK file for deployment."
    usage
    exit 1
fi

# Get list of attached devices
devices=($(adb devices | awk 'NR > 1 {print $1}'))

# Filter devices based on Android version if filter is set
if [[ -n "$FILTER" ]]; then
    log info "Filtering devices by Android version: $FILTER"
    devices=($(filter_devices "${devices[@]}"))
fi

# Perform health checks on all devices
healthy_devices=()
for device in "${devices[@]}"; do
    if check_device_health "$device"; then
        healthy_devices+=("$device")
    else
        log warning "Skipping device $device due to health check failure."
    fi
done

# Check if there are any healthy devices left
if [ ${#healthy_devices[@]} -eq 0 ]; then
    log error "No healthy devices available for deployment."
    exit 1
fi

# Confirm deployment with the user if running interactively
if [ -t 0 ]; then
    log info "This script will deploy your app(s) to the following healthy devices:"
    for device in "${healthy_devices[@]}"; do
        log info "  - $device"
    done
    read -p "Are you sure you want to proceed? (y/n): " response
    [[ "$response" != "y" ]] && log warning "Aborting..." && exit 1
fi

# Deploy APK(s) to healthy devices in parallel
deploy_apks "${healthy_devices[@]}"

# Final log message and cleanup
log info "App deployment completed successfully on all healthy devices!"
log info "Check the log file for detailed information: $LOG_FILE"

# Exit script cleanly
exit 0
