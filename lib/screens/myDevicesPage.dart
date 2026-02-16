// import 'dart:async';
// import 'dart:io' show Platform;
// import 'dart:typed_data';
//
// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// class MyDevicesPage2 extends StatefulWidget {
//   final String userMobile;
//   const MyDevicesPage2({super.key, required this.userMobile});
//
//   @override
//   State<MyDevicesPage2> createState() => _MyDevicesPageState2();
// }
//
// class _MyDevicesPageState2 extends State<MyDevicesPage2> {
//   final dbRef = FirebaseDatabase.instance.ref();
//
//   BluetoothDevice? _device;
//   BluetoothCharacteristic? _rxChar; // write to ESP
//   BluetoothCharacteristic? _txChar; // notify from ESP
//
//   StreamSubscription<List<int>>? _notifySub;
//   StreamSubscription<BluetoothAdapterState>? _adapterStateSub;
//
//   String _rxBuffer = "";
//   bool _busy = false;
//   bool _isLoading = false;
//
//   // Must match your ESP32
//   final Guid serviceUuid = Guid("000000FF-0000-1000-8000-00805F9B34FB");
//   final Guid rxUuid = Guid("0000FF01-0000-1000-8000-00805F9B34FB"); // write
//   final Guid txUuid = Guid("0000FF02-0000-1000-8000-00805F9B34FB"); // notify
//
//   @override
//   void initState() {
//     super.initState();
//     _initBluetoothListener();
//     _initPermissions();
//   }
//
//   Future<void> _initPermissions() async {
//     if (Platform.isAndroid) {
//       await [
//         Permission.bluetooth,
//         Permission.bluetoothScan,
//         Permission.bluetoothConnect,
//         Permission.location,
//       ].request();
//     }
//     // iOS handles permission via system popup on first BLE action
//   }
//
//   void _initBluetoothListener() {
//     _adapterStateSub = FlutterBluePlus.adapterState.listen((state) {
//       if (state == BluetoothAdapterState.off) {
//         _showPopup("Bluetooth Off", "Please turn on Bluetooth");
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         centerTitle: true,
//         title: const Text(
//           "My Device BLE",
//           style: TextStyle(color: Colors.white, fontSize: 22),
//         ),
//       ),
//       body: Stack(
//         children: [
//           Container(
//             decoration: const BoxDecoration(
//               image: DecorationImage(
//                 image: AssetImage("assets/images/main.png"),
//                 fit: BoxFit.cover,
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.only(top: 100),
//             child: StreamBuilder(
//               stream: dbRef.child("Devices/${widget.userMobile}").onValue,
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
//                   return const Center(
//                     child: Text("No Device Found", style: TextStyle(color: Colors.white)),
//                   );
//                 }
//
//                 final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
//                 final keys = data.keys.toList();
//
//                 return ListView.builder(
//                   padding: const EdgeInsets.all(12),
//                   itemCount: keys.length,
//                   itemBuilder: (context, i) {
//                     final key = keys[i];
//                     final device = data[key];
//
//                     final status = device["st"] ?? "Inactive";
//                     final testCount = device["testCount"] ?? 0;
//                     final mac = device["mac"] ?? "";
//                     final active = status.toLowerCase() == "active";
//
//                     return InkWell(
//                       onTap: () async {
//                         if (!active) {
//                           _showPopup("Status", "Please contact CEMD");
//                           return;
//                         }
//                         if (testCount <= 0) {
//                           _showPopup("Status", "Please Recharge");
//                           return;
//                         }
//                         await _connectSendAndRead(mac, key);
//                       },
//                       child: Card(
//                         margin: const EdgeInsets.only(bottom: 12),
//                         child: Padding(
//                           padding: const EdgeInsets.all(14),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text("Device: $key"),
//                               const SizedBox(height: 6),
//                               Text(
//                                 active ? "Active | Remaining: $testCount" : "Inactive",
//                                 style: TextStyle(
//                                   color: active ? Colors.green : Colors.redAccent,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//           if (_isLoading)
//             Container(
//               color: Colors.black.withOpacity(0.5),
//               child: const Center(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     CircularProgressIndicator(color: Colors.white),
//                     SizedBox(height: 16),
//                     Text("Communicating with device…", style: TextStyle(color: Colors.white)),
//                   ],
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _connectSendAndRead(String mac, String deviceName) async {
//     if (_busy) return;
//     _busy = true;
//     _rxBuffer = "";
//     _setLoading(true);
//
//     try {
//       await _connectToDevice(mac, deviceName);
//       await _discoverServicesAndSetupNotify();
//       await _sendCommand();
//
//       // // Give some time for response (adjust as needed)
//       // await Future.delayed(const Duration(seconds: 6));
//       //
//       // if (_rxBuffer.isEmpty) {
//       //   _showPopup("No Response", "Device did not respond in time.");
//       // }
//     } catch (e) {
//       _showPopup("Error", e.toString());
//       await _disconnectClean();
//     } finally {
//       // await _disconnectClean();
//       _setLoading(false);
//       _busy = false;
//     }
//   }
//
//   Future<void> _connectToDevice(String mac, String deviceName) async {
//     final isIOS = Platform.isIOS;
//
//     if (isIOS) {
//       // iOS → must scan and find by name
//       BluetoothDevice? foundDevice;
//
//       await FlutterBluePlus.startScan(
//         timeout: const Duration(seconds: 7),
//         androidUsesFineLocation: true,
//       );
//
//       await for (final results in FlutterBluePlus.scanResults) {
//         for (final r in results) {
//           if (r.device.name == deviceName || r.device.advName == deviceName) {
//             foundDevice = r.device;
//             break;
//           }
//         }
//         if (foundDevice != null) break;
//       }
//
//       await FlutterBluePlus.stopScan();
//
//       if (foundDevice == null) {
//         throw Exception("Device '$deviceName' not found during scan");
//       }
//
//       _device = foundDevice;
//     } else {
//       // Android → can connect directly by MAC
//       _device = BluetoothDevice.fromId(mac);
//     }
//
//     await _device!.connect(
//       autoConnect: false,
//       timeout: const Duration(seconds: 12),
//     );
//
//     // Request higher MTU (good practice)
//     try {
//       await _device!.requestMtu(185);
//       await Future.delayed(const Duration(milliseconds: 400));
//     } catch (_) {}
//   }
//
//   Future<void> _discoverServicesAndSetupNotify() async {
//     if (_device == null) throw Exception("No device connected");
//
//     final services = await _device!.discoverServices();
//
//     BluetoothService? targetService;
//     for (var s in services) {
//       if (s.uuid == serviceUuid) {
//         targetService = s;
//         break;
//       }
//     }
//
//     if (targetService == null) {
//       throw Exception("Service not found: $serviceUuid");
//     }
//
//     BluetoothCharacteristic? rx;
//     BluetoothCharacteristic? tx;
//
//     for (var c in targetService.characteristics) {
//       if (c.uuid == rxUuid) rx = c;
//       if (c.uuid == txUuid) tx = c;
//     }
//
//     if (rx == null || tx == null) {
//       throw Exception("RX or TX characteristic not found");
//     }
//
//     _rxChar = rx;
//     _txChar = tx;
//
//     // DEBUG: Print properties
//     print("RX → write: ${rx.properties.write}, "
//         "writeWithoutResponse: ${rx.properties.writeWithoutResponse}");
//     print("TX → notify: ${tx.properties.notify}");
//
//     // Enable notifications on TX (ESP sends data here)
//     await _txChar!.setNotifyValue(true);
//
//     // CRITICAL for iOS – wait for CoreBluetooth to activate notifications
//     await Future.delayed(const Duration(milliseconds: 700));
//
//     _notifySub?.cancel();
//     _notifySub = _txChar!.lastValueStream.listen(
//       _onDataReceived,
//       onError: (e) => print("Notify error: $e"),
//     );
//   }
//
//   Future<void> _sendCommand() async {
//     if (_rxChar == null) return;
//
//     const cmd = "a\r\n";
//     final bytes = Uint8List.fromList(cmd.codeUnits);
//
//     try {
//       if (_rxChar!.properties.writeWithoutResponse) {
//         await _rxChar!.write(bytes, withoutResponse: true);
//         print("Sent without response");
//       } else {
//         await _rxChar!.write(bytes, withoutResponse: false);
//         print("Sent with response");
//       }
//     } catch (e) {
//       print("First write failed: $e");
//       // Fallback
//       try {
//         await _rxChar!.write(bytes, withoutResponse: false);
//         print("Fallback: sent with response");
//       } catch (e2) {
//         print("All write attempts failed: $e2");
//         rethrow;
//       }
//     }
//   }
//
//   Future<void> _onDataReceived(List<int> data) async{
//     final chunk = String.fromCharCodes(data);
//     print("Received chunk: '$chunk'");
//
//     _rxBuffer += chunk;
//     // 🔥 Disconnect immediately when response received
//     await _disconnectClean();
//
//     if (!mounted) return;
//     if (_rxBuffer.contains("\n")) {
//       final result = _rxBuffer.trim();
//       _rxBuffer = "";
//
//       print("Full response: '$result'");
//
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (_) => AlertDialog(
//           title: const Text("Test Result"),
//           content: Text("Result:\n$result"),
//           actions: [
//             TextButton(
//               onPressed: () async {
//                 Navigator.pop(context);
//                 await _disconnectClean();   // 👈 disconnect here
//               },
//               child: const Text("OK"),
//             ),
//           ],
//         ),
//       );
//     }
//   }
//
//   Future<void> _disconnectClean() async {
//     try {
//       _notifySub?.cancel();
//       _notifySub = null;
//
//       await _txChar?.setNotifyValue(false);
//       await _device?.disconnect();
//     } catch (_) {}
//
//     _device = null;
//     _rxChar = null;
//     _txChar = null;
//   }
//
//   void _showPopup(String title, String msg) {
//     if (!mounted) return;
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: Text(title),
//         content: Text(msg),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("OK"),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _setLoading(bool value) {
//     if (!mounted) return;
//     setState(() => _isLoading = value);
//   }
//
//   @override
//   void dispose() {
//     _notifySub?.cancel();
//     _adapterStateSub?.cancel();
//     _device?.disconnect();
//     super.dispose();
//   }
// }



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
  BluetoothCharacteristic? _rxChar;
  BluetoothCharacteristic? _txChar;

  StreamSubscription<DatabaseEvent>? _testCountListener;
  Map<String, int> _lastKnownTestCount = {};





  StreamSubscription<List<int>>? _notifySub;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSub;

  String _rxBuffer = "";
  bool _busy = false;
  bool _isLoading = false;
  String selectedDeviceId ="";


  final Guid serviceUuid = Guid("000000FF-0000-1000-8000-00805F9B34FB");
  final Guid rxUuid = Guid("0000FF01-0000-1000-8000-00805F9B34FB");
  final Guid txUuid = Guid("0000FF02-0000-1000-8000-00805F9B34FB");

  @override
  void initState() {
    super.initState();
    _initPermissions();
    _initBluetoothListener();
    // _startDeviceListener();
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
  }

  void _initBluetoothListener() {
    _adapterStateSub =
        FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
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


        // 👇 Add this
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () async {
            final selected = await showMenu<String>(
              context: context,
              position: const RelativeRect.fromLTRB(0, 80, 0, 0),
              items: [
                const PopupMenuItem(
                  value: "home",
                  child: Row(
                    children: [
                      Icon(Icons.home, color: Colors.black),
                      SizedBox(width: 8),
                      Text("Home", style: TextStyle(color: Colors.black)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: "history",
                  child: Row(
                    children: [
                      Icon(Icons.history, color: Colors.black),
                      SizedBox(width: 8),
                      Text("Test History",
                          style: TextStyle(color: Colors.black)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: "device",
                  child: Row(
                    children: [
                      Icon(Icons.devices, color: Colors.black),
                      SizedBox(width: 8),
                      Text("My Device",
                          style: TextStyle(color: Colors.black)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: "doctor",
                  child: Row(
                    children: [
                      Icon(Icons.person, color: Colors.black),
                      SizedBox(width: 8),
                      Text("My Doctor",
                          style: TextStyle(color: Colors.black)),
                    ],
                  ),
                ),
              ],
            );

            if (selected == null) return;

            if (selected == "home") {
              Navigator.pushNamed(context, "/home");
            } else if (selected == "history") {
              Navigator.pushNamed(context, "/testHistory");
            } else if (selected == "device") {
              Navigator.pushNamed(context, "/myDevice");
            } else if (selected == "doctor") {
              Navigator.pushNamed(context, "/myDoctor");
            }
          },
        ),
        title: const Text(
          "My Device ",
          style: TextStyle(color: Colors.white, fontSize: 22),
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.add, color: Colors.blue),
                onPressed: () {
                  _showDeviceScanPopup();
                },

              ),
            ),
          ),
        ],
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
              stream: dbRef
                  .child("Devices/${widget.userMobile}")
                  .onValue,
              builder: (context, snapshot) {
                if (!snapshot.hasData ||
                    snapshot.data?.snapshot.value == null) {
                  return const Center(
                    child: Text("No Device Found",
                        style: TextStyle(color: Colors.white)),
                  );
                }

                final data = snapshot.data!.snapshot.value as Map<
                    dynamic,
                    dynamic>;
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

                        _listenToDeviceTestCount(key);
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
                                active
                                    ? "Active | Remaining: $testCount"
                                    : "Inactive",
                                style: TextStyle(
                                  color: active ? Colors.green : Colors
                                      .redAccent,
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
                    // Text("Communicating with device…", style: TextStyle(color: Colors.white)),
                    Text("Conecting with device…",
                        style: TextStyle(color: Colors.white)),
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
    _setLoading(true);
    _rxBuffer = "";

    try {
      selectedDeviceId =deviceName;
      await _connectToDevice(mac, deviceName);
      await _discoverServices();
      await _sendCommand();
    } catch (e) {
      _showPopup("Error", e.toString());
      await _disconnectClean();
    } finally {
      _setLoading(false);
      _busy = false;
    }
  }

  Future<void> _connectToDevice(String mac, String deviceName) async {
    if (Platform.isIOS) {
      BluetoothDevice? foundDevice;

      await FlutterBluePlus.startScan(
          timeout: const Duration(seconds: 7));

      await for (final results in FlutterBluePlus.scanResults) {
        for (final r in results) {
          if (r.device.name == deviceName ||
              r.device.advName == deviceName) {
            foundDevice = r.device;
            break;
          }
        }
        if (foundDevice != null) break;
      }

      await FlutterBluePlus.stopScan();

      if (foundDevice == null) {
        throw Exception("Device not found");
      }

      _device = foundDevice;
    } else {
      _device = BluetoothDevice.fromId(mac);
    }

    await _device!.connect(timeout: const Duration(seconds: 12));
  }

  Future<void> _discoverServices() async {
    final services = await _device!.discoverServices();

    final service =
    services.firstWhere((s) => s.uuid == serviceUuid);

    _rxChar = service.characteristics
        .firstWhere((c) => c.uuid == rxUuid);
    _txChar = service.characteristics
        .firstWhere((c) => c.uuid == txUuid);

    await _txChar!.setNotifyValue(true);

    _notifySub?.cancel();
    _notifySub =
        _txChar!.lastValueStream.listen(_onDataReceived);
  }

  Future<void> _sendCommand() async {
    const cmd = "a2\r\n";
    final bytes = Uint8List.fromList(cmd.codeUnits);

    await _rxChar!.write(
      bytes,
      withoutResponse:
      _rxChar!.properties.writeWithoutResponse,
    );
  }
  Future<void> _onDataReceived(List<int> data) async {
    final chunk = String.fromCharCodes(data);
    _rxBuffer += chunk;

    if (_rxBuffer.contains("\n")) {
      final rawResult = _rxBuffer.trim();
      _rxBuffer = "";

      String displayResult = rawResult;
      String refcesValue = "";

      // 🔹 Case 1: No Data Found
      if (rawResult == "No Data Found") {
        displayResult = "No Data Found";
      }

      // 🔹 Case 2: Format like "Absent_0.000000"
      else if (rawResult.contains("_")) {
        final parts = rawResult.split("_");

        displayResult = parts[0].trim();   // Only show text before "_"
        refcesValue =parts[1].trim();

        // 🔥 Update Firebase
        await _updateResultDB(displayResult,refcesValue);

        // 🔥 Update Firebase
        await _updateRealtimeDB();
      }

      // 🔥 Disconnect after processing
      await _disconnectClean();

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("Test Result"),
          content: Text(displayResult),  // Clean result shown
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  Future<int> _getTestCount() async {

    final testCountRef = dbRef
        .child("Devices")
        .child(widget.userMobile)
        .child(selectedDeviceId)
        .child("testCount");

    final snapshot = await testCountRef.get();

    if (snapshot.exists) {
      return (snapshot.value as num?)?.toInt() ?? 0;
    } else {
      return 0;
    }
  }

  // Future<void> _updateRealtimeDB(String result) async {
  //
  //   final userRef = dbRef.child("Devices/${widget.userMobile}/").child(selectedDeviceId);
  //
  //   final snapshot = await userRef.get();
  //
  //   if (snapshot.exists) {
  //     int currentCount = snapshot.child("testCount").value as int? ?? 0;
  //
  //     await userRef.update({
  //       "testCount": currentCount - 1,
  //     });
  //   }
  // }


  Future<void> _updateRealtimeDB() async {
    final testCountRef = dbRef
        .child("Devices")
        .child(widget.userMobile)
        .child(selectedDeviceId)
        .child("testCount");

    await testCountRef.runTransaction((currentData) {
      if (currentData == null) {
        return Transaction.success(0);
      }

      final currentCount = (currentData as num).toInt();

      if (currentCount > 0) {
        return Transaction.success(currentCount - 1);
      } else {
        return Transaction.success(0);
      }
    });
  }

  Future<void> _updateResultDB(String result,String refValue) async {

    // Create date-time key like: 09-12-25_11:39:00
    final now = DateTime.now();
    final formattedDate =
        "${now.day.toString().padLeft(2, '0')}-"
        "${now.month.toString().padLeft(2, '0')}-"
        "${now.year.toString().substring(2)}_"
        "${now.hour.toString().padLeft(2, '0')}:"
        "${now.minute.toString().padLeft(2, '0')}:"
        "${now.second.toString().padLeft(2, '0')}";

    int count = await _getTestCount();

    final resultRef = dbRef
        .child("Result")
        .child(widget.userMobile)
        .child(formattedDate);

    await resultRef.set({
      "count": count,
      "id": selectedDeviceId,
      "result": result,
      "volt":refValue,
    });
  }
  Future<void> _disconnectClean() async {
    try {
      await _notifySub?.cancel();
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
      builder: (_) =>
          AlertDialog(
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
    _testCountListener?.cancel();
    super.dispose();
  }

  Future<void> _saveDeviceToFirebase(String deviceID, String mac) async {
    final now = DateTime.now();

    String formattedDate =
        "${now.day.toString().padLeft(2, '0')}/"
        "${now.month.toString().padLeft(2, '0')}/"
        "${now.year.toString().substring(2)} "
        "${now.hour.toString().padLeft(2, '0')}:"
        "${now.minute.toString().padLeft(2, '0')}";

    await dbRef
        .child("Devices")
        .child(widget.userMobile)
        .child(deviceID)
        .set({
      "st": "Inactive",
      "testCount": 0,
      "mac": mac,
      "dt": formattedDate,
    });
  }

// 2️ helper functions go here

  void _showDeviceScanPopup() {
    List<ScanResult> foundDevices = [];
    bool isScanning = false;
    StreamSubscription<List<ScanResult>>? scanSubscription;

    void stopScan() {
      FlutterBluePlus.stopScan().catchError((_) {});
      scanSubscription?.cancel();
      scanSubscription = null;
      isScanning = false;
    }

    Future<void> startScan(StateSetter dialogSetState) async {
      // Optional: check Bluetooth state
      if (await FlutterBluePlus.adapterState.first ==
          BluetoothAdapterState.off) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enable Bluetooth")),
        );
        return;
      }

      foundDevices.clear();
      dialogSetState(() => isScanning = true);

      try {
        await FlutterBluePlus.startScan(
          timeout: const Duration(seconds: 12), // adjust as needed
          // Optional: withServices: [serviceUuid] if you want to filter by service
        );

        scanSubscription = FlutterBluePlus.scanResults.listen((results) {
          dialogSetState(() {
            for (var result in results) {
              final name = (result.device.name.isNotEmpty
                  ? result.device.name
                  : result.advertisementData.advName)
                  .trim();

              if (name.startsWith("SCINPY") &&
                  !foundDevices.any((d) =>
                  d.device.remoteId ==
                      result.device.remoteId)) {
                foundDevices.add(result);
              }
            }
          });
        });

        // Auto stop after timeout (already set in startScan)
        await Future.delayed(const Duration(seconds: 12));
        stopScan();
      } catch (e) {
        print("Scan error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Scan failed: $e")),
        );
      }
    }


    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, dialogSetState) {
            // Auto-start scan when dialog opens
            if (!isScanning && foundDevices.isEmpty &&
                scanSubscription == null) {
              Future.microtask(() => startScan(dialogSetState));
            }

            return WillPopScope(
              onWillPop: () async {
                stopScan();
                return true;
              },
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                titlePadding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
                contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                actionsPadding: const EdgeInsets.only(right: 12, bottom: 12),
                title: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Search New Devices",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () async {
                        if (isScanning) return;
                        stopScan();
                        dialogSetState(() => isScanning = true);
                        await startScan(dialogSetState);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          isScanning ? Icons.hourglass_empty : Icons.refresh,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 340,
                  child: isScanning && foundDevices.isEmpty
                      ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 20),
                        Text(
                          "Scanning for SCINPY devices...",
                          style: TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                  )
                      : foundDevices.isEmpty
                      ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bluetooth_searching,
                          size: 60,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          "No SCINPY devices found",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "Make sure the device is powered on and in pairing mode.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                      : ListView.separated(
                    itemCount: foundDevices.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final r = foundDevices[index];
                      final name = (r.device.name.isNotEmpty
                          ? r.device.name
                          : r.advertisementData.advName)
                          .trim();
                      final mac = r.device.remoteId.str;
                      final rssi = r.rssi;

                      return ListTile(
                        contentPadding:
                        const EdgeInsets.symmetric(vertical: 6),
                        leading: CircleAvatar(
                          radius: 20,
                          child: const Icon(Icons.bluetooth, size: 20),
                        ),
                        title: Text(
                          name.isEmpty ? "Unnamed Device" : name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "MAC: $mac\nRSSI: $rssi dBm",
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        isThreeLine: true,
                        onTap: () async {
                          stopScan();
                          Navigator.pop(dialogContext);

                          await _saveDeviceToFirebase(
                            name.isEmpty
                                ? "SCINPY_${mac.substring(mac.length - 6)}"
                                : name,
                            mac,
                          );

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              content: Text(
                                "${name.isEmpty ? "Device" : name} added!",
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    onPressed: () {
                      stopScan();
                      Navigator.pop(dialogContext);
                    },
                    child: const Text(
                      "Close",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            );
            // child: AlertDialog(
            //   title: Row(
            //     children: [
            //       const Expanded(
            //         child: Text("Search New Devices", textAlign: TextAlign.center),
            //       ),
            //       IconButton(
            //         icon: Icon(isScanning ? Icons.hourglass_empty : Icons.refresh),
            //         onPressed: () async {
            //           if (isScanning) return;
            //           stopScan();
            //           dialogSetState(() => isScanning = true);
            //           await startScan(dialogSetState);
            //         },
            //       ),
            //     ],
            //   ),
            //   content: SizedBox(
            //     width: double.maxFinite,
            //     height: 340,
            //     child: isScanning && foundDevices.isEmpty
            //         ? const Center(
            //       child: Column(
            //         mainAxisSize: MainAxisSize.min,
            //         children: [
            //           CircularProgressIndicator(),
            //           SizedBox(height: 16),
            //           Text("Scanning for SCINPY devices..."),
            //         ],
            //       ),
            //     )
            //         : foundDevices.isEmpty
            //         ? const Center(
            //       child: Column(
            //         mainAxisSize: MainAxisSize.min,
            //         children: [
            //           Icon(Icons.bluetooth_disabled, size: 64, color: Colors.grey),
            //           SizedBox(height: 16),
            //           Text("No SCINPY devices found"),
            //           SizedBox(height: 8),
            //           Text(
            //             "Make sure the device is on and in pairing mode.",
            //             textAlign: TextAlign.center,
            //           ),
            //         ],
            //       ),
            //     )
            //         : ListView.builder(
            //       itemCount: foundDevices.length,
            //       itemBuilder: (context, index) {
            //         final r = foundDevices[index];
            //         final name = (r.device.name.isNotEmpty
            //             ? r.device.name
            //             : r.advertisementData.advName)
            //             .trim();
            //         final mac = r.device.remoteId.str; // or .toString()
            //         final rssi = r.rssi;
            //
            //         return ListTile(
            //           leading: const Icon(Icons.bluetooth),
            //           title: Text(name.isEmpty ? "Unnamed Device" : name),
            //           subtitle: Text("MAC: $mac   RSSI: $rssi dBm"),
            //           onTap: () async {
            //             stopScan();
            //             Navigator.pop(dialogContext);
            //
            //             // Save to Firebase
            //             await _saveDeviceToFirebase(name.isEmpty ? "SCINPY_${mac.substring(mac.length - 6)}" : name, mac);
            //
            //             ScaffoldMessenger.of(context).showSnackBar(
            //               SnackBar(content: Text("$name added!")),
            //             );
            //
            //             // Optional: refresh your device list (StreamBuilder will auto-update)
            //           },
            //         );
            //       },
            //     ),
            //   ),
            //   actions: [
            //     TextButton(
            //       onPressed: () {
            //         stopScan();
            //         Navigator.pop(dialogContext);
            //       },
            //       child: const Text("Close"),
            //     ),
            //   ],
            // ),
            // );
          },
        );
      },
    ).then((_) {
      stopScan(); // final cleanup
    });
  }

  // void _startDeviceListener() {
  //   final mobile = widget.userMobile;
  //
  //   _deviceListener = dbRef
  //       .child("Devices/$mobile")
  //       .onValue
  //       .listen((event) {
  //
  //     if (!event.snapshot.exists) return;
  //
  //     final data =
  //     event.snapshot.value as Map<dynamic, dynamic>;
  //
  //     data.forEach((deviceId, deviceData) {
  //
  //       final currentTestCount =
  //           deviceData["testCount"] as int? ?? 0;
  //
  //       // First time just store value
  //       if (_lastKnownTestCount == null) {
  //         _lastKnownTestCount = currentTestCount;
  //         return;
  //       }
  //
  //       // 🔥 Detect change
  //       if (_lastKnownTestCount != currentTestCount) {
  //
  //         _lastKnownTestCount = currentTestCount;
  //
  //         showDialog(
  //           context: context,
  //           builder: (context) => AlertDialog(
  //             title: const Text("Notification"),
  //             content: Text(
  //                 "Test count changed to $currentTestCount"),
  //             actions: [
  //               TextButton(
  //                 onPressed: () {
  //                   Navigator.pop(context);
  //                 },
  //                 child: const Text("OK"),
  //               ),
  //             ],
  //           ),
  //         );
  //       }
  //     });
  //   });
  // }

  void _listenToDeviceTestCount(String deviceId) {
    final mobile = widget.userMobile;

    _testCountListener?.cancel(); // avoid multiple listeners

    _testCountListener = dbRef
        .child("Devices/$mobile/$deviceId/testCount")
        .onValue
        .listen((event) async {

      if (!event.snapshot.exists) return;

      final currentTestCount =
          event.snapshot.value as int? ?? 0;

      final previous =
      _lastKnownTestCount[deviceId];

      // First time for this device
      if (previous == null) {
        _lastKnownTestCount[deviceId] =
            currentTestCount;
        return;
      }

      // If changed → sync to BLE device
      if (previous != currentTestCount) {
        _lastKnownTestCount[deviceId] =
            currentTestCount;

        await _sendCounterCorrection(
            deviceId, currentTestCount);
      }
    });
  }


  Future<void> _sendCounterCorrection(
      String deviceId,
      int newTestCount,
      ) async {
    try {
      final macSnapshot = await dbRef
          .child("Devices")
          .child(widget.userMobile)
          .child(deviceId)
          .child("mac")
          .get();

      if (!macSnapshot.exists) return;

      final mac = macSnapshot.value.toString();

      await _connectToDevice(mac, deviceId);
      await _discoverServices();

      final command = "\$$newTestCount\r\n";
      final bytes = Uint8List.fromList(command.codeUnits);

      await _rxChar!.write(
        bytes,
        withoutResponse:
        _rxChar!.properties.writeWithoutResponse,
      );

      await Future.delayed(const Duration(milliseconds: 500));

      await _disconnectClean();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Update"),
          content: Text(
              "Device counter synced.\nRemaining Test Count: $newTestCount"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } catch (e) {
      await _disconnectClean();

      if (!mounted) return;

      _showPopup("Sync Failed", e.toString());
    }
  }







}



