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
//   BluetoothCharacteristic? _rxChar;
//   BluetoothCharacteristic? _txChar;
//
//   StreamSubscription<List<int>>? _notifySub;
//   StreamSubscription<BluetoothAdapterState>? _adapterStateSub;
//
//   String _rxBuffer = "";
//   bool _busy = false;
//   bool _isLoading = false;
//   String selectedDeviceId = "";
//   bool _isConnecting = false; // 🔥 NEW
//
//   int? _pendingCounter;// 🔥 STORED COUNTER
//
//
//   final Map<String, int> _lastKnownTestCounts = {};
//
//
//   final Guid serviceUuid = Guid("000000FF-0000-1000-8000-00805F9B34FB");
//   final Guid rxUuid = Guid("0000FF01-0000-1000-8000-00805F9B34FB");
//   final Guid txUuid = Guid("0000FF02-0000-1000-8000-00805F9B34FB");
//
//   @override
//   void initState() {
//     super.initState();
//     _initPermissions();
//     _initBluetoothListener();
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
//   }
// // 🔥 Bluetooth listener for auto retry
//   void _initBluetoothListener() {
//     _adapterStateSub =
//         FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) async {
//           if (state == BluetoothAdapterState.off) {
//             _showPopup("Bluetooth Off", "Please turn on Bluetooth");
//           }
//
//           if (state == BluetoothAdapterState.on) {
//             if (_pendingCounter != null && selectedDeviceId.isNotEmpty) {
//               await _trySendPendingCounter();
//             }
//           }
//         });
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
//
//
//         // 👇 Add this
//         leading: IconButton(
//           icon: const Icon(Icons.menu, color: Colors.white),
//           onPressed: () async {
//             final selected = await showMenu<String>(
//               context: context,
//               position: const RelativeRect.fromLTRB(0, 80, 0, 0),
//               items: [
//                 const PopupMenuItem(
//                   value: "home",
//                   child: Row(
//                     children: [
//                       Icon(Icons.home, color: Colors.black),
//                       SizedBox(width: 8),
//                       Text("Home", style: TextStyle(color: Colors.black)),
//                     ],
//                   ),
//                 ),
//                 const PopupMenuItem(
//                   value: "history",
//                   child: Row(
//                     children: [
//                       Icon(Icons.history, color: Colors.black),
//                       SizedBox(width: 8),
//                       Text("Test History",
//                           style: TextStyle(color: Colors.black)),
//                     ],
//                   ),
//                 ),
//                 const PopupMenuItem(
//                   value: "device",
//                   child: Row(
//                     children: [
//                       Icon(Icons.devices, color: Colors.black),
//                       SizedBox(width: 8),
//                       Text("My Device",
//                           style: TextStyle(color: Colors.black)),
//                     ],
//                   ),
//                 ),
//                 const PopupMenuItem(
//                   value: "doctor",
//                   child: Row(
//                     children: [
//                       Icon(Icons.person, color: Colors.black),
//                       SizedBox(width: 8),
//                       Text("My Doctor",
//                           style: TextStyle(color: Colors.black)),
//                     ],
//                   ),
//                 ),
//               ],
//             );
//
//             if (selected == null) return;
//
//             if (selected == "home") {
//               Navigator.pushNamed(context, "/home");
//             } else if (selected == "history") {
//               Navigator.pushNamed(context, "/testHistory");
//             } else if (selected == "device") {
//               Navigator.pushNamed(context, "/myDevice");
//             } else if (selected == "doctor") {
//               Navigator.pushNamed(context, "/myDoctor");
//             }
//           },
//         ),
//         title: const Text(
//           "My Device ",
//           style: TextStyle(color: Colors.white, fontSize: 22),
//         ),
//
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 10),
//             child: CircleAvatar(
//               backgroundColor: Colors.white,
//               child: IconButton(
//                 icon: const Icon(Icons.add, color: Colors.blue),
//                 onPressed: () {
//                   _showDeviceScanPopup();
//                 },
//
//               ),
//             ),
//           ),
//         ],
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
//               stream: dbRef
//                   .child("Devices/${widget.userMobile}")
//                   .onValue,
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData ||
//                     snapshot.data?.snapshot.value == null) {
//                   return const Center(
//                     child: Text("No Device Found",
//                         style: TextStyle(color: Colors.white)),
//                   );
//                 }
//
//                 final data = snapshot.data!.snapshot.value as Map<
//                     dynamic,
//                     dynamic>;
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
//                     // 🔥 Detect testCount change
//                     WidgetsBinding.instance.addPostFrameCallback((_) async {
//                       final previous = _lastKnownTestCounts[key];
//
//                       if (previous != null) {
//                         final difference = (previous - testCount).abs();
//
//                         // Show popup only if difference is greater than 1
//                         if (difference > 1) {
//                           String formattedCount = testCount.toString().padLeft(
//                               3, '0');
//                           String cmd = "\$$formattedCount";
//                           await _connectSendAndRead(mac, key, cmd);
//                           // _showPopup(
//                           //   "Test Count Updated",
//                           //   "Device: $key\nOld: $previous\nNew: $testCount",
//                           // );
//                         }
//                       }
//
//                       _lastKnownTestCounts[key] = testCount;
//                     });
//
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
//                         // await _checkAndShowCountStatus(key);
//
//                         await _connectSendAndRead(mac, key, "a2");
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
//                                 active
//                                     ? "Active | Remaining: $testCount"
//                                     : "Inactive",
//                                 style: TextStyle(
//                                   color: active ? Colors.green : Colors
//                                       .redAccent,
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
//                     // Text("Communicating with device…", style: TextStyle(color: Colors.white)),
//                     Text("Conecting with device…",
//                         style: TextStyle(color: Colors.white)),
//                   ],
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//
//   // ==============================================================
//   // 🔥 COUNTER LOGIC (ONLY FOR $xxx)
//   // ==============================================================
//
//   Future<void> sendCounterCommand(int count) async {
//     _pendingCounter = count;
//
//     final state = await FlutterBluePlus.adapterState.first;
//
//     // Bluetooth OFF → just store
//     if (state != BluetoothAdapterState.on) {
//       print("Bluetooth OFF. Counter stored.");
//       return;
//     }
//
//     // Connected → send now
//     if (_device != null &&
//         _device!.connectionState == BluetoothConnectionState.connected &&
//         _rxChar != null) {
//       await _trySendPendingCounter();
//     } else {
//       print("Device not connected. Counter stored.");
//     }
//   }
//
//   Future<void> _trySendPendingCounter() async {
//     if (_pendingCounter == null) return;
//
//     // Check device connected
//     if (_device == null ||
//         _device!.connectionState != BluetoothConnectionState.connected ||
//         _rxChar == null) {
//       return;
//     }
//
//
//     try {
//       final formatted = _pendingCounter!.toString().padLeft(3, '0');
//       final command = "\$$formatted\r\n";
//       final bytes = Uint8List.fromList(command.codeUnits);
//
//       await _rxChar!.write(
//         bytes,
//         withoutResponse: _rxChar!.properties.writeWithoutResponse,
//       );
//
//       print("Counter sent successfully: $_pendingCounter");
//       _pendingCounter = null; // clear after success
//     } catch (e) {
//       print("Counter send failed: $e");
//     }
//   }
//
//   Future<void> _connectSendAndRead(String mac, String deviceName,String cmd) async {
//     if (_busy || _isConnecting) return;
//     _busy = true;
//     _setLoading(true);
//     _rxBuffer = "";
//
//     try {
//       selectedDeviceId = deviceName;
//
//       await _connectToDevice(mac, deviceName);
//       await _discoverServices();
//       await _sendCommand(cmd);
//     } catch (e) {
//       _showPopup("Error", e.toString());
//       await _disconnectClean();
//     } finally {
//       _setLoading(false);
//       _busy = false;
//     }
//   }
//
//   // ==============================================================
//   // 🔥 CONNECTION
//   // ==============================================================
//
//   Future<void> _connectToDevice(String mac, String deviceName) async {
//     if (_isConnecting) return;
//     _isConnecting = true;
//
//     try {
//       // 🔹 Ensure Bluetooth is ON
//       // await FlutterBluePlus.adapterState.firstWhere(
//       //       (state) => state == BluetoothAdapterState.on,
//       // );
//
//       final state = await FlutterBluePlus.adapterState.first;
//       if (state != BluetoothAdapterState.on) {
//         _showPopup("Bluetooth Off", "Please turn on Bluetooth.");
//         return;
//       }
//
//       // 🔹 Always disconnect old connection (important for 133)
//       if (_device != null) {
//         try {
//           await _device!.disconnect();
//           await Future.delayed(const Duration(milliseconds: 500));
//         } catch (_) {}
//       }
//       if (Platform.isIOS) {
//         BluetoothDevice? foundDevice;
//
//         await FlutterBluePlus.startScan(
//             timeout: const Duration(seconds: 7));
//
//         await for (final results in FlutterBluePlus.scanResults) {
//           for (final r in results) {
//             if (r.device.name == deviceName ||
//                 r.device.advName == deviceName) {
//               foundDevice = r.device;
//               break;
//             }
//           }
//           if (foundDevice != null) break;
//         }
//
//         await FlutterBluePlus.stopScan();
//
//         if (foundDevice == null) {
//           throw Exception("Device not found");
//         }
//
//         _device = foundDevice;
//       } else {
//         _device = BluetoothDevice.fromId(mac);
//       }
//
//       // await _device!.connect(timeout: const Duration(seconds: 800));
//       await _device!.connect(
//         timeout: const Duration(seconds: 12),
//         autoConnect: false,
//       );
//       await _discoverServices();
//
//       // 🔥 After connection → try sending stored counter
//       await _trySendPendingCounter();
//     }
//     // catch (e) {
//     //   // 🔥 Retry once (fix for Android 133)
//     //   try {
//     //     await _device?.disconnect();
//     //     await Future.delayed(const Duration(seconds: 1));
//     //
//     //     await _device!.connect(
//     //       timeout: const Duration(seconds: 12),
//     //       autoConnect: false,
//     //     );
//     //   } catch (e) {
//     //     // throw Exception("Failed to connect: $e");
//     //     throw Exception("Device not found.\nPlease check if the device is available and turned on.");
//     //   }
//     catch (e) {
//       _showPopup("Connection Error", "Device not found or unreachable.");
//     } finally {
//       _isConnecting = false;
//     }
//   }
//
//   Future<void> _discoverServices() async {
//     final services = await _device!.discoverServices();
//     // _isDeviceReady = false;
//     final service = services.firstWhere(
//           (s) => s.uuid == serviceUuid,
//       orElse: () => throw Exception("Service not found"),
//     );
//
//     _rxChar = service.characteristics.firstWhere(
//           (c) => c.uuid == rxUuid,
//       orElse: () => throw Exception("RX not found"),
//     );
//
//     _txChar = service.characteristics.firstWhere(
//           (c) => c.uuid == txUuid,
//       orElse: () => throw Exception("TX not found"),
//     );
//
//     await _txChar!.setNotifyValue(true);
//
//     _notifySub?.cancel();
//     _notifySub = _txChar!.lastValueStream.listen(_onDataReceived);
//   }
//   Future<void> _sendCommand(String com) async {
//     // const cmd = "a2\r\n";
//     final cmd = com + "\r\n";
//     final bytes = Uint8List.fromList(cmd.codeUnits);
//
//     await _rxChar!.write(
//       bytes,
//       withoutResponse:
//       _rxChar!.properties.writeWithoutResponse,
//     );
//   }
//
//   Future<void> _onDataReceived(List<int> data) async {
//     final chunk = String.fromCharCodes(data);
//     _rxBuffer += chunk;
//
//     if (_rxBuffer.contains("\n")) {
//       final rawResult = _rxBuffer.trim();
//       _rxBuffer = "";
//
//       print("Device RESPONSE => [$rawResult]");
//
//       // 🔥 1️⃣ Handle Stored Counter FIRST
//       if (rawResult.contains("Stored Counter")) {
//         print("Counter stored successfully on device");
//
//         await _disconnectClean();
//         _pendingCounter = null;
//         return; // 🚫 absolutely stop
//       }
//
//       String displayResult = rawResult;
//       String refcesValue = "";
//
//       // 🔹 No Data Found
//       if (rawResult == "No Data Found") {
//         displayResult = "No Data Found";
//       }
//
//       // 🔹 Only treat as test result if format is EXACTLY like Result_Value
//       else if (rawResult.contains("_") &&
//           !rawResult.contains("Stored Counter")) {
//         final parts = rawResult.split("_");
//
//         displayResult = parts[0].trim();
//         refcesValue = parts.length > 1 ? parts[1].trim() : "";
//
//         await _updateResultDB(displayResult, refcesValue);
//         await _updateRealtimeDB(); // 🔥 decrease only here
//       }
//
//       await _disconnectClean();
//
//       if (!mounted) return;
//
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (_) =>
//             AlertDialog(
//               title: const Text("Test Result"),
//               content: Text(displayResult),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: const Text("OK"),
//                 ),
//               ],
//             ),
//       );
//     }
//   }
//
//
//   Future<int> _getTestCount() async {
//     final testCountRef = dbRef
//         .child("Devices")
//         .child(widget.userMobile)
//         .child(selectedDeviceId)
//         .child("testCount");
//
//     final snapshot = await testCountRef.get();
//
//     if (snapshot.exists) {
//       return (snapshot.value as num?)?.toInt() ?? 0;
//     } else {
//       return 0;
//     }
//   }
//
//   Future<void> _updateRealtimeDB() async {
//     final testCountRef = dbRef
//         .child("Devices")
//         .child(widget.userMobile)
//         .child(selectedDeviceId)
//         .child("testCount");
//
//     await testCountRef.runTransaction((currentData) {
//       if (currentData == null) {
//         return Transaction.success(0);
//       }
//
//       final currentCount = (currentData as num).toInt();
//
//       if (currentCount > 0) {
//         return Transaction.success(currentCount - 1);
//       } else {
//         return Transaction.success(0);
//       }
//     });
//   }
//
//   Future<void> _updateResultDB(String result, String refValue) async {
//     // Create date-time key like: 09-12-25_11:39:00
//     final now = DateTime.now();
//     final formattedDate =
//         "${now.day.toString().padLeft(2, '0')}-"
//         "${now.month.toString().padLeft(2, '0')}-"
//         "${now.year.toString().substring(2)}_"
//         "${now.hour.toString().padLeft(2, '0')}:"
//         "${now.minute.toString().padLeft(2, '0')}:"
//         "${now.second.toString().padLeft(2, '0')}";
//
//     int count = await _getTestCount();
//
//     final resultRef = dbRef
//         .child("Result")
//         .child(widget.userMobile)
//         .child(formattedDate);
//
//     await resultRef.set({
//       "count": count,
//       "id": selectedDeviceId,
//       "result": result,
//       "volt": refValue,
//     });
//   }
//
//   Future<void> _disconnectClean() async {
//     try {
//       await _notifySub?.cancel();
//       // await _txChar?.setNotifyValue(false);
//       // await _device?.disconnect();
//       if (_txChar != null) {
//         await _txChar!.setNotifyValue(false);
//       }
//
//       if (_device != null) {
//         await _device!.disconnect();
//         await Future.delayed(const Duration(milliseconds: 300));
//       }
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
//       builder: (_) =>
//           AlertDialog(
//             title: Text(title),
//             content: Text(msg),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text("OK"),
//               ),
//             ],
//           ),
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
//
//   Future<void> _saveDeviceToFirebase(String deviceID, String mac) async {
//     final now = DateTime.now();
//
//     String formattedDate =
//         "${now.day.toString().padLeft(2, '0')}/"
//         "${now.month.toString().padLeft(2, '0')}/"
//         "${now.year.toString().substring(2)} "
//         "${now.hour.toString().padLeft(2, '0')}:"
//         "${now.minute.toString().padLeft(2, '0')}";
//
//     await dbRef
//         .child("Devices")
//         .child(widget.userMobile)
//         .child(deviceID)
//         .set({
//       "st": "Inactive",
//       "testCount": 0,
//       "mac": mac,
//       "dt": formattedDate,
//     });
//   }
//
// // 2️ helper functions go here
//
//   void _showDeviceScanPopup() {
//     List<ScanResult> foundDevices = [];
//     bool isScanning = false;
//     StreamSubscription<List<ScanResult>>? scanSubscription;
//
//     void stopScan() {
//       FlutterBluePlus.stopScan().catchError((_) {});
//       scanSubscription?.cancel();
//       scanSubscription = null;
//       isScanning = false;
//     }
//
//     Future<void> startScan(StateSetter dialogSetState) async {
//       // Optional: check Bluetooth state
//       if (await FlutterBluePlus.adapterState.first ==
//           BluetoothAdapterState.off) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Please enable Bluetooth")),
//         );
//         return;
//       }
//
//       foundDevices.clear();
//       dialogSetState(() => isScanning = true);
//
//       try {
//         await FlutterBluePlus.startScan(
//           timeout: const Duration(seconds: 12), // adjust as needed
//           // Optional: withServices: [serviceUuid] if you want to filter by service
//         );
//
//         scanSubscription = FlutterBluePlus.scanResults.listen((results) {
//           dialogSetState(() {
//             for (var result in results) {
//               final name = (result.device.name.isNotEmpty
//                   ? result.device.name
//                   : result.advertisementData.advName)
//                   .trim();
//
//               if (name.startsWith("SCINPY") &&
//                   !foundDevices.any((d) =>
//                   d.device.remoteId ==
//                       result.device.remoteId)) {
//                 foundDevices.add(result);
//               }
//             }
//           });
//         });
//
//         // Auto stop after timeout (already set in startScan)
//         await Future.delayed(const Duration(seconds: 12));
//         stopScan();
//       } catch (e) {
//         print("Scan error: $e");
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Scan failed: $e")),
//         );
//       }
//     }
//
//
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (dialogContext) {
//         return StatefulBuilder(
//           builder: (ctx, dialogSetState) {
//             // Auto-start scan when dialog opens
//             if (!isScanning && foundDevices.isEmpty &&
//                 scanSubscription == null) {
//               Future.microtask(() => startScan(dialogSetState));
//             }
//
//             return WillPopScope(
//               onWillPop: () async {
//                 stopScan();
//                 return true;
//               },
//               child: AlertDialog(
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 titlePadding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
//                 contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
//                 actionsPadding: const EdgeInsets.only(right: 12, bottom: 12),
//                 title: Row(
//                   children: [
//                     const Expanded(
//                       child: Text(
//                         "Search New Devices",
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                     InkWell(
//                       borderRadius: BorderRadius.circular(30),
//                       onTap: () async {
//                         if (isScanning) return;
//                         stopScan();
//                         dialogSetState(() => isScanning = true);
//                         await startScan(dialogSetState);
//                       },
//                       child: Padding(
//                         padding: const EdgeInsets.all(8.0),
//                         child: Icon(
//                           isScanning ? Icons.hourglass_empty : Icons.refresh,
//                           size: 22,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 content: SizedBox(
//                   width: double.maxFinite,
//                   height: 340,
//                   child: isScanning && foundDevices.isEmpty
//                       ? const Center(
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         CircularProgressIndicator(),
//                         SizedBox(height: 20),
//                         Text(
//                           "Scanning for SCINPY devices...",
//                           style: TextStyle(fontSize: 15),
//                         ),
//                       ],
//                     ),
//                   )
//                       : foundDevices.isEmpty
//                       ? const Center(
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(
//                           Icons.bluetooth_searching,
//                           size: 60,
//                           color: Colors.grey,
//                         ),
//                         SizedBox(height: 16),
//                         Text(
//                           "No SCINPY devices found",
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                         SizedBox(height: 6),
//                         Text(
//                           "Make sure the device is powered on and in pairing mode.",
//                           textAlign: TextAlign.center,
//                           style: TextStyle(color: Colors.grey),
//                         ),
//                       ],
//                     ),
//                   )
//                       : ListView.separated(
//                     itemCount: foundDevices.length,
//                     separatorBuilder: (_, __) => const Divider(height: 1),
//                     itemBuilder: (context, index) {
//                       final r = foundDevices[index];
//                       final name = (r.device.name.isNotEmpty
//                           ? r.device.name
//                           : r.advertisementData.advName)
//                           .trim();
//                       final mac = r.device.remoteId.str;
//                       final rssi = r.rssi;
//
//                       return ListTile(
//                         contentPadding:
//                         const EdgeInsets.symmetric(vertical: 6),
//                         leading: CircleAvatar(
//                           radius: 20,
//                           child: const Icon(Icons.bluetooth, size: 20),
//                         ),
//                         title: Text(
//                           name.isEmpty ? "Unnamed Device" : name,
//                           style: const TextStyle(
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                         subtitle: Padding(
//                           padding: const EdgeInsets.only(top: 4),
//                           child: Text(
//                             "MAC: $mac\nRSSI: $rssi dBm",
//                             style: const TextStyle(fontSize: 12),
//                           ),
//                         ),
//                         isThreeLine: true,
//                         onTap: () async {
//                           stopScan();
//                           Navigator.pop(dialogContext);
//
//                           await _saveDeviceToFirebase(
//                             name.isEmpty
//                                 ? "SCINPY_${mac.substring(mac.length - 6)}"
//                                 : name,
//                             mac,
//                           );
//
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                               behavior: SnackBarBehavior.floating,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               content: Text(
//                                 "${name.isEmpty ? "Device" : name} added!",
//                               ),
//                             ),
//                           );
//                         },
//                       );
//                     },
//                   ),
//                 ),
//                 actions: [
//                   TextButton(
//                     style: TextButton.styleFrom(
//                       padding: const EdgeInsets.symmetric(horizontal: 20),
//                     ),
//                     onPressed: () {
//                       stopScan();
//                       Navigator.pop(dialogContext);
//                     },
//                     child: const Text(
//                       "Close",
//                       style: TextStyle(fontWeight: FontWeight.w500),
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     ).then((_) {
//       stopScan(); // final cleanup
//     });
//   }
// }
//



import 'dart:async';
import 'dart:io' ;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'testHistory.dart';
import 'user_model.dart';

import 'mydoctor.dart';
import 'myprofile.dart';
import 'test_count_screen.dart';

class MyDevicesPage2 extends StatefulWidget {
  // final String userMobile;
  final UserModel user;
  // const MyDevicesPage2({super.key, required this.userMobile});
  const MyDevicesPage2({
    super.key,
    required this.user,
  });

  @override
  State<MyDevicesPage2> createState() => _MyDevicesPageState2();
}

class _MyDevicesPageState2 extends State<MyDevicesPage2> {
  final dbRef = FirebaseDatabase.instance.ref();

  BluetoothDevice? _device;
  BluetoothCharacteristic? _rxChar;
  BluetoothCharacteristic? _txChar;
  StreamSubscription<List<int>>? _notifySub;

  bool _isLoading = false;
  bool _busy = false;
  bool _isConnecting = false;

  String selectedDeviceId = "";
  String _rxBuffer = "";

  final Map<String, int> _previousCounts = {};
  List<Map<String, dynamic>> updatedNewTest = [];
  StreamSubscription<DatabaseEvent>? _deviceListener;
  StreamSubscription<List<ScanResult>>? _scanSub;
  Set<String> _syncingDevices = {};
  Map<String, DateTime> _lastSyncAttempt = {};
  List<Map<String, dynamic>> pendingResults = [];

  final Guid serviceUuid = Guid("000000FF-0000-1000-8000-00805F9B34FB");
  final Guid rxUuid = Guid("0000FF01-0000-1000-8000-00805F9B34FB");
  final Guid txUuid = Guid("0000FF02-0000-1000-8000-00805F9B34FB");


  @override
  void initState() {
    super.initState();
    _initPermissions();
    _startupValidation();
    _loadPendingUpdates();
    _listenToDevices();
    syncPendingResults();
  }

  /* -------------------- STARTUP VALIDATION -------------------- */

  Future<void> _startupValidation() async {
    _setLoading(true);

    bool hasInternet = await _checkInternetConnection();

    if (!hasInternet) {
      _setLoading(false);
      _showPopup("No Internet", "Please check your internet connection.");
      return;
    }

    final snapshot =
    await dbRef.child("Devices/${widget.user.mobile}").get();

    if (!snapshot.exists) {
      _setLoading(false);
      _showPopup("No Devices", "No devices found for this user.");
      return;
    }

    _setLoading(false);
    _listenToDevices();
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty &&
          result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
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

  Future<void> _loadPendingUpdates() async {
    final snapshot = await dbRef.child("Devices/${widget.user.mobile}").get();

    if (!snapshot.exists) return;

    final data = Map<String, dynamic>.from(snapshot.value as Map);

    for (var entry in data.entries) {
      final deviceId = entry.key;
      final device = entry.value as Map;
      final status = device["st"].toString().toLowerCase();
      if (status != "active") continue;
      final currentCount = device["testCount"] as int;
      final oldCount = await getLatestOldTestCount(deviceId);
      _previousCounts[deviceId] = currentCount;
      if (oldCount != null) {
        final diff = (oldCount - currentCount).abs();
        if (diff > 1) {
          _addOrUpdateDevice(deviceId, currentCount);
        }
      }
    }

    if (updatedNewTest.isNotEmpty) {
      await syncUpdatedDevices();
      if (updatedNewTest.isNotEmpty) _startScanning();
    }
  }

  Future<void> syncPendingResults() async {
    for (var item in List.from(pendingResults)) {
      try {
        await dbRef
            .child("Result/${widget.user.mobile}/${item["key"]}")
            .set(item);

        pendingResults.remove(item);
        print("Synced: ${item["key"]}");
      } catch (e) {
        print("Still failed: ${item["key"]}");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDoctor = widget.user.type == "doctor";

    final historyTitle = isDoctor ? "Test Count’s" : "Test History";
    final doctorTitle = isDoctor ? "My Patient" : "My Doctor";
    final historyIcon = isDoctor ? Icons.account_balance_wallet : Icons.history;
    final doctorIcon = isDoctor ? Icons.groups : Icons.person;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
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
                // const PopupMenuItem(
                //   value: "history",
                //   child: Row(
                //     children: [
                //       Icon(Icons.history, color: Colors.black),
                //       SizedBox(width: 8),
                //       Text("Test History",
                //           style: TextStyle(color: Colors.black)),
                //     ],
                //   ),
                // ),
                // // const PopupMenuItem(
                // //   value: "device",
                // //   child: Row(
                // //     children: [
                // //       Icon(Icons.devices, color: Colors.black),
                // //       SizedBox(width: 8),
                // //       Text("My Device",
                // //           style: TextStyle(color: Colors.black)),
                // //     ],
                // //   ),
                // // ),
                // const PopupMenuItem(
                //   value: "doctor",
                //   child: Row(
                //     children: [
                //       Icon(Icons.people, color: Colors.black),
                //       SizedBox(width: 8),
                //       Text("My Doctor",
                //           style: TextStyle(color: Colors.black)),
                //     ],
                //   ),
                // ),
                PopupMenuItem(
                  value: "history",
                  child: Row(
                    children: [
                      Icon(historyIcon, color: Colors.black),
                      const SizedBox(width: 8),
                      Text(historyTitle,
                          style: const TextStyle(color: Colors.black)),
                    ],
                  ),
                ),

                PopupMenuItem(
                  value: "doctor",
                  child: Row(
                    children: [
                      Icon(doctorIcon, color: Colors.black),
                      const SizedBox(width: 8),
                      Text(doctorTitle,
                          style: const TextStyle(color: Colors.black)),
                    ],
                  ),
                ),

                const PopupMenuItem(
                  value: "profile",
                  child: Row(
                    children: [
                      Icon(Icons.person, color: Colors.black),
                      SizedBox(width: 8),
                      Text("My Profile",
                          style: TextStyle(color: Colors.black)),
                    ],
                  ),
                ),
              ],
            );

            if (selected == null) return;

            if (selected == "home") {
              Navigator.pushNamed(context, "/home");
            }
            // else if (selected == "history") {
            //   // Navigator.pushNamed(context, "/testHistory");
            //
            //   Navigator.push(
            //     context,
            //     MaterialPageRoute(
            //       builder: (_) => TesthistoryPage(user: widget.user),
            //     ),
            //   );
            // }
            else if (selected == "history") {
              if (widget.user.type == "doctor") {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TestCountScreen(user: widget.user),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TesthistoryPage(user: widget.user),
                  ),
                );
              }
            }
            // else if (selected == "device") {
            //   Navigator.pushNamed(context, "/myDevice");
            // }
            // else if (selected == "doctor") {
            //   Navigator.pushNamed(context, "/myDoctor");
            // }

            else if (selected == "doctor") {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      MyDoctorPage(
                        user: widget.user,
                      ),
                ),
              );
            }
            else if (selected == "profile") {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      MyProfileScreen(
                        user: widget.user,
                      ),
                ),
              );
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
                  .child("Devices/${widget.user.mobile}")
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

                        // 🔹 If less than 10, show warning first
                        if (testCount < 10) {
                          bool proceed = await _showLowTestWarning(testCount);
                          if (!proceed) return;
                        }

                        await _connectSendAndRead(mac, key, "a2");
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
                    Text("Connecting with device…",
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _checkTestCountChange(String deviceId, int currentTestCount,
      String status, String mac) async {
    if (status.toLowerCase() != "active") return;

    final previous = _previousCounts[deviceId];

    if (previous == null) {
      _previousCounts[deviceId] = currentTestCount;
      return;
    }

    final difference = (previous - currentTestCount).abs();

    if (difference > 1) {
      _showPopup(
        "Test Count Updated",
        "Device: $deviceId\nPrevious Test : $previous\nCurrent Test : $currentTestCount",
      );

      bool sent = await _sendTestCountToDevice(deviceId, currentTestCount);

      if (!sent) {
        // Only add to retry list if sending failed
        _addOrUpdateDevice(deviceId, currentTestCount);
        print("Added to retry list: $updatedNewTest");

        if (_scanSub == null) {
          _startScanning();
        }
      } else {
        print("Sync success immediately");
      }
    }

    _previousCounts[deviceId] = currentTestCount;
  }

  Future<void> _connectSendAndRead(String mac, String deviceName,
      String cmd) async {
    if (_busy || _isConnecting) return;

    _busy = true;
    _setLoading(true);
    selectedDeviceId = deviceName;
    _rxBuffer = "";

    try {
      await _connectToDevice(mac, deviceName);
      // await _discoverServices();
      await _sendCommand(cmd);
    } catch (e) {
      print("Error" + e.toString());
      _showPopup("Error",
          "Device not found.\nPlease check if the device is available and turned on.");
      await _disconnect();
    }
    _setLoading(false);
    _busy = false;
  }

  Future<void> _connectToDevice(String mac, String deviceName) async {
    if (_isConnecting) return;
    _isConnecting = true;

    try {
      final state = await FlutterBluePlus.adapterState.first;
      if (state != BluetoothAdapterState.on) {
        _showPopup("Bluetooth Off", "Please turn on Bluetooth.");
        return;
      }

      if (_device != null) {
        try {
          await _device!.disconnect();
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (_) {}
      }
      if (Platform.isIOS) {
        BluetoothDevice? foundDevice;

        await FlutterBluePlus.startScan(timeout: const Duration(seconds: 7));

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
          throw Exception("Device not found");
        }

        _device = foundDevice;
      } else {
        _device = BluetoothDevice.fromId(mac);
      }

      await _device!.connect(
        license: License.commercial,
        timeout: const Duration(seconds: 12),
        autoConnect: false,
      );
      await _discoverServices();
    } catch (e) {
      _showPopup("Connection Error", "Device not found or unreachable.");
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> _discoverServices() async {
    final services = await _device!.discoverServices();

    final service = services.firstWhere((s) => s.uuid == serviceUuid);

    _rxChar = service.characteristics.firstWhere((c) => c.uuid == rxUuid);

    _txChar = service.characteristics.firstWhere((c) => c.uuid == txUuid);
    await _notifySub?.cancel();
    await _txChar!.setNotifyValue(true);
    _notifySub = _txChar!.lastValueStream.listen(_onDataReceived);
  }

  Future<void> _sendCommand(String command) async {
    final cmd = "$command\r\n";
    await _rxChar!.write(
      Uint8List.fromList(cmd.codeUnits),
      withoutResponse: _rxChar!.properties.writeWithoutResponse,
    );
  }

  // Future<void> _onDataReceived(List<int> data) async {
  //   _rxBuffer += String.fromCharCodes(data);
  //
  //   if (!_rxBuffer.contains("\n")) return;
  //
  //   final raw = _rxBuffer.trim();
  //   _rxBuffer = "";
  //
  //   // await _disconnect();
  //
  //   if (raw == "No Data Found") {
  //     _showPopup("Result", raw);
  //     return;
  //   }
  //
  //   String result = raw;
  //   String ref = "";
  //
  //    if (raw.contains("_")) {
  //     final parts = raw.split("_");
  //
  //     if (parts.length >= 3) {
  //       result = parts[0].trim();
  //       String ref = parts[1].trim();
  //       int count = int.tryParse(parts[2].trim()) ?? 0;
  //
  //       // await _updateResultDB(result, ref, count);
  //
  //       bool saved = await _updateResultDB(result, ref, count);
  //
  //       if (saved) {
  //         // _showPopup("Success", "Result saved successfully.");
  //         await _decreaseTestCount();
  //       } else {
  //         _showPopup("Error", "Failed to save result.");
  //       }
  //
  //     }
  //   }
  //
  //   _showPopup("Test Result", result);
  // }

  // Future<void> _onDataReceived(List<int> data) async {
  //   _rxBuffer += String.fromCharCodes(data);
  //
  //   if (!_rxBuffer.contains("\n")) return;
  //
  //   final raw = _rxBuffer.trim();
  //   _rxBuffer = "";
  //
  //   // 🚀 Process immediately (DO NOT wait for disconnect)
  //   _handleResult(raw);
  //
  //   // Disconnect in background
  //   Future.microtask(() async {
  //     await _disconnect();
  //   });
  // }
  // Future<void> _handleResult(String raw) async {
  //   if (raw == "No Data Found") {
  //     _showPopup("Result", raw);
  //     return;
  //   }
  //
  //   if (raw.contains("_")) {
  //     final parts = raw.split("_");
  //
  //     if (parts.length >= 3) {
  //       final result = parts[0].trim();
  //       final ref = parts[1].trim();
  //       final count = int.tryParse(parts[2].trim()) ?? 0;
  //
  //       bool saved = await _updateResultDB(result, ref, count);
  //
  //       if (saved) {
  //         await _decreaseTestCount();
  //       }
  //
  //       _showPopup("Test Result", result);
  //     }
  //   }
  // }


  Future<void> _onDataReceived(List<int> data) async {
    final chunk = String.fromCharCodes(data);
    _rxBuffer += chunk;

    if (_rxBuffer.contains("\n")) {
      final rawResult = _rxBuffer.trim();
      _rxBuffer = "";

      print("Device RESPONSE => [$rawResult]");

      // 🔥 1️⃣ Handle Stored Counter FIRST
      if (rawResult.contains("Stored Counter")) {
        print("Counter stored successfully on device");

        await _disconnectClean();

        return; // 🚫 absolutely stop
      }

      String displayResult = rawResult;
      String refcesValue = "";

      // 🔹 No Data Found
      if (rawResult == "No Data Found") {
        displayResult = "No Data Found";
      }

      // 🔹 Only treat as test result if format is EXACTLY like Result_Value
      else if (rawResult.contains("_") &&
          !rawResult.contains("Stored Counter")) {
        final parts = rawResult.split("_");

        displayResult = parts[0].trim();
        refcesValue = parts.length > 1 ? parts[1].trim() : "";

        // await _updateResultDB(displayResult, refcesValue);
        // await _decreaseTestCount(); // 🔥 decrease only here
        int count = int.tryParse(parts[2].trim()) ?? 0;

        // await _updateResultDB(result, ref, count);

        bool saved = await _updateResultDB(displayResult, refcesValue, count);

        if (saved) {
          // _showPopup("Success", "Result saved successfully.");
          await _decreaseTestCount();
        } else {
          _showPopup("Error", "Failed to save result.");
        }
      }

      await _disconnectClean();

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            AlertDialog(
              title: const Text("Test Result"),
              content: Text(displayResult),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            ),
      );
    }
  }

  Future<void> _disconnectClean() async {
    try {
      await _notifySub?.cancel();
      // await _txChar?.setNotifyValue(false);
      // await _device?.disconnect();
      if (_txChar != null) {
        await _txChar!.setNotifyValue(false);
      }

      if (_device != null) {
        await _device!.disconnect();
        await Future.delayed(const Duration(milliseconds: 300));
      }
    } catch (_) {}

    _device = null;
    _rxChar = null;
    _txChar = null;
  }

  Future<void> _decreaseTestCount() async {
    final ref = dbRef.child(
        "Devices/${widget.user.mobile}/$selectedDeviceId/testCount");

    await ref.runTransaction((current) {
      if (current == null) return Transaction.success(0);
      final val = (current as num).toInt();
      return Transaction.success(val > 0 ? val - 1 : 0);
    });
  }

  // Future<bool> _updateResultDB(String result, String refValue, int count) async {
  //   try {
  //     final now = DateTime.now();
  //     final key =
  //         "${now.day}-${now.month}-${now.year}_${now.hour}:${now.minute}:${now.second}";
  //
  //     await dbRef.child("Result/${widget.userMobile}/$key").set({
  //       "id": selectedDeviceId,
  //       "result": result,
  //       "volt": refValue,
  //       "count": count,
  //     });
  //
  //     print("Result saved successfully");
  //     return true;
  //   } catch (e) {
  //     print("Error saving result: $e");
  //     return false;
  //   }
  // }

  Future<bool> _updateResultDB(String result, String refValue,
      int count) async {
    final now = DateTime.now();
    final key =
        "${now.day}-${now.month}-${now.year}_${now.hour}:${now.minute}:${now
        .second}";

    final data = {
      "key": key,
      "id": selectedDeviceId,
      "result": result,
      "volt": refValue,
      "count": count,
    };

    try {
      await dbRef.child("Result/${widget.user.mobile}/$key").set(data);
      print("Result saved successfully");
      return true;
    } catch (e) {
      print("Error saving result: $e");

      // Save locally in list
      pendingResults.add(data);

      print("Saved locally in pending list");
      return false;
    }
  }

  Future<void> _disconnect() async {
    await _notifySub?.cancel();
    if (_txChar != null) {
      await _txChar!.setNotifyValue(false);
    }
    await _device?.disconnect();

    _device = null;
    _rxChar = null;
    _txChar = null;
  }

  void _showPopup(String title, String message) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) =>
            AlertDialog(
              title: Text(title),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                )
              ],
            ),
      );
    });
  }

  void _setLoading(bool value) {
    if (mounted) setState(() => _isLoading = value);
  }

  Future<void> _saveDeviceToFirebase(String deviceID, String mac) async {
    await dbRef.child("Devices/${widget.user.mobile}/$deviceID").set({
      "st": "Inactive",
      "testCount": 0,
      "mac": mac,
    });
  }

  void _showDeviceScanPopup() {
    List<ScanResult> found = [];

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Search SCINTIGLO Devices"),
          content: SizedBox(
            height: 500,
            child: FutureBuilder(
              future: FlutterBluePlus.startScan(
                  timeout: const Duration(seconds: 8)),
              builder: (_, __) {
                FlutterBluePlus.scanResults.listen((results) {
                  for (var r in results) {
                    final name = r.device.name;
                    if (name.startsWith("SCINPY") &&
                        !found.any((d) =>
                        d.device.remoteId == r.device.remoteId)) {
                      found.add(r);
                    }
                  }
                });

                return ListView.builder(
                  itemCount: found.length,
                  itemBuilder: (_, i) {
                    final r = found[i];
                    return ListTile(
                      title: Text(r.device.name),
                      subtitle: Text(r.device.remoteId.str),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _saveDeviceToFirebase(
                            r.device.name, r.device.remoteId.str);
                      },
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _addOrUpdateDevice(String deviceName, int newCount) {
    final index = updatedNewTest.indexWhere((d) => d["deviceId"] == deviceName);

    if (index != -1) {
      updatedNewTest[index]["testCount"] = newCount;
    } else {
      updatedNewTest.add({
        "deviceId": deviceName,
        "testCount": newCount,
      });
    }
  }

  Future<int> _getTestCount() async {
    final testCountRef = dbRef
        .child("Devices")
        .child(widget.user.mobile)
        .child(selectedDeviceId)
        .child("testCount");

    final snapshot = await testCountRef.get();

    if (snapshot.exists) {
      return (snapshot.value as num?)?.toInt() ?? 0;
    } else {
      return 0;
    }
  }

  Future<void> syncUpdatedDevices() async {
    if (updatedNewTest.isEmpty) {
      print("No devices to sync");
      return;
    }
    _setLoading(true);
    try {
      final List<Map<String, dynamic>> devicesToProcess = List.from(
          updatedNewTest);

      for (var device in devicesToProcess) {
        final deviceId = device["deviceId"];
        final testCount = device["testCount"];

        bool sent = await _sendTestCountToDevice(deviceId, testCount);

        if (sent) {
          updatedNewTest.removeWhere((d) => d["deviceId"] == deviceId);
          print("$deviceId synced and removed");
        } else {
          print("$deviceId not available");
        }
      }
    } finally {
      _setLoading(false);
    }

    print("Remaining Devices: $updatedNewTest");
  }

  @override
  void dispose() {
    _notifySub?.cancel();
    _device?.disconnect();
    _deviceListener?.cancel();
    _scanSub?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  void _listenToDevices() {
    final devicesRef = dbRef.child("Devices").child(widget.user.mobile);

    _deviceListener = devicesRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return;

      for (var entry in data.entries) {
        final deviceId = entry.key;
        final device = Map<String, dynamic>.from(entry.value);

        final status = (device["st"] ?? "Inactive").toString();
        final testCount = (device["testCount"] ?? 0) as int;
        final mac = device["mac"] ?? "";

        if (status.toLowerCase() != "active") continue;

        _checkTestCountChange(deviceId, testCount, status, mac);
      }
    });
  }

  Future<int?> getLatestOldTestCount(String deviceId) async {
    final resultRef = dbRef.child("Result").child(widget.user.mobile);

    final snapshot = await resultRef.get();
    if (!snapshot.exists) return null;

    final data = Map<String, dynamic>.from(snapshot.value as Map);

    DateTime? latestDate;
    int? latestCount;

    data.forEach((dateKey, value) {
      final item = Map<String, dynamic>.from(value);

      if (item["id"] == deviceId) {
        final parsedDate = _parseCustomDate(dateKey);

        if (latestDate == null || parsedDate.isAfter(latestDate!)) {
          latestDate = parsedDate;
          latestCount = (item["count"] as num).toInt();
        }
      }
    });

    return latestCount;
  }

  DateTime _parseCustomDate(String key) {
    final parts = key.split('_');
    final date = parts[0].split('-');
    final time = parts[1].split(':');

    return DateTime(
      2000 + int.parse(date[2]),
      int.parse(date[1]),
      int.parse(date[0]),
      int.parse(time[0]),
      int.parse(time[1]),
      int.parse(time[2]),
    );
  }

  Future<bool> _sendTestCountToDevice(String deviceId, int testCount) async {
    try {
      await _disconnect();
      final deviceSnap = await dbRef
          .child("Devices")
          .child(widget.user.mobile)
          .child(deviceId)
          .get();

      if (!deviceSnap.exists) return false;

      final mac = deviceSnap
          .child("mac")
          .value
          .toString();

      String formattedCount = testCount.toString().padLeft(3, '0');
      String command = "\$$formattedCount";

      await _connectToDevice(mac, deviceId);
      await _sendCommand(command);
      print("Sync success → $deviceId : $command");
      return true;
    } catch (e) {
      print("Sync failed: $e");
      return false;
    } finally {
      await _disconnect();
    }
  }

  void _startScanning() {
    if (_scanSub != null) return;

    FlutterBluePlus.startScan();

    _scanSub = FlutterBluePlus.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        String name = result.device.platformName;
        if (name == '') name = result.advertisementData.localName ?? '';
        if (!name.startsWith('SCINPY')) continue;

        final index = updatedNewTest.indexWhere((d) => d['deviceId'] == name);
        if (index == -1) continue;
        if (_syncingDevices.contains(name)) continue;

        final last = _lastSyncAttempt[name];
        if (last != null &&
            DateTime.now().difference(last) < const Duration(seconds: 30))
          continue;

        _lastSyncAttempt[name] = DateTime.now();
        _syncingDevices.add(name);

        final count = updatedNewTest[index]['testCount'] as int;

        _sendTestCountToDevice(name, count).then((bool success) {
          _syncingDevices.remove(name);
          if (success) {
            updatedNewTest.removeAt(index);
            _showPopup("Sync Success", "Test count updated for $name");
            if (updatedNewTest.isEmpty) {
              _stopScanning();
            }
          }
        });
      }
    });
  }

  void _stopScanning() {
    _scanSub?.cancel();
    _scanSub = null;
    FlutterBluePlus.stopScan();
  }

  Future<bool> _showLowTestWarning(int remaining) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 8),
                Text("Low Test Count"),
              ],
            ),
            content: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
                children: [
                  const TextSpan(text: "Remaining tests: "),
                  TextSpan(
                    text: "$remaining",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      fontSize: 18,
                    ),
                  ),
                  const TextSpan(
                    text: "\n\nDo you want to continue?",
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("OK"),
              ),
            ],
          ),
    ) ??
        false;
  }
}
