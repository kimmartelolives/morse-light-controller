## How It Works

The application performs the following steps:
1.  **Permissions**: On launch, it requests the necessary Bluetooth and location permissions required for BLE communication on modern Android and iOS devices.
2.  **Scanning**: The user initiates a scan for nearby BLE devices. The app specifically looks for a peripheral advertising the name "Pico".
3.  **Connection**: Upon finding the "Pico" device, the app stops scanning and attempts to establish a connection.
4.  **Service Discovery**: Once connected, it discovers the services and characteristics of the device, searching for a writable characteristic to send data.
5.  **Transmission**: The user interface displays a grid of buttons for each letter of the alphabet (A-Z). Tapping a button sends the corresponding character to the connected Pico device.
6.  **Disconnection**: A floating action button allows the user to safely disconnect from the peripheral.

The connected hardware (e.g., a Pico microcontroller) is responsible for receiving the character and executing the corresponding Morse code light pattern.

## Features

-   **BLE Scanning & Connection**: Automatically scans for and connects to a device named "Pico".
-   **Connection Status**: Displays the real-time connection state (e.g., connecting, connected, disconnecting).
-   **Simple UI**: A clean grid layout with buttons for all 26 letters of the English alphabet.
-   **Data Transmission**: Sends single-character commands to the connected BLE device.
-   **Safe Disconnection**: A dedicated button to terminate the BLE connection.

## Getting Started

### Prerequisites

-   Flutter SDK installed on your machine.
-   A target BLE device (e.g., Raspberry Pi Pico W) programmed to advertise as "Pico", accept BLE connections, and interpret incoming characters to flash an LED in Morse code.

### Installation

1.  **Clone the repository:**
    ```sh
    git clone https://github.com/kimmartelolives/morse-light-controller.git
    ```

2.  **Navigate to the project directory:**
    ```sh
    cd morse-light-controller
    ```

3.  **Install dependencies:**
    ```sh
    flutter pub get
    ```

4.  **Run the application:**
    ```sh
    flutter run
    ```

### Platform Configuration

The project is configured for multiple platforms. For BLE to function correctly, ensure the following settings are in place.

#### Android

The necessary permissions (`BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, `BLUETOOTH_ADVERTISE`, and `ACCESS_FINE_LOCATION`) are already included in `android/app/src/main/AndroidManifest.xml` to support Android 12 and newer.

#### iOS

Add the required Bluetooth permission descriptions to your `ios/Runner/Info.plist` file:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app needs Bluetooth to find and connect to the Morse code light device.</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app needs Bluetooth to communicate with the Morse code light device.</string>
```

#### macOS

To enable Bluetooth access on macOS, add the Bluetooth entitlement to `macos/Runner/DebugProfile.entitlements` and `macos/Runner/Release.entitlements`:

```xml
<key>com.apple.security.device.bluetooth</key>
<true/>
```

## Dependencies

-   [**flutter_blue_plus**](https://pub.dev/packages/flutter_blue_plus): Handles all Bluetooth Low Energy interactions.
-   [**permission_handler**](https://pub.dev/packages/permission_handler): Manages runtime permission requests for Bluetooth and location services.
