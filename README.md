## README for android-deploy

### Introduction

This Bash script (device_list_and_app_deployment.sh) automates the process of listing attached Android devices, filtering them based on Android version, and deploying an APK file to each selected device. 

### Prerequisites

- **Android SDK:** Ensure you have the Android SDK installed and configured on your system.
- **ADB (Android Debug Bridge):** Make sure ADB is added to your system's PATH.
- **Bash shell:** The script is designed to run in a Bash environment.

### Usage

1. **Clone the repository:**
   ```bash
   git clone git@github.com:jadm11/android-deploy.git
   ```
2. **Navigate to the script directory:**
   ```bash
   cd android-deploy
   ```
3. **Make the script executable (optional):**
   ```bash
   chmod +x device_list_and_app_deployment.sh
   ```
4. **Run the script with optional arguments:**
   ```bash
   ./device_list_and_app_deployment.sh [-h] [-v] [-c] [-l logfile] [-f filter] [APK_FILE]
   ```

### Command-Line Options

- **-h:** Displays help information and exits.
- **-v:** Enables verbose mode for more detailed output.
- **-c:** Continues deployment even if installation fails on a device.
- **-l logfile:** Specifies a custom log file (default: `deployment.log`).
- **-f filter:** Filters devices based on Android version (e.g., `9`, `10+`).
- **APK_FILE:** Path to the APK file to install (default: `your_app.apk`).

### How it works

1. **Checks prerequisites:** Verifies that `adb` is available and the APK file exists.
2. **Retrieves device list:** Obtains a list of attached Android devices using `adb devices`.
3. **Filters devices (optional):** If a filter is specified, filters the device list based on Android version.
4. **Prompts for confirmation:** Asks the user for confirmation before proceeding.
5. **Deploys app:** Iterates over each device in the filtered list and deploys the APK using `adb install`.
6. **Handles errors and logs:** Logs the deployment process, errors, and success messages to a log file.

### Example

```bash
./device_list_and_app_deployment.sh -v -f "9+" my_app.apk
```
This command will deploy the `my_app.apk` file to all connected Android devices with Android version 9 or higher, enabling verbose logging and continuing deployment even if errors occur.

### Note

- Ensure that your Android devices are connected and enabled for USB debugging.
- For more advanced usage or customization, refer to the Android Developer Documentation for ADB commands and options.
