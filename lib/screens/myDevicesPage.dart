import 'dart:async';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class MyDevicesPage2 extends StatefulWidget {
  final String userMobile;
  const MyDevicesPage2({super.key, required this.userMobile});

  @override
  State<MyDevicesPage2> createState() => _MyDevicesPageState2();
}

class _MyDevicesPageState2 extends State<MyDevicesPage2> {
  final dbRef = FirebaseDatabase.instance.ref();

  BluetoothDevice? _device;
  BluetoothCharacteristic? _rxChar; // write to ESP
  BluetoothCharacteristic? _txChar; // notify from ESP

  StreamSubscription<List<int>>? _notifySub;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSub;

  String _rxBuffer = "";
  bool _busy = false;
  bool _isLoading = false;

  // Must match your ESP32
  final Guid serviceUuid = Guid("000000FF-0000-1000-8000-00805F9B34FB");
  final Guid rxUuid = Guid("0000FF01-0000-1000-8000-00805F9B34FB"); // write
  final Guid txUuid = Guid("0000FF02-0000-1000-8000-00805F9B34FB"); // notify

  @override
  void initState() {
    super.initState();
    _initBluetoothListener();
    _initPermissions();
  }

  Future<void> _initPermissions() async {
    if (Platform.isAndroid) {
      await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();
    }
    // iOS handles permission via system popup on first BLE action
  }

  void _initBluetoothListener() {
    _adapterStateSub = FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.off) {
        _showPopup("Bluetooth Off", "Please turn on Bluetooth");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "My Device BLE",
          style: TextStyle(color: Colors.white, fontSize: 22),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/main.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 100),
            child: StreamBuilder(
              stream: dbRef.child("Devices/${widget.userMobile}").onValue,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                  return const Center(
                    child: Text("No Device Found", style: TextStyle(color: Colors.white)),
                  );
                }

                final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                final keys = data.keys.toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: keys.length,
                  itemBuilder: (context, i) {
                    final key = keys[i];
                    final device = data[key];

                    final status = device["st"] ?? "Inactive";
                    final testCount = device["testCount"] ?? 0;
                    final mac = device["mac"] ?? "";
                    final active = status.toLowerCase() == "active";

                    return InkWell(
                      onTap: () async {
                        if (!active) {
                          _showPopup("Status", "Please contact CEMD");
                          return;
                        }
                        if (testCount <= 0) {
                          _showPopup("Status", "Please Recharge");
                          return;
                        }
                        await _connectSendAndRead(mac, key);
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Device: $key"),
                              const SizedBox(height: 6),
                              Text(
                                active ? "Active | Remaining: $testCount" : "Inactive",
                                style: TextStyle(
                                  color: active ? Colors.green : Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text("Communicating with device…", style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _connectSendAndRead(String mac, String deviceName) async {
    if (_busy) return;
    _busy = true;
    _rxBuffer = "";
    _setLoading(true);

    try {
      await _connectToDevice(mac, deviceName);
      await _discoverServicesAndSetupNotify();
      await _sendCommand();

      // Give some time for response (adjust as needed)
      await Future.delayed(const Duration(seconds: 6));

      if (_rxBuffer.isEmpty) {
        _showPopup("No Response", "Device did not respond in time.");
      }
    } catch (e) {
      _showPopup("Error", e.toString());
    } finally {
      await _disconnectClean();
      _setLoading(false);
      _busy = false;
    }
  }

  Future<void> _connectToDevice(String mac, String deviceName) async {
    final isIOS = Platform.isIOS;

    if (isIOS) {
      // iOS → must scan and find by name
      BluetoothDevice? foundDevice;

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 7),
        androidUsesFineLocation: true,
      );

      await for (final results in FlutterBluePlus.scanResults) {
        for (final r in results) {
          if (r.device.name == deviceName || r.device.advName == deviceName) {
            foundDevice = r.device;
            break;
          }
        }
        if (foundDevice != null) break;
      }

      await FlutterBluePlus.stopScan();

      if (foundDevice == null) {
        throw Exception("Device '$deviceName' not found during scan");
      }

      _device = foundDevice;
    } else {
      // Android → can connect directly by MAC
      _device = BluetoothDevice.fromId(mac);
    }

    await _device!.connect(
      autoConnect: false,
      timeout: const Duration(seconds: 12),
    );

    // Request higher MTU (good practice)
    try {
      await _device!.requestMtu(185);
      await Future.delayed(const Duration(milliseconds: 400));
    } catch (_) {}
  }

  Future<void> _discoverServicesAndSetupNotify() async {
    if (_device == null) throw Exception("No device connected");

    final services = await _device!.discoverServices();

    BluetoothService? targetService;
    for (var s in services) {
      if (s.uuid == serviceUuid) {
        targetService = s;
        break;
      }
    }

    if (targetService == null) {
      throw Exception("Service not found: $serviceUuid");
    }

    BluetoothCharacteristic? rx;
    BluetoothCharacteristic? tx;

    for (var c in targetService.characteristics) {
      if (c.uuid == rxUuid) rx = c;
      if (c.uuid == txUuid) tx = c;
    }

    if (rx == null || tx == null) {
      throw Exception("RX or TX characteristic not found");
    }

    _rxChar = rx;
    _txChar = tx;

    // DEBUG: Print properties
    print("RX → write: ${rx.properties.write}, "
        "writeWithoutResponse: ${rx.properties.writeWithoutResponse}");
    print("TX → notify: ${tx.properties.notify}");

    // Enable notifications on TX (ESP sends data here)
    await _txChar!.setNotifyValue(true);

    // CRITICAL for iOS – wait for CoreBluetooth to activate notifications
    await Future.delayed(const Duration(milliseconds: 700));

    _notifySub?.cancel();
    _notifySub = _txChar!.lastValueStream.listen(
      _onDataReceived,
      onError: (e) => print("Notify error: $e"),
    );
  }

  Future<void> _sendCommand() async {
    if (_rxChar == null) return;

    const cmd = "a\r\n";
    final bytes = Uint8List.fromList(cmd.codeUnits);

    try {
      if (_rxChar!.properties.writeWithoutResponse) {
        await _rxChar!.write(bytes, withoutResponse: true);
        print("Sent without response");
      } else {
        await _rxChar!.write(bytes, withoutResponse: false);
        print("Sent with response");
      }
    } catch (e) {
      print("First write failed: $e");
      // Fallback
      try {
        await _rxChar!.write(bytes, withoutResponse: false);
        print("Fallback: sent with response");
      } catch (e2) {
        print("All write attempts failed: $e2");
        rethrow;
      }
    }
  }

  void _onDataReceived(List<int> data) {
    final chunk = String.fromCharCodes(data);
    print("Received chunk: '$chunk'");

    _rxBuffer += chunk;

    if (_rxBuffer.contains("\n")) {
      final result = _rxBuffer.trim();
      _rxBuffer = "";

      print("Full response: '$result'");

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("Test Result"),
          content: Text("Result:\n$result"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _disconnectClean() async {
    try {
      _notifySub?.cancel();
      _notifySub = null;

      await _txChar?.setNotifyValue(false);
      await _device?.disconnect();
    } catch (_) {}

    _device = null;
    _rxChar = null;
    _txChar = null;
  }

  void _showPopup(String title, String msg) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _setLoading(bool value) {
    if (!mounted) return;
    setState(() => _isLoading = value);
  }

  @override
  void dispose() {
    _notifySub?.cancel();
    _adapterStateSub?.cancel();
    _device?.disconnect();
    super.dispose();
  }
}