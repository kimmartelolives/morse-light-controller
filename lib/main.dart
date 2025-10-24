import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Morse Light Controller',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MorseHomePage(),
    );
  }
}

class MorseHomePage extends StatefulWidget {
  const MorseHomePage({super.key});

  @override
  MorseHomePageState createState() => MorseHomePageState();
}

class MorseHomePageState extends State<MorseHomePage> {
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? writeCharacteristic;
  bool isScanning = false;
  StreamSubscription<List<ScanResult>>? scanSubscription;

  @override
  void initState() {
    super.initState();
    checkPermissions();
  }

  @override
  void dispose() {
    scanSubscription?.cancel();
    connectedDevice?.disconnect();
    super.dispose();
  }

  // ✅ Request permissions for Android 12+
  Future<void> checkPermissions() async {
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.location.request();
  }

  // ✅ Scan and connect to "Pico"
  Future<void> scanForPico() async {
    setState(() => isScanning = true);

    // Ensure Bluetooth is on
    final state = await FlutterBluePlus.adapterState.first;
    if (state != BluetoothAdapterState.on) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enable Bluetooth first.")),
      );
      setState(() => isScanning = false);
      return;
    }

    // Start scanning
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    scanSubscription = FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        debugPrint("Found device: ${r.device.platformName}");
        if (r.device.platformName.contains("Pico")) {
          await FlutterBluePlus.stopScan();
          setState(() => isScanning = false);

          final device = r.device;
          try {
            await device.connect(timeout: const Duration(seconds: 10));
          } catch (e) {
            debugPrint("Connection error: $e");
          }

          connectedDevice = device;

          // Discover services
          List<BluetoothService> services =
              await connectedDevice!.discoverServices();
          for (var service in services) {
            for (var c in service.characteristics) {
              if (c.properties.write) {
                writeCharacteristic = c;
                break;
              }
            }
          }

          setState(() {});
          break;
        }
      }
    }, onDone: () => setState(() => isScanning = false));
  }

  // ✅ Send letter to the device
  Future<void> sendLetter(String letter) async {
    if (writeCharacteristic != null) {
      await writeCharacteristic!.write(letter.codeUnits, withoutResponse: true);
      debugPrint("Sent $letter");
    } else {
      debugPrint("Write characteristic not found!");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Device not ready or missing characteristic")),
      );
    }
  }

  // ✅ Disconnect safely
  Future<void> disconnectDevice() async {
    await connectedDevice?.disconnect();
    setState(() {
      connectedDevice = null;
      writeCharacteristic = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Morse Light Controller")),
      body: connectedDevice == null
          ? Center(
              child: isScanning
                  ? const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 10),
                        Text("Scanning for Pico..."),
                      ],
                    )
                  : ElevatedButton.icon(
                      onPressed: scanForPico,
                      icon: const Icon(Icons.search),
                      label: const Text("Scan for Pico"),
                    ),
            )
          : Column(
              children: [
                const SizedBox(height: 10),
                Text(
                  "Connected to: ${connectedDevice!.platformName}",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                StreamBuilder<BluetoothConnectionState>(
                  stream: connectedDevice!.connectionState,
                  builder: (context, snapshot) {
                    final state = snapshot.data ??
                        BluetoothConnectionState.disconnected;
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Status: ${state.toString().split('.').last}",
                        style: TextStyle(
                          fontSize: 16,
                          color: state ==
                                  BluetoothConnectionState.connected
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    );
                  },
                ),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 6,
                    padding: const EdgeInsets.all(10),
                    children: List.generate(26, (index) {
                      String letter = String.fromCharCode(65 + index);
                      return Padding(
                        padding: const EdgeInsets.all(4),
                        child: ElevatedButton(
                          onPressed: () => sendLetter(letter),
                          child: Text(letter,
                              style: const TextStyle(fontSize: 20)),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
      floatingActionButton: connectedDevice != null
          ? FloatingActionButton(
              onPressed: disconnectDevice,
              backgroundColor: Colors.redAccent,
              child: const Icon(Icons.power_settings_new),
            )
          : null,
    );
  }
}
