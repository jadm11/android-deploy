## README for Device List and App Deployment Script

### Introduction

This Bash script automates the process of listing attached Android devices and deploying an APK file to each device. It's particularly useful for mobile developers and QA teams who need to quickly test their apps on multiple devices.

### Prerequisites

- **Android SDK:** Ensure you have the Android SDK installed and configured on your system.
- **ADB (Android Debug Bridge):** Make sure ADB is added to your system's PATH.
- **Bash shell:** The script is designed to run in a Bash environment.

### Usage

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/your-repo.git
   ```
2. **Navigate to the script directory:**
   ```bash
   cd your-repo/script-directory
   ```
3. **Make the script executable (optional):**
   ```bash
   chmod +x device_list_and_app_deployment.sh
   ```
4. **Run the script:**
   ```bash
   ./device_list_and_app_deployment.sh
   ```

### How it works

1. **Lists attached devices:** The script uses the `adb devices` command to retrieve a list of Android devices connected to your computer.
2. **Creates device array:** The list of devices is converted into an array for easier iteration.
3. **Iterates over devices:** The script loops through each device ID in the array.
4. **Displays device ID:** The current device ID is printed to the console for information.
5. **Deploys app:** The script executes the `adb install` command with the specified device ID and APK file to install the app on the device.

### Customization

- **APK path:** Replace `your_app.apk` with the actual path to your app's APK file.
- **Additional commands:** You can add or modify commands within the script to perform other actions, such as pushing files to devices or executing shell commands.

### Example

```bash
./device_list_and_app_deployment.sh
```
This will list all attached Android devices and deploy the app specified in the script to each device.

### Note

- Ensure that your Android devices are connected and enabled for USB debugging.
- For more advanced usage or customization, refer to the Android Developer Documentation for ADB commands and options.
