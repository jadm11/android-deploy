# Device List and APK Deployment Script

### Automate the deployment of one or more APKs to connected Android devices with options for filtering devices, logging, and more.

## Overview

This script simplifies and automates the deployment of Android APK files to multiple connected devices. Designed for both local development and CI/CD environments, the script provides robust error handling, logging, and flexibility in deployment.

**Key Features:**

- Deploys one or more APKs to multiple Android devices.
- Supports device filtering based on Android version.
- Logs all activities for auditing and debugging.
- Performs health checks on devices (battery level, storage).
- Verifies installation post-deployment.
- Supports configuration via environment variables or a config file.
- Designed to run interactively or in CI/CD pipelines.

## Usage

```bash
./device_list_and_app_deployment.sh [-h] [-v] [-c] [-l logfile] [-f filter] [-d] [APK_FILE...]
```

### Options

- **`-h`**: Display this help message and exit.
- **`-v`**: Enable verbose mode for detailed output.
- **`-c`**: Continue on failure. If an APK installation fails on a device, continue with the next device.
- **`-l logfile`**: Specify a custom log file (default: `deployment.log`).
- **`-f filter`**: Filter devices based on Android version (e.g., `9`, `10+`).
- **`-d`**: List all attached devices and exit without deploying APKs.
- **`APK_FILE...`**: Path(s) to the APK file(s) to install.

### Environment Variables

- **`CONFIG_FILE`**: Path to a configuration file that can set default values for the script options.

### Example Commands

1. **Deploy a single APK to all connected devices:**
   ```bash
   ./device_list_and_app_deployment.sh your_app.apk
   ```

2. **Deploy multiple APKs to all connected devices:**
   ```bash
   ./device_list_and_app_deployment.sh app1.apk app2.apk app3.apk
   ```

3. **List all connected devices:**
   ```bash
   ./device_list_and_app_deployment.sh -d
   ```

4. **Filter devices running Android 10 or later and deploy APK:**
   ```bash
   ./device_list_and_app_deployment.sh -f 10+ your_app.apk
   ```

5. **Run in verbose mode with a custom log file:**
   ```bash
   ./device_list_and_app_deployment.sh -v -l custom_log.log your_app.apk
   ```

## Configuration File

You can use a configuration file to set default values for the script's options, making it easier to run the script without repeatedly specifying options.

### Example Configuration File (`config.env`)

```bash
# config.env

LOG_FILE="my_custom_log.log"
FILTER="9"
CONTINUE_ON_FAILURE=true
```

### Loading the Configuration

Specify the config file using the `CONFIG_FILE` environment variable:

```bash
CONFIG_FILE=config.env ./device_list_and_app_deployment.sh your_app.apk
```

## Health Checks

Before deployment, the script checks each device's battery level and storage capacity. Devices that do not meet the criteria (battery < 20%, storage < 1GB) are skipped to prevent deployment failures.

## Post-Deployment Verification

After the APK is installed, the script verifies the installation by checking if the package is listed on the device. This ensures that the deployment was successful.

## CI/CD Integration

The script is designed to run non-interactively, making it suitable for integration into CI/CD pipelines. It can be triggered with all necessary options passed as arguments or through a configuration file.

### Example GitLab CI/CD Pipeline

```yaml
stages:
  - deploy

deploy_app:
  stage: deploy
  script:
    - ./device_list_and_app_deployment.sh -v -c app1.apk app2.apk
  only:
    - main
```

## Logging

All operations are logged with timestamps and levels (debug, info, warning, error). Logs can be reviewed in the specified log file or sent to a centralized logging system.

### Log Example

```plaintext
[2024-09-01 08:50:39] info: Listing attached devices...
[2024-09-01 08:50:39] info: Deploying APK to 3 devices...
[2024-09-01 08:50:40] debug: Installing on device: emulator-5554
[2024-09-01 08:50:45] info: Successfully installed on device: emulator-5554
[2024-09-01 08:50:45] info: Deployment completed on all devices.
```