#!/usr/bin/env bash

# Enable exit on error and unset variable usage
set -euo pipefail

# Function to display usage information
usage() {
    echo "Usage: $0 [-h] [-v] [-c] [-l logfile] [-f filter] [APK_FILE]"
    echo "  -h: Display this help message"
    echo "  -v: Enable verbose mode"
    echo "  -c: Continue on failure (don't exit if installation fails on a device)"
    echo "  -l logfile: Specify a custom log file (default: deployment.log)"
    echo "  -f filter: Filter devices based on Android version (e.g., '9', '10+'))"
    echo "  APK_FILE: Path to the APK file to install (default: your_app.apk)"
}

# Function to log messages with a timestamp
log() {
    local level="${1:-info}"
    local message="${2:-}"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")

    case "$level" in
        debug) color=blue ;;
        info) color=green ;;
        warning) color=yellow ;;
        error) color=red ;;
        *) color=white ;;
    esac

    printf "\033[1;${color}m[$timestamp] $level: $message\033[0m\n" >> "$LOG_FILE"

    if $VERBOSE; then
        printf "\033[1;${color}m[$timestamp] $level: $message\033[0m\n"
    fi
}

# Initialize variables
VERBOSE=false
CONTINUE_ON_FAILURE=false
LOG_FILE="deployment.log"
FILTER=""

# Parse command-line options
while getopts "hvcl:f:" opt; do
    case $opt in
        h) usage; exit 0 ;;
        v) VERBOSE=true ;;
        c) CONTINUE_ON_FAILURE=true ;;
        l) LOG_FILE="$OPTARG" ;;
        f) FILTER="$OPTARG" ;;
        \?) echo "Invalid option: -$OPTARG" >&2; usage; exit 1 ;;
    esac
done
shift $((OPTIND-1))

# Check if adb is available
if ! command -v adb &> /dev/null; then
    log error "adb command not found. Please ensure Android SDK is installed and added to PATH."
    exit 1
fi

# Specify the APK file (or use the first non-option argument)
APK_FILE="${1:-your_app.apk}"

# Check if the APK file exists
if [ ! -f "$APK_FILE" ]; then
    log error "APK file not found: $APK_FILE"
    exit 1
fi

# Function to filter devices based on Android version
filter_devices() {
    local device
    for device in "${array[@]}"; do
        local version=$(adb -s "$device" shell getprop ro.build.version.release)
        if [[ "$version" =~ ^$FILTER$ ]]; then
            echo "$device"
        fi
    done
}

# Get a list of attached Android devices
deviceLst=$(adb devices | awk 'NR > 1 {print $1}')

# Convert the device list into an array for easier iteration
read -a array <<< "$deviceLst"

# Check if any devices are connected
if [ ${#array[@]} -eq 0 ]; then
    log info "No devices connected. Please connect a device and try again."
    exit 1
fi

# Filter devices based on the specified filter
if [[ -n "$FILTER" ]]; then
    log info "Filtering devices by Android version: $FILTER"
    deviceLst=$(filter_devices)
    read -a array <<< "$deviceLst"
fi

# Prompt the user for confirmation before proceeding
log info "This script will deploy your app to the following devices:"
for element in "${array[@]}"; do
    log info "  - $element"
done

if [ -t 0 ]; then  # Only prompt if running interactively
    read -p "Are you sure you want to proceed? (y/n): " response
    if [[ "$response" != "y" ]]; then
        log warning "Aborting..."
        exit 1
    fi

    if ! $CONTINUE_ON_FAILURE; then
        read -p "Continue if installation fails on a device? (y/n): " response
        if [[ "$response" == "y" ]]; then
            CONTINUE_ON_FAILURE=true
        fi
    fi
fi

log info "Starting deployment of $APK_FILE"

# Iterate over each device ID and deploy the app
log info "Deploying app to ${#array[@]} devices"
for element in "${array[@]}"; do
    log debug "Installing on device: $element"
    adb -s "$element" install -r "$APK_FILE" >> "$LOG_FILE" 2>&1  # Redirect both stdout and stderr

    if [[ $? -ne 0 ]]; then
        log error "Error deploying app to device $element"
        if ! $CONTINUE_ON_FAILURE; then
            log error "Deployment failed. Check log file: $LOG_FILE"
            exit 1
        fi
    else
        log info "Successfully installed on device: $element"
    fi
done

# Print a success message if the app deployment completes
log info "App deployment completed!"
echo "See log file: $LOG_FILE"
